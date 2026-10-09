#!/usr/bin/env bash
#
# Check that the plugin codebase contains the files which are listed in files.json for the given mode.
# The mode "standard" requires the files which every Moodle plugin needs, the mode "extended" requires
# the files which the organization requires on top of these as well.
#
# Expected environment variables:
#   MODE            The mode, either "standard" or "extended"
#   PLUGIN_DIR      The path to the plugin directory, relative to the workspace root
#   CASE_SENSITIVE  Whether the file names have to match exactly ("true", the default) or whether a file
#                   which differs only in upper and lower case is accepted as well ("false")

set -e -o pipefail

# Helper to fail with the given error message
fail() {
  echo "::error title=Plugin Codebase Completeness Checker::$1"
  exit 1
}

# Check the prerequisites
FILES_JSON="$(dirname "$0")/files.json"
if [ ! -f "$FILES_JSON" ]; then
  fail "The file list $FILES_JSON was not found."
fi
if [ -z "$PLUGIN_DIR" ] || [ ! -d "$PLUGIN_DIR" ]; then
  fail "The plugin directory '$PLUGIN_DIR' was not found."
fi
CASE_SENSITIVE="${CASE_SENSITIVE:-true}"
if [ "$CASE_SENSITIVE" != "true" ] && [ "$CASE_SENSITIVE" != "false" ]; then
  fail "Invalid value '$CASE_SENSITIVE' for case-sensitive. Allowed values are 'true' and 'false'."
fi

# Read the list of required files for the given mode
case "$MODE" in
  standard)
    echo "Checking the plugin codebase for the standard set of files..."
    REQUIRED_FILES=$(jq -r '.standard[]' "$FILES_JSON")
    ;;
  extended)
    echo "Checking the plugin codebase for the extended set of files..."
    REQUIRED_FILES=$(jq -r '.standard[], .extended[]' "$FILES_JSON")
    ;;
  *)
    fail "Invalid mode '$MODE'. Allowed values are 'standard' and 'extended'."
    ;;
esac

# The English language file is named after the plugin's frankenstyle component name from version.php,
# except for activity modules whose language file is named after the module name without the mod_ prefix.
# The name is substituted for the {langfile} placeholder in the file list.
FOUND_ISSUES=false
LANGFILE=""
if [ -f "$PLUGIN_DIR/version.php" ]; then
  COMPONENT=$(grep -E '^\s*\$plugin->component\s*=' "$PLUGIN_DIR/version.php" | head -1 | sed -E 's|//.*||; s/^[^=]*=//; s/[^a-z0-9_]//g') || true
  if [[ "$COMPONENT" =~ ^[a-z][a-z0-9]*_[a-z0-9_]+$ ]]; then
    echo "Plugin component: $COMPONENT"
    if [[ "$COMPONENT" == mod_* ]]; then
      LANGFILE="${COMPONENT#mod_}"
    else
      LANGFILE="$COMPONENT"
    fi
  else
    echo "::error::Could not read the plugin's frankenstyle component name from \$plugin->component in version.php, so the English language file cannot be checked."
    FOUND_ISSUES=true
  fi
fi

# Check that each required file exists
# (in case-insensitive mode, a file whose path differs from the required path only in upper and lower case is accepted as well)
if [ "$CASE_SENSITIVE" = "false" ]; then
  echo "File names are compared case-insensitively (case-sensitive is false)."
fi
while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  if [[ "$FILE" == *"{langfile}"* ]]; then
    # Without a known language file name, the check of this file has already been reported as an error above.
    [ -n "$LANGFILE" ] || continue
    FILE="${FILE//\{langfile\}/$LANGFILE}"
  fi
  if [ -f "$PLUGIN_DIR/$FILE" ]; then
    echo "Found required file: $FILE"
    continue
  fi
  if [ "$CASE_SENSITIVE" = "false" ]; then
    MATCH=$(find "$PLUGIN_DIR" -type f -ipath "$PLUGIN_DIR/$FILE" -print -quit)
    if [ -n "$MATCH" ]; then
      echo "Found required file: $FILE (as ${MATCH#"$PLUGIN_DIR"/})"
      continue
    fi
  fi
  echo "::error::The required file $FILE is missing in the plugin codebase."
  FOUND_ISSUES=true
done <<< "$REQUIRED_FILES"

# Fail if any issues were found
if [ "$FOUND_ISSUES" = true ]; then
  echo "The plugin codebase is incomplete! Please add the missing files."
  exit 1
fi
echo "The plugin codebase is complete."
