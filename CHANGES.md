moodle-workflows
================

Changes
-------

### Rolling release

* 2026-10-05 - Print a warning and upload the Behat faildump if Behat scenarios failed in the first attempt and only passed in the automatic rerun, resolves #23
* 2026-10-04 - Add option to add additional lines to the Moodle config.php for the runtime tests, resolves #22
* 2026-10-04 - Intermediate fix to let the Mustache Lint step run ESLint on the JS in Mustache templates on Moodle 5.1+ again until https://github.com/moodlehq/moodle-plugin-ci/issues/400 is fixed, resolves #21
* 2026-10-03 - Run the PHP web server for Behat in a supervisor loop which restarts it if it crashes and keeps its log, resolves #19
* 2026-10-03 - Add option to let the runtime tests fail if Behat reports pending or undefined steps (enabled by default), resolves #18
* 2026-10-02 - Accept Mustache Lint messages which are inherited from .upstream template files or listed in a .mustachelintbaseline file, resolves #17
* 2026-09-23 - Deduplicate runtime test steps in `run` and `verify` jobs via YAML anchors and aliases
* 2026-09-23 - Update moodle-release workflow to support the new notes parameter of the HQ GHA workflow
* 2026-09-18 - Update moodle-release workflow to use the new Moodle Marketplace API
               ACTION REQUIRED: If you use this workflow in your Moodle plugin repos, have a look at https://github.com/moodle-an-hochschulen/moodle-workflows#moodle-release-workflow for understanding the necessary transition steps
* 2026-09-14 - Add options to tolerate a known number of warnings in the Moodle Code Checker, Moodle PHPDoc Checker and Grunt steps
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
