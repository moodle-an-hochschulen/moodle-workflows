#!/usr/bin/env bash
#
# Print a warning if the plugin ships other language packs than the English one.
# The translations of published plugins are supposed to be managed in AMOS instead of being shipped
# with the plugin, where they would get out of sync with the AMOS translations sooner or later.
# The warning never fails the step.
#
# Expected environment variables:
#   PLUGIN_DIR  The path to the plugin directory, relative to the workspace root

set -e -o pipefail

# Helper to fail with the given error message
fail() {
  echo "::error title=Language Pack Checker::$1"
  exit 1
}

# Check the prerequisites
if [ -z "$PLUGIN_DIR" ] || [ ! -d "$PLUGIN_DIR" ]; then
  fail "The plugin directory '$PLUGIN_DIR' was not found."
fi

# Nothing to check without a lang directory
if [ ! -d "$PLUGIN_DIR/lang" ]; then
  echo "The plugin does not have a lang directory, nothing to check."
  exit 0
fi

# Look for language pack directories other than en
echo "Checking the plugin for language packs other than the English one..."
OTHER_LANGS=$(find "$PLUGIN_DIR/lang" -mindepth 1 -maxdepth 1 -type d ! -name en -exec basename {} \; | sort | tr '\n' ' ')
if [ -n "$OTHER_LANGS" ]; then
  echo "::warning::The plugin ships other language packs than the English one: ${OTHER_LANGS% }. Published plugins should only ship the English language pack and have their translations managed in AMOS. If this plugin is not published, you can mute this warning by setting codebase-check-languagepacks to false in your caller workflow."
else
  echo "The plugin ships only the English language pack."
fi
