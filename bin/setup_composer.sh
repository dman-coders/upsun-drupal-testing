#!/usr/bin/env bash
set -e

# Set up composer-level configuration for Drupal testing.
# Adds test runner shortcuts to composer scripts.
#
# This script is automatically run via composer post-install/post-update hooks.
# Expected to run from inside the container context where composer ran.

# The name of the web docroot relative to the app root. Usually `web` or `docroot`
WEB_ROOT="web";

# Utilities
script_path=$(dirname "$(readlink -f "$0")")
source "$script_path/utilities.lib"

# If the app root is not the same as project root, (nested applications) find the project root.
COMPOSER_JSON_PATH=$(realpath $(find_composer_json))
APP_ROOT=$(dirname "$COMPOSER_JSON_PATH")
log_info "Working composer location is $COMPOSER_JSON_PATH , APP_ROOT is $APP_ROOT";
cd $APP_ROOT

# Check if drupal/core-dev is installed
check_drupal_core_dev() {
  if [ ! -d "vendor/drupal/core-dev" ]; then
    log_warning "drupal/core-dev is not installed. This package requires it as a dev dependency."
    log_warning "Run: composer require --dev drupal/core-dev"
    return 1
  fi
  log_info "drupal/core-dev is installed."
  return 0
}

# Add sample test runner scripts to composer.json for easy invocation
add_sample_run_tests_as_composer_scripts() {
  log_notice "Running: ${FUNCNAME[0]}"

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    log_warning "jq is not installed. Cannot add composer scripts automatically."
    log_info "Install jq or manually add test scripts to composer.json"
    return 0
  fi

  # We run from webroot, so the config file is relative to that.
  phpunit_xml_file="core/phpunit.xml.dist"

  log_info "Add command to run a core Functional test into composer scripts"
  the_test="core/modules/block/tests/src/Functional/BlockTest.php"
  the_alias="run-tests-core-blocktest"
  the_script="cd ${WEB_ROOT} && XDEBUG_MODE=off phpunit --configuration ${phpunit_xml_file} ${the_test}"

  # Check if script already exists
  existing_script=$(jq -r ".scripts.\"${the_alias}\" // empty" "$COMPOSER_JSON_PATH")
  if [ -n "$existing_script" ]; then
    log_info "Script '${the_alias}' already exists, skipping."
  else
    jq ".scripts.\"${the_alias}\" = \"${the_script}\"" "$COMPOSER_JSON_PATH" \
      > composer.json.tmp && mv composer.json.tmp "$COMPOSER_JSON_PATH"
    log_info "Added script: composer ${the_alias}"
  fi

  log_info "Add command to run a core FunctionalJavascript test into composer scripts"
  the_test="core/modules/system/tests/src/FunctionalJavascript/FrameworkTest.php"
  the_alias="run-tests-core-javascript"
  the_script="cd ${WEB_ROOT} && XDEBUG_MODE=off phpunit --configuration ${phpunit_xml_file} ${the_test}"

  existing_script=$(jq -r ".scripts.\"${the_alias}\" // empty" "$COMPOSER_JSON_PATH")
  if [ -n "$existing_script" ]; then
    log_info "Script '${the_alias}' already exists, skipping."
  else
    jq ".scripts.\"${the_alias}\" = \"${the_script}\"" "$COMPOSER_JSON_PATH" \
      > composer.json.tmp && mv composer.json.tmp "$COMPOSER_JSON_PATH"
    log_info "Added script: composer ${the_alias}"
  fi
}

# Main execution
log_notice "=== Setting up Drupal Testing (Composer Configuration) ==="

if check_drupal_core_dev; then
  add_sample_run_tests_as_composer_scripts

  log_notice "Composer setup complete!"
  log_info ""
  log_info "Next steps:"
  log_info "  - For DDEV: Run 'vendor/upsun/drupal-testing/bin/setup_ddev.sh' from the host"
  log_info "  - For Upsun/Platform.sh: Run 'vendor/upsun/drupal-testing/bin/setup_platform.sh'"
  log_info ""
  log_info "Test your setup with:"
  log_info "  composer run-tests-core-blocktest"
fi
