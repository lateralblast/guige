#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034
# shellcheck disable=SC2153

# Funtion update_iso_url
#
# Update CI URL

update_ci_url () {
  BASE_CI_INPUT_FILE=$( basename "$CI_INPUT_FILE" )
  if [ "$ISO_OS_NAME" = "ubuntu" ]; then
    case $ISO_BUILD_TYPE in
      "daily-live"|"daily-live-server")
        CI_URL="https://cloud-images.ubuntu.com/daily/server/$ISO_CODENAME/current/$BASE_CI_INPUT_FILE"
        ;;
      *)
        CI_URL="https://cloud-images.ubuntu.com/releases/$ISO_RELEASE/release/$BASE_CI_INPUT_FILE"
        ;;
    esac
  fi
}

# Function: get_base_ci
#
# Get base Cloud Image

get_base_ci () {
  handle_output "# Check source Cloud Image exists and grab it if it doesn't" "TEXT"
  BASE_CI_INPUT_FILE=$( basename "$CI_INPUT_FILE" )
  CI_DIR=$( dirname $CI_INPUT_FILE )
  if [ ! -d "$CI_DIR" ]; then
    sudo_create_dir "$CI_DIR"
    sudo_chown "$CI_DIR" "$OS_USER" "$OS_GROUP"
  fi
  if [ "$FULL_FORCE_MODE" = "true" ]; then
    handle_output "rm $WORK_DIR/files/$BASE_CI_INPUT_FILE" ""
    if [ "$TEST_MODE" = "false" ]; then
      rm "$WORK_DIR/files/$BASE_CI_INPUT_FILE"
    fi
  fi
  check_base_ci_file
  if [ "$DO_CHECK_CI" = "true" ]; then
    cd "$WORK_DIR/files" || exit ; wget -N "$CI_URL"
  else
    if ! [ -f "$WORK_DIR/files/$BASE_CI_INPUT_FILE" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        wget "$CI_URL" -O "$WORK_DIR/files/$BASE_CI_INPUT_FILE"
      fi
    fi
  fi
}

# Function: check_base_ci_file
#
# Check base Cloud Image file exists

check_base_ci_file () {
  if [ -f "$CI_INPUT_FILE" ]; then
    BASE_CI_INPUT_FILE=$( basename "$CI_INPUT_FILE" )
    FILE_TYPE=$( file "$WORK_DIR/files/$BASE_CI_INPUT_FILE" |cut -f2 -d: |grep -E "QCOW" |wc -l |sed "s/ //g" )
    if [ "$FILE_TYPE" = "0" ]; then
      warning_message "$WORK_DIR/files/$BASE_CI_INPUT_FILE is not a valid Cloud Image file"
      exit
    fi
  fi
}
