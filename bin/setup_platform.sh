#!/usr/bin/env bash
set -e

# Set up Platform.sh/Upsun-specific configuration for Drupal testing.
# Configures writable simpletest directories in deployment YAMLs.
#
# This script should be run from inside the application container context.
# Run this AFTER composer require upsun/drupal-testing has completed.

# The name of the web docroot relative to the app root. Usually `web` or `docroot`
WEB_ROOT="web";

# Utilities
script_path=$(dirname "$(readlink -f "$0")")
source "$script_path/utilities.lib"
source "$script_path/setup.lib"

# If the app root is not the same as project root, (nested applications) find the project root.
COMPOSER_JSON_PATH=$(realpath $(find_composer_json))
APP_ROOT=$(dirname "$COMPOSER_JSON_PATH")
log_info "Working from APP_ROOT: $APP_ROOT";
cd $APP_ROOT

# Main execution
log_notice "=== Setting up Drupal Testing (Platform.sh/Upsun Configuration) ==="

# Try to configure both Platform.sh and Upsun (one or both may exist)
add_simpletest_dir_as_writable_on_platformsh
add_simpletest_dir_as_writable_on_upsun

log_notice "Platform configuration complete!"
log_info ""
log_info "Modified files (if they existed):"
log_info "  - .platform.app.yaml"
log_info "  - .upsun/config.yaml"
log_info ""
log_info "Review the changes and commit them to your repository."
log_info "The simpletest directory is now configured as a writable mount."
