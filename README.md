moodle-workflows
================

A collection of reusable GitHub Actions workflows for Moodle plugin development and release management used by Moodle an Hochschulen e.V.


Motivation for this collection
------------------------------

Managing GitHub Actions workflows across multiple Moodle plugin repositories can be tedious and error-prone. Each repository requires similar CI/CD pipelines for testing, code quality checks, and releases. When updates or improvements are needed, they must be applied to every repository individually.

This collection centralizes common workflows into reusable components, providing:

- **Consistency**: All plugin repositories use the same, tested workflows
- **Maintainability**: Updates only need to be made in one place
- **Best practices**: Incorporates Moodle community standards and recommendations
- **Automation**: Reduces manual configuration and potential errors


moodle-plugin-ci workflow
-------------------------

A comprehensive continuous integration workflow for Moodle plugins based on the [moodle-plugin-ci](https://github.com/moodlehq/moodle-plugin-ci) tool.

### Enhanced features beyond standard moodle-plugin-ci

- **Automatic Moodle branch detection** from the Moodle plugin repository branch or from the plugin's version.php file
- **Development leftover detection** to catch leftovers like *TODO* comments or unresolved merge conflicts
- **Easy plugin dependency addition** for plugins that depend on other plugins
- **Split static and runtime jobs** to avoid running static tests unnecessarily on each PHP and database version
- **Single database testing** to run only PostgreSQL for plugins which do not interact with the Moodle database at all
- **Behat suite and tags selection** to select the theme and the tags to be used for running Behat tests
- **Behat timeout handling** to raise the Behat timeout if the plugin requires it
- **Behat parallelization** to split the Behat run across multiple parallel jobs, distributing the plugin's feature files by scenario count to shorten the overall runtime
- **Strict Behat result handling** to let the runtime tests fail if Behat silently skipped scenarios because of pending or undefined steps
- **Behat web server supervision** to restart the PHP web server automatically if it crashes during the Behat run, so that a single crash no longer fails the whole job
- **Flaky Behat scenario reporting** to print a warning and to keep the Behat faildump if scenarios failed in the first attempt and only passed in the automatic rerun
- **Concurrency handling** to cancel running jobs if a new commit is pushed to the same branch
- **Consecutive runtime testing** where the code is initially tested with the highest PHP version and Postgres only and the full matrix is only tested if that initial test was successful with the goal to save ressources
- **Additional services support** including Redis service for plugins that require caching or session storage as well as Docker Compose support for arbitrary backend services like LDAP containers
- **Pull request content validation** to automatically check PR content for required or forbidden text patterns, enforce ticket references, limit PR size, and exempt specific users from checks
- **Flexible error handling** for code quality checks with configurable continue-on-error behavior for phpcs and mustache lint steps
- **Organization-wide settings** to set workflow-wide parameters like the strict Behat result handling once as an organization variable instead of repeating them in the caller workflow of each plugin repository
- **Upstream-aware Mustache linting** which accepts Mustache Lint messages that a template inherits from the upstream template it was copied from or which are listed in a baseline file
- **Flexible pre-install script** for running a custom script before installing moodle-plugin-ci
- **Additional config.php lines** to add arbitrary lines to the Moodle config.php for the runtime tests, e.g. to override constants or to set config settings which cannot be set via the Moodle UI
- **Generic secrets support** to pass up to two username/password credential pairs from your repository secrets into the test environment

### Usage

Create a workflow file in your plugin repository at `.github/workflows/moodle-plugin-ci.yml`:

#### Basic setup (recommended)

```yaml
name: Moodle Plugin CI

on:
  push:
  pull_request:
  workflow_dispatch:
    inputs:
      moodle-core-branch:
        description: 'Moodle core branch to test against (if not provided, the branch will be auto-detected)'
        required: false
        type: string
  repository_dispatch:
    types: [moodle-plugin-ci]

jobs:
  moodle-plugin-ci:
    uses: moodle-an-hochschulen/moodle-workflows/.github/workflows/moodle-plugin-ci.yml@main
    with:
      moodle-core-branch: ${{ inputs.moodle-core-branch || github.event.client_payload.moodle-core-branch }}
```

#### More sophisticated setups

The following examples are meant to keep all lines of the basic setup above as all its parameters have its purpose.
However, if you know what you are doing, you are free to customize the setup beyond our examples, of course.

##### With plugin dependencies

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      plugin-dependencies: |
        learnweb/moodle-tool_lifecycle,main
        learnweb/moodle-customfield_semester,main
```

##### With manual branch selection and Postgres-only testing

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      moodle-core-branch: MOODLE_500_STABLE
      one-db-only: true
```

#### With Redis service and PHP extensions

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      redis-enabled: true
      php-extensions: "redis"
```

#### With Docker Compose for starting an additional service

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      docker-compose-file: "tests/fixtures/bitnami-openldap-docker-compose.yaml"
```

#### With pre-install script

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      pre-install-script: |
        # Do this.
        touch plugin/foo
        # Do that.
        rm -f plugin/foo
```

#### With additional config.php lines

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      extra-config: |
        define('THEME_DESIGNER_CACHE_LIFETIME', 0);
        $CFG->foo = 'bar';
```

#### With pull request content checks

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      pr-check-diff-does-not-contain: "theme->settings->"
      pr-check-body-contains: "MDL-"
      pr-check-waived-users: "dependabot[bot]"
```

#### With specific Behat suite

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      behat-suite: "boost_union"
```

#### With increased Behat timeout

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      behat-timeout: 3
```

#### With Behat tags filtering

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      behat-tags: "@javascript"
```

#### With parallel Behat slices

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      behat-slices: 4
```

#### With SCSS deprecations disabled

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      scss-deprecations: false
```

#### With strict Behat result handling disabled

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      behat-strict: false
```

#### With a tolerated number of code quality warnings

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      phpcs-max-warnings: 3
      phpdoc-max-warnings: 12
      grunt-max-lint-warnings: 2
```

Please note: These parameters are meant to let a particular, known number of warnings pass in a plugin which cannot get rid of these warnings for good reasons. They are not meant to switch warnings off across the board. Set the value to the exact number of warnings which the plugin currently produces, so that any additional warning which appears later on still makes the workflow fail. Keep the value as low as possible and lower it again as soon as warnings have been fixed. A blanket high value defeats the purpose of these checks.

#### With continue-on-error for code quality checks

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    with:
      phpcs-continue-on-error: true
      mustache-continue-on-error: true
```

### Available input parameters

| Parameter | Type | Required | Default | Configuration variable | Description |
|-----------|------|----------|---------|------------------------|-------------|
| `moodle-core-branch` | string | No | auto-detected | None | Run the tests on this Moodle core branch (if not provided, the branch will be auto-detected from current branch) |
| `plugin-dependencies` | string | No | - | None | List of plugin dependencies with repository and branch (use one dependency per line and separate repository and branch with a comma) |
| `one-db-only` | boolean | No | false | None | Use only PostgreSQL database instead of all configured databases |
| `max-parallel-verify` | number | No | unlimited | None | Maximum number of parallel jobs for the verify job (can be useful if you have really long running Behat tests and do not want to block too many runners at the same time) |
| `redis-enabled` | boolean | No | false | None | Start Redis service before running runtime tests |
| `php-extensions` | string | No | - | None | PHP extensions to install (e.g., "redis", "memcached", "redis,imagick") |
| `docker-compose-file` | string | No | - | None | Path to Docker Compose file (relative to plugin repository root) for starting an additional service |
| `pre-install-script` | string | No | - | None | Custom script to run before installing moodle-plugin-ci (multiline bash script) |
| `extra-config` | string | No | - | None | Additional lines to add to the Moodle config.php after installing moodle-plugin-ci (multiline, one PHP statement per line). The lines are added with `moodle-plugin-ci add-config` and apply to both the PHPUnit and the Behat runs. |
| `behat-suite` | string | No | - | None | The theme to be used for running Behat tests (e.g. "boost_union") |
| `behat-tags` | string | No | - | None | Behat tags to filter which Behat scenarios to run (e.g. "@javascript"). Separate multiple tags with a comma, but without any spaces in-between. |
| `behat-timeout` | number | No | - | None | Behat timeout multiplier (e.g. 3 for 3x timeout) |
| `behat-slices` | number | No | 1 | None | Number of parallel Behat slices to split the Behat run across (1 = no splitting). Each slice runs a subset of the plugin's Behat feature files in its own job, distributed by scenario count. |
| `behat-strict` | boolean | No | true | Supported | Let the runtime tests fail if Behat reports pending or undefined steps (which Behat itself does not treat as failures) |
| `pr-check-diff-contains` | string | No | - | None | Pull request diff must contain this text |
| `pr-check-diff-does-not-contain` | string | No | - | None | Pull request diff must not contain this text |
| `pr-check-body-contains` | string | No | - | None | Pull request body must contain this text |
| `pr-check-body-does-not-contain` | string | No | - | None | Pull request body must not contain this text |
| `pr-check-files-changed` | string | No | - | None | Number of files that must have changed in pull request |
| `pr-check-lines-changed` | string | No | - | None | Number of lines that must have changed in pull request |
| `pr-check-waived-users` | string | No | - | None | Comma-separated list of users exempt from pull request checks |
| `phpdoc-max-warnings` | number | No | 0 | None | Number of warnings which are tolerated in the Moodle PHPDoc Checker (phpdoc) step before it fails. |
| `grunt-max-lint-warnings` | number | No | 0 | None | Number of lint warnings which are tolerated in the Grunt step before it fails. |
| `phpcs-continue-on-error` | boolean | No | false | Supported | Continue on error for Moodle Code Checker (phpcs) |
| `phpcs-max-warnings` | number | No | 0 | None | Number of warnings which are tolerated in the Moodle Code Checker (phpcs) step before it fails. |
| `mustache-continue-on-error` | boolean | No | false | Supported | Continue on error for Mustache Lint |
| `scss-deprecations` | boolean | No | true | Supported | Include SCSS deprecation warnings in Behat tests |

### Organization-wide settings via configuration variables

Most parameters of this workflow are specific to a particular plugin and belong into the caller workflow of the plugin repository. Some parameters however control the behaviour of the workflow as a whole and are rather a matter of organization policy than of the particular plugin. To avoid repeating these parameters in the caller workflow of each and every plugin repository, they can also be set via [configuration variables](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-variables) at the organization level for all plugin repositories at once.

| Input Parameter | Corresponding configuration variable | Default |
|-----------------|--------------------------------------|---------|
| `phpcs-continue-on-error` | `MOODLE_PLUGIN_CI_PHPCS_CONTINUE_ON_ERROR` | false |
| `mustache-continue-on-error` | `MOODLE_PLUGIN_CI_MUSTACHE_CONTINUE_ON_ERROR` | false |
| `scss-deprecations` | `MOODLE_PLUGIN_CI_SCSS_DEPRECATIONS` | true |
| `behat-strict` | `MOODLE_PLUGIN_CI_BEHAT_STRICT` | true |

The effective value of each of these parameters is resolved in this order of precedence:

1. The input parameter which is passed in the caller workflow, if it deviates from the default value.
2. The configuration variable, if set. As usual in Github, a repository variable takes precedence over an organization variable with the same name.
3. The default value.

The allowed values of the configuration variables are `true` and `false`. Any other value lets the preflight job fail with a clear error message. The preflight job also logs where the effective value of each of these parameters came from.

Please note: As these parameters are booleans, Github does not let the workflow tell a parameter which has not been set in the caller workflow apart from a parameter which has been explicitly set to its default value. Both cases are therefore treated alike and let the configuration variable decide. If you want a single plugin repository to deviate from an organization variable and to run with the default value again, set a repository variable with the same name to the default value instead of setting the parameter in the caller workflow.

To set a configuration variable at the organization level, open your organization's settings, go to Secrets and variables, then Actions, switch to the Variables tab and create a new organization variable with the name from the table above and the value `true` or `false`. Make sure that the repository access of the variable covers your plugin repositories.

### Available secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `GENERIC_USERNAME_1` | No | Generic secret to pass a username to the workflow, if needed |
| `GENERIC_PASSWORD_1` | No | Generic secret to pass a password to the workflow, if needed |
| `GENERIC_USERNAME_2` | No | Generic secret to pass another username to the workflow, if needed |
| `GENERIC_PASSWORD_2` | No | Generic secret to pass another password to the workflow, if needed |

### Automatic Moodle core branch detection

The workflow includes an intelligent Moodle core branch detection that works as follows:

1. **Explicit parameter**: If the `moodle-core-branch` parameter is provided, it is used directly
2. **Branch pattern matching**: If the current plugin branch matches the `MOODLE_XXX_STABLE` pattern, it is used as Moodle core branch as well
3. **Main branch handling**: If the current plugin branch is the `main` branch, the workflow searches for the highest available `MOODLE_XXX_STABLE` branch in the plugin repository and uses it as Moodle core branch
4. **version.php parsing**: When testing feature branches with arbitrary namings, the workflow parses the `$plugin->supported` array to determine the maximum supported Moodle version and uses this as Moodle core branch
5. **Moodle core fallback**: If no `$plugin->supported` line is found in version.php, the workflow queries the official Moodle core repository to determine the highest available `MOODLE_XXX_STABLE` branch and uses it as Moodle core branch as final fallback

### Additional services and PHP extensions

The workflow supports starting additional services that your plugin might need during testing:

#### Redis service
Set `redis-enabled: true` to start a Redis service that will be available at `localhost:6379`. This is useful for plugins that use Redis for caching or session storage.

#### Docker Compose service
For more complex service requirements, you can use the `docker-compose-file` parameter to start an additional service using Docker Compose. Specify the path to your Docker Compose file relative to your repository root (e.g., `'tests/fixtures/openldap-docker-compose.yaml'`). The service will be started before running the runtime tests (run and verify jobs) but not during static tests.

#### PHP extensions
Use the `php-extensions` parameter to install additional PHP extensions needed by your plugin. Specify multiple extensions separated by commas (e.g., `"redis,imagick,memcached"`). The extensions are installed using `shivammathur/setup-php@v2`.

### Pull request content validation

The workflow supports automated pull request content validation using the [github-pr-contains-action](https://github.com/JJ/github-pr-contains-action) action by JJ. These checks run during the static analysis phase and only apply to pull requests. Please see JJ's documentation for additional details.

### Mustache Lint with upstream templates and a baseline file

Theme plugins like Boost Union often copy Mustache templates from Moodle core or from other plugins and adapt them. These copies inherit all Mustache Lint messages of the upstream template, and fixing them in the copy would make the copy deviate from the upstream template. Additionally, some of the plugin's own templates may be fragments (e.g. single list items) which produce Mustache Lint messages for good reasons.

The workflow therefore checks in the preflight job if the plugin contains `.upstream` template files or a `.mustachelintbaseline` file. If it does, the Mustache Lint step is run with the bundled `mustache-lint` action which accepts Mustache Lint messages in two cases and only fails for all other messages:

- If a file with the same name plus the suffix `.upstream` (e.g. `templates/core/user_menu.mustache.upstream`) exists next to a template, the step lints this file as well. All messages which are also reported for the `.upstream` file are accepted for the template. The `.upstream` file is supposed to contain an unmodified copy of the upstream template.
- If the plugin contains a `.mustachelintbaseline` file in its root directory, all messages which are listed in this file are accepted. The file contains one message per line in the format `<template path>: <message>`, for example:

```
# The smart menu children templates render single menu items which are wrapped into a menu by the calling template.
templates/smartmenus-moremenu-children.mustache: WARNING: HTML Validation error: Element “li” not allowed as child of element “body” in this context.
```

The messages are compared without the line number and without the HTML or JavaScript extract in parentheses, as these depend on the template's example context. The normalized messages are printed in the workflow log, so you can copy them from there into the baseline file. Each message is counted, so if a template reports a message more often than its `.upstream` file or the baseline file, the step fails. Lines starting with `#` and empty lines in the baseline file are ignored, and baseline entries which do not match any message anymore make the step fail as well, so the baseline file always has to be kept up to date.

Please note: Partials which are included by an `.upstream` file are resolved in the same way as for the plugin's template, i.e. the plugin's own template overrides are used. Messages caused by such a partial are still reported for the partial itself.

If a plugin has neither `.upstream` files nor a `.mustachelintbaseline` file, the Mustache Lint step just runs `moodle-plugin-ci mustache` as usual.

### Passing secrets to the workflow

Some plugins require credentials during test execution, for example to connect to an external service such as an LDAP server or a third-party API. If you do not want to add these credentials into the plugin's PHPUnit test files or into the plugin's Behat feature files directly, you can add them to GitHub secrets and use these secrets in your GitHub Actions workflow afterwards.

The problem is that GitHub does not automatically pass secrets to a reusable workflow, at least not across GitHub organizations. Thus, you have to pass them actively within your workflow definition.

Against this background, this workflow supports passing up to two username/password pairs from your plugin repository secrets into the test environment via the four optional secrets `GENERIC_USERNAME_1`, `GENERIC_PASSWORD_1`, `GENERIC_USERNAME_2`, and `GENERIC_PASSWORD_2`.

These secrets are exposed as environment variables of the same name in both the runtime tests job and the runtime verification job. They are not available during static analysis.

#### Usage example to call the workflow with generic secrets

```yaml
name: Moodle Plugin CI

on:
  [...]

jobs:
  moodle-plugin-ci:
    uses: moodle-an-hochschulen/moodle-workflows/.github/workflows/moodle-plugin-ci.yml@main
    with:
      moodle-core-branch: ${{ inputs.moodle-core-branch || github.event.client_payload.moodle-core-branch }}
    secrets:
      GENERIC_USERNAME_1: ${{ secrets.MY_SERVICE_USERNAME }}
      GENERIC_PASSWORD_1: ${{ secrets.MY_SERVICE_PASSWORD }}
```

This example would pick the secrets `MY_SERVICE_USERNAME` and `MY_SERVICE_PASSWORD` from your plugin repository and pass them into the reusable workflow. There, inside your tests, the values are then available as the environment variables `GENERIC_USERNAME_1` and `GENERIC_PASSWORD_1` respectively.

While the names of `MY_SERVICE_USERNAME` and `MY_SERVICE_PASSWORD` are up to your choice and can be aligned to your needs, the names `GENERIC_USERNAME_1` and `GENERIC_PASSWORD_1` are fixed.

#### Using generic secrets in Behat step definitions

If you want to use the generic secrets in a Behat feature, you can create a custom Behat step.

In your plugin's Behat step definitions, read the secrets with PHP's `getenv()` function. It is recommended to validate that the variables are actually set and throw an `ExpectationException` with a clear message if they are not – otherwise Behat would silently use empty credentials and produce confusing test failures.

```php
/**
 * Sets the credentials for connecting to the external service.
 *
 * @Given /^I set the external service credentials$/
 * @return void
 */
public function i_set_the_external_service_credentials(): void {
    $username = getenv('GENERIC_USERNAME_1');
    $password = getenv('GENERIC_PASSWORD_1');

    if ($username === false || $username === '') {
        throw new ExpectationException(
            'GENERIC_USERNAME_1 is not set.',
            $this->getSession(),
        );
    }
    if ($password === false || $password === '') {
        throw new ExpectationException(
            'GENERIC_PASSWORD_1 is not set.',
            $this->getSession(),
        );
    }

    set_config('myservice_user', $username, 'local_myplugin');
    set_config('myservice_password', $password, 'local_myplugin');
}
```

### Behat parallelization

For plugins with a large Behat test suite, the overall runtime can be shortened by splitting the Behat run across several parallel jobs. Set `behat-slices` to the number of slices you want (e.g. `behat-slices: 4`); the default of `1` keeps the Behat run in a single job.

How it works:

1. Before installing the plugin, the workflow scans the plugin's `tests/behat/*.feature` files (including those of subplugins), counts the scenarios in each and distributes the files across the requested number of slices using a greedy, scenario-count-weighted algorithm. This keeps the slices balanced even when feature files differ a lot in size.
2. Each feature file gets an additional `@behat_slice_<n>` tag on its tag line. Because the distribution is deterministic, every slice job computes the exact same assignment.
3. The runtime test jobs (run and verify) are multiplied by the number of slices, and each slice job runs Behat filtered to its own `@behat_slice_<n>` tag. If you also provide `behat-tags`, your tags and the slice tag are combined so that both conditions must match.

Notes:

- The splitting happens per feature file, not per scenario. A single feature file always runs within one slice.
- If you configure more slices than the plugin has feature files, the surplus slice jobs will simply run no scenarios (and pass quickly). Choose a slice count that fits the number of feature files.
- Slicing applies to both the run and the verify job, so the total number of runtime jobs grows accordingly. Combine it with `max-parallel-verify` if you want to limit how many verify jobs run at the same time.

### Strict Behat result handling

Behat does not treat pending steps or undefined steps as failures. It just skips the rest of the affected scenario and exits with code 0, which lets the Behat step pass although the scenario has not really been tested. Such glitches can easily go unnoticed in the workflow log.

Typical causes are:

- A `the following "x" exist:` step which uses an entity that the plugin's Behat generator does not know. This happens, for example, when a scenario is backported to an older plugin branch whose generator does not provide the entity yet. Moodle reports this as a pending step with the message `"x" is not a known type of entity that can be generated`.
- A step without a matching step definition, which Behat reports as an undefined step.

The workflow therefore scans the Behat summary (e.g. `12 scenarios (11 passed, 1 pending)`) after the Behat run and fails the runtime tests if any pending or undefined steps were reported. The list of pending steps and the summary lines are printed in the workflow log.

This check is enabled by default. If your plugin intentionally contains pending or undefined steps, you can disable it by setting `behat-strict: false` in your caller workflow or by setting the `MOODLE_PLUGIN_CI_BEHAT_STRICT` configuration variable to `false` in your organization or repository. The Behat run itself is not changed by this setting, it only controls whether pending or undefined steps let the runtime tests fail.

### Behat web server supervision

moodle-plugin-ci runs the Behat tests against PHP's built-in web server (`php -S localhost:8000`). By default, it starts this server as a single process, discards its output and does not restart it if it dies. If the server crashes in the middle of a long Behat run, every remaining scenario fails with `Connection refused`, the automatic reruns of moodle-plugin-ci hit the dead server as well and the whole job is lost, although only a single scenario was actually affected by the crash.

The workflow therefore does not let moodle-plugin-ci start the servers. Instead, it starts Selenium itself (with the same options as moodle-plugin-ci) and runs the PHP web server in a supervisor loop which starts the server again immediately if it exits for whatever reason. A crash then only affects the scenario which was running at that moment, and this scenario is picked up by the automatic rerun.

The output of the PHP web server, including its exit codes, is written to a log file:

- After the Behat run, the workflow prints a warning if the web server had to be restarted, together with the exit codes and the last requests before each exit.
- If the Behat run fails or if the web server had to be restarted, the log file is uploaded as the `PHP web server log` artifact. In the second case this happens even if the job passed, so that the cause of the crash can be examined.

No configuration is needed for this, it is always active. If you set `MOODLE_BEHAT_SELENIUM_IMAGE` in your environment, it is respected just like moodle-plugin-ci does.

### Flaky Behat scenario reporting

moodle-plugin-ci reruns failed Behat scenarios automatically. If a scenario fails in the first attempt and passes in the rerun, the Behat step is green and the job passes. The job log then only holds the generic Behat error message of the first attempt together with a truncated HTML snippet of the page, and the Behat faildump with the screenshot and the full HTML of the failed step would normally be discarded because the job did not fail. This makes flaky scenarios hard to investigate.

The workflow therefore detects such reruns from the Behat output:

- After the Behat run, the workflow prints a warning if scenarios had to be rerun, together with the failed steps of the first attempt.
- If the Behat run fails or if scenarios had to be rerun, the faildump is uploaded as the `Behat Faildump` artifact. In the second case this happens even if the job passed, so that the screenshots and the HTML of the failed steps from the first attempt can be examined.

No configuration is needed for this, it is always active.

### CLI tool

For programmatic triggering of Moodle Plugin CI workflows – instead of having them triggered by pull requests and pushes or even manually through the Github actions GUI – you can use the provided CLI script to make Github API calls. This comes particularly handy when you want to trigger fresh build of multiple plugins after a new Moodle core minor / major version has been released.

#### Prerequisites

To use the script, you need a GitHub Personal Access Token with the following permissions on the targeted repository:

  - `actions:write`
  - `contents:write`
  - `metadata:read`

#### Basic usage

```bash
# Test on main plugin branch, auto-detect Moodle core branch
./cli/moodle-plugin-ci.sh -t THE_GITHUB_TOKEN -r theme_boost_union

# Test on main plugin branch and specific Moodle core branch
./cli/moodle-plugin-ci.sh -t THE_GITHUB_TOKEN -r theme_boost_union -c MOODLE_500_STABLE

# Test on specific plugin branch, auto-detect Moodle core branch
./cli/moodle-plugin-ci.sh -t THE_GITHUB_TOKEN -r theme_boost_union -p feature-branch

# Test on specific plugin branch and specific Moodle core branch
./cli/moodle-plugin-ci.sh -t THE_GITHUB_TOKEN -r theme_boost_union -c MOODLE_500_STABLE -p my-feature

# Using environment variable for GitHub token
export GITHUB_TOKEN=your_token_here
./cli/moodle-plugin-ci.sh -r theme_boost_union -p feature-branch

# Show help with all options
./cli/moodle-plugin-ci.sh -h
```


moodle-release workflow
----------------------

An automated release workflow for publishing Moodle plugins to the [Moodle Marketplace](https://marketplace.moodle.com/) based on Moodle HQ's [moodle-plugin-release](https://github.com/moodlehq/moodle-plugin-release) tool.

### Heads-up

Before you add this workflow to your plugin, you should note the following:

Since the [transition of the good old Moodle plugins directory to the Moodle Marketplace](https://moodle.com/news/moodle-marketplace-is-here/), this workflow does not provide an additional benefit to the official Moodle HQ solution anymore.

It is just kept and maintained as glue code to make sure that existing plugin repositories which already used this workflow to publish to the good old Moodle plugins directory do not have to update all of their Github action workflows.

If you intend to add this workflow to a new plugin, please consider using the [Moodle HQ workflow](https://github.com/moodlehq/moodle-plugin-release) directly instead.


### Usage

Create a workflow file in your plugin repository at `.github/workflows/moodle-release.yml`:

```yaml
name: Moodle Plugin Release

on:
  push:
    tags:
      - v*
  workflow_dispatch:
    inputs:
      tag:
        description: 'Git tag to be released'
        required: true

jobs:
  release:
    uses: moodle-an-hochschulen/moodle-workflows/.github/workflows/moodle-release.yml@main
    secrets:
      MOODLE_ORG_TOKEN: ${{ secrets.MOODLE_ORG_TOKEN }}
```

### Available parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `tag` | string | No | The tag from the triggering event | Git tag to be released. You normally do not need to set this: on a tag push as well as on a `workflow_dispatch` run with a `tag` input, the workflow picks the tag up on its own. |
| `release_notes` | string | No | - | Release notes to be published. You normally do not need to set this either, see the notes below about how the release notes are determined. |
| `plugin-name` | string | No | - | Deprecated and ignored, see the notes below. |

### Required Github actions secrets

| Secret | Description |
|--------|-------------|
| `MOODLE_ORG_TOKEN` | API token for Moodle Marketplace (see https://moodledev.io/general/community/plugincontribution/moodlemarketplaceapi#create-an-api-token for help) |

### Important note about the token naming

The Moodle HQ workflow to publish to the good old Moodle plugins directory required a `MOODLE_ORG_TOKEN` secret while the Moodle Marketplace requires a `MOODLE_MARKETPLACE_TOKEN` secret.

This workflow here continues to expect a `MOODLE_ORG_TOKEN` secret so that you do not have to change anything in your caller workflows.

That `MOODLE_ORG_TOKEN` secret from your plugin is mapped to the `MOODLE_MARKETPLACE_TOKEN` secret before calling the Moodle HQ tool.

### How to transition existing repositories to releasing to the Moodle Marketplace

If you have a plugin repository which used this workflow successfully before to publish to the good old Moodle plugins directory, these are the steps to transition your release process to the Moodle Marketplace:

* Login to the [Moodle Marketplace](https://marketplace.moodle.com/) with your Moodle Marketplace account (which has the rights to publish new releases of the particular plugin, of course).
* Go to the [Account security page](https://marketplace.moodle.com/account/security).
* Create a new token without an expiry date.
* Go to your Github repository's or organization's actions secrets management page.
* Update the value of the existing `MOODLE_ORG_TOKEN` secret and set the token which you just created in the Moodle Marketplace as its new content.
* (Sometime later) Try to publish a new release by pushing a new tag to Github.

### More things to know about the Moodle Marketplace release process

Compared to the previous release process which published to the good old Moodle plugins directory, the Moodle HQ tool works differently in some aspects which are relevant for your plugin repository:

* The plugin's frankenstyle name is not derived from the Github repository name anymore. It is read from the `$plugin->component` setting in the `version.php` file in the root of your plugin repository. Your repository does not have to follow the `moodle-<frankenstyle_pluginname>` naming convention anymore. Consequently, the `plugin-name` parameter of this workflow has become pointless. It is still accepted, but ignored, so that plugin repositories which set it do not break. You can remove it from your caller workflow at any time.
* Your ZIP package is not downloaded from Github anymore. It is built within the workflow run from the tagged code with `git archive`. If your repository ships a `.gitattributes` file with `export-ignore` entries, these files will not be part of the released ZIP package.
* The release notes are determined in this order: the `release_notes` parameter of this workflow if you set it, then the description of the Github release which belongs to the tag, then the first changelog file which exists in the root of your plugin (`CHANGES.md`, `CHANGES.txt`, `CHANGES.html`, `CHANGES`, `CHANGELOG.md`, `CHANGELOG.txt`, `CHANGELOG.html`, `CHANGELOG` or `UPGRADING.md`, matched regardless of upper and lower case). If none of these yields anything, the plugin version is published without any release notes. Please note that the changelog file is published as a whole, not just the section which belongs to the released version.


Bug and problem reports / Support requests
------------------------------------------

This workflow collection is carefully developed and thoroughly tested, but bugs and problems can always appear.

Please report bugs and problems on GitHub:
https://github.com/moodle-an-hochschulen/moodle-workflows/issues

We will do our best to solve your problems, but please note that due to limited resources we can't always provide per-case support.


Feature proposals
-----------------

Due to limited resources, the functionality of these workflows is primarily implemented for our own local needs and published as-is to the community. We are aware that members of the community will have other needs and would love to see them solved by these workflows.

Please issue feature proposals on GitHub:
https://github.com/moodle-an-hochschulen/moodle-workflows/issues

Please create pull requests on GitHub:
https://github.com/moodle-an-hochschulen/moodle-workflows/pulls

We are always interested to read about your feature proposals or even get a pull request from you, but please accept that we can handle your issues only as feature _proposals_ and not as feature _requests_.


Moodle release support
----------------------

These workflows are maintained to support current and LTS releases of Moodle. The CI matrix configuration is regularly updated to include new PHP versions and Moodle releases.


Maintainers
-----------

These workflows are maintained by\
Moodle an Hochschulen e.V.


Copyright
---------

The copyright of these workflows is held by\
Moodle an Hochschulen e.V.

Individual copyrights of individual developers are tracked in Git commits.


Credits
-------

This workflow collection and the Moodle plugin automation as a whole would not have been possible by the groundwork of Moodle HQ.

In addition to that, this collection was highly inspired by previous work and similar collections by [Catalyst IT](https://github.com/catalyst/catalyst-moodle-workflows), [University of Münster](https://github.com/learnweb/moodle-workflows-learnweb) and the [Moodle-Opencast Community](https://github.com/Opencast-Moodle/moodle-workflows-opencast)
