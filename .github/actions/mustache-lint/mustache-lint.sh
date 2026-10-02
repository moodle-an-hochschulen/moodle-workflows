#!/usr/bin/env bash
#
# Run Mustache Lint and accept the messages which are inherited from .upstream template files
# or which are listed in the plugin's .mustachelintbaseline file.
# This script is meant to be run in the workspace root after moodle-plugin-ci has been installed.

set -e -o pipefail

# Use a fixed locale so that sort, comm and awk behave consistently
export LC_ALL=C

# Helper to fail with the given error message
fail() {
  echo "::error title=Mustache Lint::$1"
  exit 1
}

# Check the prerequisites
if [ -z "$RUNNER_TEMP" ]; then
  fail "The RUNNER_TEMP environment variable is not set, this script is meant to be run within a GitHub Actions job."
fi
if [ ! -f ci/.env ]; then
  fail "The file ci/.env was not found, moodle-plugin-ci has to be installed before this script is run."
fi

# Get the plugin and Moodle directories from moodle-plugin-ci
PLUGIN_DIR=$(grep '^PLUGIN_DIR=' ci/.env | cut -d= -f2-) || true
MOODLE_DIR=$(grep '^MOODLE_DIR=' ci/.env | cut -d= -f2-) || true
if [ -z "$PLUGIN_DIR" ] || [ -z "$MOODLE_DIR" ]; then
  fail "The file ci/.env does not contain the PLUGIN_DIR and MOODLE_DIR settings."
fi

# Run Mustache Lint and keep its output for the analysis below
# (the very verbose mode prints the linter command of each template, which is needed to know which templates were linted)
LOG="$RUNNER_TEMP/mustache-lint.log"
LINT_EXIT=0
moodle-plugin-ci mustache -vv 2>&1 | tee "$LOG" || LINT_EXIT=$?

# Moodle 5.1+ is using the public directory structure
MOODLE_PUBLIC_DIR="$MOODLE_DIR"
if [ -d "$MOODLE_DIR/public" ]; then
  MOODLE_PUBLIC_DIR="$MOODLE_DIR/public"
fi

# Locate the linter and the HTML validator in the same way as moodle-plugin-ci does
LINTER="ci/vendor/moodlehq/moodle-local_ci/mustache_lint/mustache_lint.php"
VALIDATOR="ci/vendor/moodlehq/moodle-local_ci/node_modules/vnu-jar/build/dist/vnu.jar"
if [ ! -f "$VALIDATOR" ]; then
  VALIDATOR="$(npm -g prefix)/lib/node_modules/vnu-jar/build/dist/vnu.jar"
fi

# Helper to print the remainder of all lines which start with the given prefix
strip_prefix() {
  awk -v p="$1" 'index($0, p) == 1 { print substr($0, length(p) + 1) }'
}

# Helper to normalize the linter messages of the given template
# (line numbers, HTML extracts and JS source extracts depend on the example context and are removed,
# the HTML extract is cut off at the first opening parenthesis as its start cannot be told apart from
# a parenthesis within the message otherwise, all other messages are kept as they are)
normalize() {
  strip_prefix "$1 - " | sed -n -E \
    -e '/^(WARNING|ERROR): /!d' \
    -e '/^[A-Z]+: HTML Validation /{s/, line [0-9]+: /: /;s/ \(.*$//;}' \
    -e '/^[A-Z]+: ESLint /s/ \( .* \), Line: [0-9]+ Column: [0-9]+$//' \
    -e 'p' | sort
}

# Read the plugin's baseline file which lists accepted messages (format: "<template path>: <normalized message>")
# (surrounding whitespace and Windows line endings are removed, comments and empty lines are skipped)
BASELINE="$RUNNER_TEMP/mustache-lint-baseline.txt"
: > "$BASELINE"
if [ -f "$PLUGIN_DIR/.mustachelintbaseline" ]; then
  sed -E -e 's/^[[:space:]]+//' -e 's/[[:space:]]+$//' "$PLUGIN_DIR/.mustachelintbaseline" \
    | grep -v -e '^#' -e '^$' | sort > "$BASELINE" || true
fi

# Check that each linted template got a result, i.e. either the OK message or at least one warning or error.
# A template without any result means that the linter crashed, which must not be hidden by accepted messages of other templates.
LINTED_FILES="$RUNNER_TEMP/mustache-lint-linted.txt"
RESULT_FILES="$RUNNER_TEMP/mustache-lint-results.txt"
sed -n -E "s/^.*RUN .*'--filename=(.*)' '--validator=.*$/\1/p" "$LOG" | sort -u > "$LINTED_FILES"
sed -n -E 's/ - (OK|WARNING|ERROR): .*//p' "$LOG" | sort -u > "$RESULT_FILES"
if [ ! -s "$LINTED_FILES" ] && [ -s "$RESULT_FILES" ]; then
  fail "Could not determine the linted templates from the Mustache Lint output."
