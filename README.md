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
- **Concurrency handling** to cancel running jobs if a new commit is pushed to the same branch
- **Consecutive runtime testing** where the code is initially tested with the highest PHP version and Postgres only and the full matrix is only tested if that initial test was successful with the goal to save ressources
- **Additional services support** including Redis service for plugins that require caching or session storage as well as Docker Compose support for arbitrary backend services like LDAP containers
- **Pull request content validation** to automatically check PR content for required or forbidden text patterns, enforce ticket references, limit PR size, and exempt specific users from checks
- **Flexible error handling** for code quality checks with configurable continue-on-error behavior for phpcs and mustache lint steps
- **Flexible pre-install script** for running a custom script before installing moodle-plugin-ci
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

### Available parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `moodle-core-branch` | string | No | auto-detected | Run the tests on this Moodle core branch (if not provided, the branch will be auto-detected from current branch) |
| `plugin-dependencies` | string | No | - | List of plugin dependencies with repository and branch (use one dependency per line and separate repository and branch with a comma) |
| `one-db-only` | boolean | No | false | Use only PostgreSQL database instead of all configured databases |
| `max-parallel-verify` | number | No | unlimited | Maximum number of parallel jobs for the verify job (can be useful if you have really long running Behat tests and do not want to block too many runners at the same time) |
| `redis-enabled` | boolean | No | false | Start Redis service before running runtime tests |
| `php-extensions` | string | No | - | PHP extensions to install (e.g., "redis", "memcached", "redis,imagick") |
| `docker-compose-file` | string | No | - | Path to Docker Compose file (relative to plugin repository root) for starting an additional service |
| `pre-install-script` | string | No | - | Custom script to run before installing moodle-plugin-ci (multiline bash script) |
| `behat-suite` | string | No | - | The theme to be used for running Behat tests (e.g. "boost_union") |
| `behat-tags` | string | No | - | Behat tags to filter which Behat scenarios to run (e.g. "@javascript"). Separate multiple tags with a comma, but without any spaces in-between. |
| `behat-timeout` | number | No | - | Behat timeout multiplier (e.g. 3 for 3x timeout) |
| `behat-slices` | number | No | 1 | Number of parallel Behat slices to split the Behat run across (1 = no splitting). Each slice runs a subset of the plugin's Behat feature files in its own job, distributed by scenario count. |
| `pr-check-diff-contains` | string | No | - | Pull request diff must contain this text |
| `pr-check-diff-does-not-contain` | string | No | - | Pull request diff must not contain this text |
| `pr-check-body-contains` | string | No | - | Pull request body must contain this text |
| `pr-check-body-does-not-contain` | string | No | - | Pull request body must not contain this text |
| `pr-check-files-changed` | string | No | - | Number of files that must have changed in pull request |
| `pr-check-lines-changed` | string | No | - | Number of lines that must have changed in pull request |
| `pr-check-waived-users` | string | No | - | Comma-separated list of users exempt from pull request checks |
| `phpcs-continue-on-error` | boolean | No | false | Continue on error for Moodle Code Checker (phpcs) |
| `mustache-continue-on-error` | boolean | No | false | Continue on error for Mustache Lint |
| `scss-deprecations` | boolean | No | true | Include SCSS deprecation warnings in Behat tests |

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

An automated release workflow for publishing Moodle plugins to the official [Moodle plugins directory](https://moodle.org/plugins) based on the [moodle-plugin-release](https://github.com/moodlehq/moodle-plugin-release) tool.

### Enhanced features beyond standard moodle-plugin-release

- **Automatic plugin name detection** from the Plugin repository name

### Usage

Create a workflow file in your plugin repository at `.github/workflows/moodle-release.yml`:

#### With automated plugin name detection (recommended)

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

#### With manual plugin name definition

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
    with:
      plugin-name: theme_boost_union
    secrets:
      MOODLE_ORG_TOKEN: ${{ secrets.MOODLE_ORG_TOKEN }}
```

### Available parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `plugin-name` | string | No | auto-detected | Plugin frankenstyle name (if not provided, it will be auto-detected from the repository name) |

### Required Github actions secrets

| Secret | Description |
|--------|-------------|
| `MOODLE_ORG_TOKEN` | API token for Moodle.org plugins directory (see https://moodledev.io/general/community/plugincontribution/pluginsdirectory/api#access-token for help) |

### Repository naming convention

For automatic plugin name detection to work, the plugin repository must follow the naming convention:

`moodle-<frankenstyle_pluginname>`

#### Examples

- `moodle-local_mylocalplugin` → Plugin name: `local_mylocalplugin`
- `moodle-mod_customactivity` → Plugin name: `mod_customactivity`
- `moodle-theme_mytheme` → Plugin name: `theme_mytheme`


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
