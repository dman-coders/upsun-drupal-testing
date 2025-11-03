
# Upsun Drupal Testing

This package configures Drupal projects for PHPUnit and Selenium testing, supporting local development (DDEV) and cloud deployment (Upsun/Platform.sh).

## What it does

* Adds `drupal/core-dev` as a development dependency
* Configures composer scripts for running common test suites
* Provides environment-specific setup scripts for DDEV and Upsun/Platform.sh

## Installation

### 1. Install Package (from inside container)

```bash
composer require --dev upsun/drupal-testing
```

The package automatically configures composer scripts via post-install hooks.

### 2. Environment Setup (optional)

Choose the appropriate setup script for your environment:

#### For DDEV (from host machine)

```bash
vendor/upsun/drupal-testing/bin/setup_ddev.sh
```

This installs the Selenium standalone chrome addon and restarts DDEV.

#### For Upsun/Platform.sh (from inside container)

```bash
vendor/upsun/drupal-testing/bin/setup_platform.sh
```

This configures writable simpletest directories in your deployment YAML files.

## Usage

After installation, you can run tests using composer scripts:

```bash
# Functional test (no JavaScript)
composer run-tests-core-blocktest

# FunctionalJavascript test (requires Selenium)
composer run-tests-core-javascript
```

## Development Install (local library)

If you're developing this package locally, you can use it as a path repository:

```bash
# From inside DDEV
composer config repositories.upsun-drupal-testing \
  '{"type": "path", "url": "/var/www/html/repositories/upsun-drupal-testing", "options": {"symlink": true}}'
composer require --dev upsun/drupal-testing:@dev
```

Or from a remote VCS repository:

```bash
composer config repositories.drupal-testing vcs git@github.com:dman-coders/upsun-drupal-testing
composer require --dev upsun/drupal-testing:dev-main
```

## Troubleshooting

### Selenium browser testing (DDEV)

Check if Selenium is running:

```bash
ddev describe
```

Selenium should be available at:
- **Internal (for tests):** `selenium-chrome:4444`
- **VNC viewer (for debugging):** `https://${DDEV_SITENAME}:7900`

Environment variables are configured in `.ddev/config.selenium-standalone-chrome.yaml`

### Known Issues

**Element click failures in JavaScript tests:** There is a known compatibility issue between `lullabot/php-webdriver` (used by Drupal 10.5.x) and Selenium Grid 4.x where some element click operations fail with 400 errors. This is a limitation of the current Drupal testing stack. Most tests work correctly, but some that require click interactions may fail.

## Requirements

* Drupal 10.x or 11.x
* `drupal/core-dev` (automatically installed)
* For DDEV: DDEV v1.21+
* For Platform.sh/Upsun: `yq` command-line tool

## Architecture

The package separates concerns across three execution contexts:

1. **Composer scripts** (`setup_composer.sh`) - Run inside container, configure composer.json
2. **DDEV setup** (`setup_ddev.sh`) - Run from host, configure DDEV addons
3. **Platform setup** (`setup_platform.sh`) - Run inside container, configure deployment YAMLs

This separation allows the core package to work in any environment while providing optional wrappers for specific platforms.