fi
CRASHED_COUNT=0
while IFS= read -r FILE; do
  echo "::error title=Mustache Lint::The linter did not report any result for ${FILE//%/%25}, see the output above."
  CRASHED_COUNT=$((CRASHED_COUNT+1))
done < <(comm -23 "$LINTED_FILES" "$RESULT_FILES")

# Check each template which produced warnings or errors against its .upstream file and the baseline file
echo ""
echo "Checking the Mustache Lint messages against the .upstream files and the .mustachelintbaseline file..."
PLUGIN_MESSAGES="$RUNNER_TEMP/mustache-lint-plugin.txt"
UPSTREAM_MESSAGES="$RUNNER_TEMP/mustache-lint-upstream.txt"
ACCEPTED_MESSAGES="$RUNNER_TEMP/mustache-lint-accepted.txt"
ALL_MESSAGES="$RUNNER_TEMP/mustache-lint-all.txt"
: > "$ALL_MESSAGES"
INTRODUCED_COUNT=0
while IFS= read -r REL; do
  FILE="$PLUGIN_DIR/$REL"
  normalize "$FILE" < "$LOG" > "$PLUGIN_MESSAGES"
  awk -v p="$REL: " '{ print p $0 }' "$PLUGIN_MESSAGES" >> "$ALL_MESSAGES"

  # Lint the .upstream file (if there is one) and accept its messages as well as the baseline messages
  : > "$UPSTREAM_MESSAGES"
  if [ -f "$FILE.upstream" ]; then
    env -u _JAVA_OPTIONS php "$LINTER" --filename="$FILE.upstream" --validator="$VALIDATOR" --basename="$MOODLE_PUBLIC_DIR" < /dev/null 2>&1 \
      | normalize "$FILE.upstream" > "$UPSTREAM_MESSAGES" || true
  fi
  strip_prefix "$REL: " < "$BASELINE" | sort | comm -13 "$UPSTREAM_MESSAGES" - | sort -m - "$UPSTREAM_MESSAGES" > "$ACCEPTED_MESSAGES"

  echo ""
  echo "$REL:"
  while IFS= read -r MESSAGE; do
    if grep -q -x -F "$MESSAGE" "$UPSTREAM_MESSAGES"; then
      echo "  Inherited from .upstream file: $MESSAGE"
    else
      echo "  Accepted by baseline: $MESSAGE"
    fi
  done < <(comm -12 "$PLUGIN_MESSAGES" "$ACCEPTED_MESSAGES")
  while IFS= read -r MESSAGE; do
    echo "  Introduced by plugin: $MESSAGE"
    echo "::error file=$REL,title=Mustache Lint::${MESSAGE//%/%25}"
    INTRODUCED_COUNT=$((INTRODUCED_COUNT+1))
  done < <(comm -23 "$PLUGIN_MESSAGES" "$ACCEPTED_MESSAGES")
done < <(strip_prefix "$PLUGIN_DIR/" < "$LOG" | sed -n -E 's/ - (WARNING|ERROR): .*//p' | sort -u)

# Report baseline entries which do not match any message anymore
sort -o "$ALL_MESSAGES" "$ALL_MESSAGES"
STALE_COUNT=0
while IFS= read -r ENTRY; do
  echo ""
  echo "Stale baseline entry: $ENTRY"
  echo "::error file=.mustachelintbaseline,title=Mustache Lint::Stale baseline entry which has to be removed: ${ENTRY//%/%25}"
  STALE_COUNT=$((STALE_COUNT+1))
done < <(comm -23 "$BASELINE" "$ALL_MESSAGES")

# Decide about the result
echo ""
FAILED=0
if [ "$CRASHED_COUNT" -gt 0 ]; then
  echo "Mustache Lint did not report any result for $CRASHED_COUNT template(s), see the output above."
  FAILED=1
fi
if [ "$INTRODUCED_COUNT" -gt 0 ]; then
  echo "Mustache Lint found $INTRODUCED_COUNT message(s) which are neither inherited from an .upstream file nor accepted by the baseline."
  FAILED=1
fi
if [ "$STALE_COUNT" -gt 0 ]; then
  echo "The .mustachelintbaseline file contains $STALE_COUNT stale entry/entries which do not match any Mustache Lint message anymore and have to be removed."
  FAILED=1
fi
if [ "$LINT_EXIT" -ne 0 ] && [ ! -s "$ALL_MESSAGES" ]; then
  echo "Mustache Lint failed without reporting any template message, see the output above."
  FAILED=1
fi
if [ "$FAILED" -ne 0 ]; then
  exit 1
elif [ ! -s "$ALL_MESSAGES" ]; then
  echo "Mustache Lint did not report any template message."
else
  echo "All Mustache Lint messages are either inherited from an .upstream file or accepted by the baseline."
fi
