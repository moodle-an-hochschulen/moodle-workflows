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
- **Behat suite selection** to select the theme to be used for running Behat tests
- **Behat timeout handling** to raise the Behat timeout if the plugin requires it
- **Concurrency handling** to cancel running jobs if a new commit is pushed to the same branch
- **Consecutive runtime testing** where the code is initially tested with the highest PHP version and Postgres only and the full matrix is only tested if that initial test was successful with the goal to save ressources
- **Additional services support** including Redis service for plugins that require caching or session storage as well as Docker Compose support for arbitrary backend services like LDAP containers
- **Pull request content validation** to automatically check PR content for required or forbidden text patterns, enforce ticket references, limit PR size, and exempt specific users from checks
- **Flexible error handling** for code quality checks with configurable continue-on-error behavior for phpcs and mustache lint steps

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
| `behat-suite` | string | No | - | The theme to be used for running Behat tests (e.g. "boost_union") |
| `behat-timeout` | number | No | - | Behat timeout multiplier (e.g. 3 for 3x timeout) |
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

### Automatic Moodle core branch detection

The workflow includes an intelligent Moodle core branch detection that works as follows:

1. **Explicit parameter**: If the `moodle-core-branch` parameter is provided, it is used directly
2. **Branch pattern matching**: If the current plugin branch matches the `MOODLE_XXX_STABLE` pattern, it is used as Moodle core branch as well
3. **Main branch handling**: If the current plugin branch is the `main` branch, the workflow searches for the highest available `MOODLE_XXX_STABLE` branch in the plugin repository and uses it as Moodle core branch
4. **version.php parsing**: As final fallback, especially when testing feature branches with arbitrary namings, the workflow parses the `$plugin->supported` array to determine the maximum supported Moodle version and uses this as Moodle core branch

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
