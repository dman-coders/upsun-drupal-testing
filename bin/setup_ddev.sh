#!/usr/bin/env bash
set -e

# Set up DDEV-specific configuration for Drupal testing.
# Adds Selenium standalone chrome addon.
#
# This script must be run from the HOST (not inside the container).
# Run this AFTER composer require upsun/drupal-testing has completed.

# Utilities
script_path=$(dirname "$(readlink -f "$0")")
source "$script_path/utilities.lib"

# Check if we're running inside DDEV (we shouldn't be)
if [ -n "$DDEV_HOSTNAME" ]; then
  log_warning "This script should be run from the HOST, not inside the DDEV container."
  log_warning "Exit the container and run: vendor/upsun/drupal-testing/bin/setup_ddev.sh"
  exit 1
fi

# Check if ddev is available
if ! command -v ddev &> /dev/null; then
  log_warning "ddev command not found. Is DDEV installed?"
  log_info "See: https://ddev.readthedocs.io/en/stable/"
  exit 1
fi

# Check if we're in a DDEV project
if [ ! -f ".ddev/config.yaml" ]; then
  log_warning "No .ddev/config.yaml found. Are you in a DDEV project root?"
  log_warning "Run this script from your project root directory."
  exit 1
fi

# Add DDEV Selenium addon
add_ddev_addon() {
  log_notice "=== Setting up DDEV Selenium Addon ==="

  # @see https://github.com/ddev/ddev-selenium-standalone-chrome
  add_on="ddev/ddev-selenium-standalone-chrome"

  # Look ahead to avoid unnecessary restarts.
  already_installed=$(ddev add-on list --installed | grep "${add_on}" || true);
  if [[ -n "${already_installed}" ]]; then
    log_info "Selenium add-on ${add_on} is already installed, skipping."
    return 0
  else
    log_notice "Adding Selenium component to ddev container"
    ddev add-on get ddev/ddev-selenium-standalone-chrome
    log_notice "Restarting DDEV to apply changes..."
    ddev restart
  fi
}

# Main execution
log_notice "=== Setting up Drupal Testing (DDEV Configuration) ==="

add_ddev_addon

log_notice "DDEV setup complete!"
log_info ""
log_info "Selenium is now available at:"
log_info "  - Internal: selenium-chrome:4444"
log_info "  - VNC viewer: https://\${DDEV_SITENAME}:7900"
log_info ""
log_info "Test your setup with:"
log_info "  ddev composer run-tests-core-blocktest"
log_info "  ddev composer run-tests-core-javascript"
