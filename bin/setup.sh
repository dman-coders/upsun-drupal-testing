#!/usr/bin/env bash

# Set up requirements for Drupal testing.
# and add some settings and shortcuts.
#
# Once done, testing invocations will be added to the composer `scripts` for easy finding.

# This is expected to be run from outside a ddev container,
# but will need to `exec` into one for a few reasons.

add_testing_requirements(){
  echo "Running: ${FUNCNAME[0]}" >&2
  ddev exec "composer require --dev drupal/core-dev"
  # @see https://github.com/ddev/ddev-selenium-standalone-chrome
  ddev add-on get ddev/ddev-selenium-standalone-chrome && ddev restart
}


add_sample_run_tests_as_composer_scripts() {
  echo "Running: ${FUNCNAME[0]}" >&2
  # echo "Run a core Functional test"
  # On the environment it would be:
  # vendor/bin/phpunit --configuration phpunit.ddev.xml web/core/modules/block/tests/src/Functional/BlockTest.php
  # phpunit --configuration core/phpunit.xml.dist core/modules/system/tests/src/FunctionalJavascript/FrameworkTest.php
  phpunit_xml_file=web/core/phpunit.xml.dist

  echo "Add command to run a a core Functional test into composer scripts"
  the_test="core/modules/block/tests/src/Functional/BlockTest.php"
  the_alias="run-tests-core-blocktest"
  the_script="cd web && XDEBUG_MODE=off phpunit --configuration ${phpunit_xml_file} ${the_test}"
  jq " .scripts.\"${the_alias}\" = \"${the_script}\"" composer.json \
    > composer.json.tmp && mv composer.json.tmp composer.json

  echo "Invoke that new test script '${the_alias}' via composer"
  ddev exec "composer ${the_alias}"

  the_test="core/modules/system/tests/src/FunctionalJavascript/FrameworkTest.php"
  the_alias="run-tests-core-javascript"
  the_script="cd web && XDEBUG_MODE=off phpunit --configuration ${phpunit_xml_file} ${the_test}"
  jq " .scripts.\"${the_alias}\" = \"${the_script}\"" composer.json \
    > composer.json.tmp && mv composer.json.tmp composer.json
  echo "Invoke that new test script '${the_alias}' via composer"
  ddev exec "composer ${the_alias}"
}

add_simpletest_dir_as_writable_on_platformsh(){
  echo "Running: ${FUNCNAME[0]}" >&2
  echo "Add the simpletest directory as a mount so that tests can be run inside platform"
  # requires `yq`
  yq --version || { echo "Please install yq or edit the YAML file manually"; return 1; }
  yaml_snippet='{
      "source": "local",
      "source_path": "simpletest"
  }'
  yq -I4 e ".mounts[\"/web/sites/simpletest\"] = ${yaml_snippet} " .platform.app.yaml -i

  yaml_snippet='{
      "allow": true,
      "root": "web/sites/simpletest"
  }'
  yq -I4 e ".web.locations[\"/sites/simpletest\"] = $yaml_snippet " .platform.app.yaml -i
}
add_simpletest_dir_as_writable_on_upsun(){
  echo "Running: ${FUNCNAME[0]}" >&2
  echo "Add the simpletest directory as a mount so that tests can be run inside upsun"
  # requires `yq`
  yq --version || { echo "Please install yq or edit the YAML file manually"; return 1; }
  yaml_snippet='{
      "source": "storage",
      "source_path": "simpletest"
  }'
  yq -I4 e ".applications.drupal.mounts[\"/web/sites/simpletest\"] = ${yaml_snippet} " .upsun/config.yaml -i

  yaml_snippet='{
      "allow": true,
      "root": "web/sites/simpletest"
  }'
  yq -I4 e ".applications.drupal.web.locations[\"/sites/simpletest\"] = $yaml_snippet " .upsun/config.yaml -i
}

add_testing_requirements
add_simpletest_dir_as_writable_on_platformsh
add_simpletest_dir_as_writable_on_upsun
add_sample_run_tests_as_composer_scripts
