moodle-workflows
================

Changes
-------

### Rolling release

* 2026-06-25 - Improve CI concurrency to deduplicate push and pull request runs on the same branch (use `tags-ignore` in the caller workflow's `on: push` trigger to avoid duplicate runs on release)
* 2026-06-24 - Deduplicate runtime test steps in `run` and `verify` jobs via Composite Action
* 2026-06-12 - Add option to split the Behat run across multiple parallel slices
* 2026-06-09 - Add possibility to pass secrets to the workflow
* 2025-10-24 - Add Moodle core repository branch detection as final fallback to automatic branch detection
* 2025-10-24 - Add option to run a custom script before installing moodle-plugin-ci
* 2025-10-23 - Add option to select the tags to be used for running Behat tests
* 2025-10-21 - Add option to disable SCSS deprecations in Behat tests
* 2025-10-20 - Add option to raise the Behat timeout if the plugin requires it
* 2025-10-20 - Add options to continue on error within the Moodle Codechecker and the Mustache Lint steps
* 2025-10-20 - Add option to select the theme to be used for running Behat tests
* 2025-10-20 - Add options for pull request content validation
* 2025-10-20 - Add option to start additonal service with Docker Compose for runtime tests
* 2025-10-19 - Add option to start Redis for runtime tests
* 2025-10-14 - Initial version
