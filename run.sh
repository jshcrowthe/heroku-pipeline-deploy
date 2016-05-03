#!/bin/bash
set -e;

main() {
  local exit_code_promote=0;
  local exit_code_run=0;

  # Initialize some values
  init_wercker_environment_variables;
  init_netrc "$WERCKER_HEROKU_PIPELINE_DEPLOY_USER" "$WERCKER_HEROKU_PIPELINE_DEPLOY_KEY";

  # Test authentication to verify it works
  test_authentication "$WERCKER_HEROKU_PIPELINE_DEPLOY_APP_NAME";

  # Install heroku toolbelt to do promotions
  install_toolbelt;

  # Promote application
  if [[ -z $WERCKER_HEROKU_PIPELINE_DEPLOY_TO ]]; then
    heroku pipelines:promote -a "$WERCKER_HEROKU_PIPELINE_DEPLOY_FROM" || exit_code_promote=1
  else
    heroku pipelines:promote -a "$WERCKER_HEROKU_PIPELINE_DEPLOY_FROM" --to "$WERCKER_HEROKU_PIPELINE_DEPLOY_TO" || exit_code_promote=1
  fi

  # Run a command, if the push succeeded and the user supplied a run command
  if [ -n "$WERCKER_HEROKU_PIPELINE_DEPLOY_RUN" ]; then
    if [ $exit_code_promote -eq 0 ]; then
      set +e;
      execute_heroku_command "$WERCKER_HEROKU_PIPELINE_DEPLOY_APP_NAME" "$WERCKER_HEROKU_PIPELINE_DEPLOY_RUN";
      exit_code_run=$?
      set -e;
    fi
  fi

  if [ $exit_code_run -ne 0 ]; then
    fail "Heroku run failed (Command: $WERCKER_HEROKU_PIPELINE_DEPLOY_RUN)";
  fi

  if [ $exit_code_promote -eq 0 ]; then
    success 'Heroku app promotion finished successfully';
  else
    fail "Heroku promote for app $WERCKER_HEROKU_PIPELINE_DEPLOY_FROM failed";
  fi
}

init_wercker_environment_variables() {
  # verify user not empty
  if [ -z "$WERCKER_HEROKU_PIPELINE_DEPLOY_USER" ]; then
    fail "user property is required"
  fi

  # verify key not empty
  if [ -z "$WERCKER_HEROKU_PIPELINE_DEPLOY_KEY" ]; then
    fail "key property is required (API key)"
  fi

  # verify from not empty
  if [ -z "$WERCKER_HEROKU_PIPELINE_DEPLOY_FROM" ]; then
    fail "from property is required"
  fi
}

# init_netrc($username, $password) appends the machine credentials for Heroku to
# the ~/.netrc file, make sure it is .
init_netrc() {
  local username="$1";
  local password="$2";
  local netrc="$HOME/.netrc";

  {
    echo "machine api.heroku.com"
    echo "  login $username"
    echo "  password $password"
  } >> "$netrc"

  chmod 0600 "$netrc";
}

install_toolbelt() {
  check_ruby;

  if ! type heroku &> /dev/null; then
    info 'heroku toolbelt not found, starting installing it';

  # extract from $steproot/heroku-client.tgz into /usr/local/heroku
  sudo rm -rf /usr/local/heroku
  sudo cp -r "$WERCKER_STEP_ROOT/vendor/heroku" /usr/local/heroku
  export PATH="/usr/local/heroku/bin:$PATH"

  info 'finished heroku toolbelt installation';
  else
    info 'heroku toolbelt is available, and will not be installed by this step';
  fi

  debug "type heroku: $(type heroku)";
  debug "heroku version: $(heroku --version)";
}

execute_heroku_command() {
  local app_name="$1";
  local command="$2";

  debug "starting heroku run $command";
  heroku run "$command" --app "$app_name";
  local exit_code_run=$?;

  debug "heroku run exited with $exit_code_run";
  return $exit_code_run;
}

test_authentication() {
  local app_name="$1"

  check_curl;

  set +e;
  curl -n --fail \
  -H "Accept: application/vnd.heroku+json; version=3" \
  https://api.heroku.com/account > /dev/null 2>&1;
  local exit_code_authentication_test=$?;
  set -e;

  if [ $exit_code_authentication_test -ne 0 ]; then
    fail 'Unable to retrieve account information, please check your Heroku Username and API key';
  fi

  set +e;
  curl -n --fail \
  -H "Accept: application/vnd.heroku+json; version=3" \
  "https://api.heroku.com/apps/$app_name" > /dev/null 2>&1;
  local exit_code_app_test=$?
  set -e;

  if [ $exit_code_app_test -ne 0 ]; then
    fail 'Unable to retrieve application information, please check if the Heroku application still exists';
  fi
}

check_curl() {
  if ! type curl &> /dev/null; then
    if ! type apt-get &> /dev/null; then
      fail "curl is not available. Install it, and make sure it is available in \$PATH"
    else
      debug "curl not found; installing it."

      sudo apt-get update;
      sudo apt-get install curl -y;
    fi
  fi
}

check_ruby() {
  if ! type ruby &> /dev/null; then
    if ! type apt-get &> /dev/null; then
      fail "ruby is not available. Install it, and make sure it is available in \$PATH"
    else
      debug "ruby not found; installing it."

      sudo apt-get update;
      sudo apt-get install ruby-full -y;
    fi
  fi
}

main;