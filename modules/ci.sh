#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034
# shellcheck disable=SC2153

# Funtion update_iso_url
#
# Update CI URL

update_ci_url () {
  BASE_ISO_INPUTCI=$( basename "$ISO_INPUTCI" )
  if [ "$ISO_CODENAME" = "ubuntu" ]; then
    case $ISO_BUILDTYPE in
      "daily-live"|"daily-live-server")
        CI_URL="https://cloud-images.ubuntu.com/daily/server/$ISO_CODENAME/current/$BASE_ISO_INPUTCI"
        ;;
      *)
        CI_URL="https://cloud-images.ubuntu.com/releases/$ISO_RELEASE/release/$BASE_ISO_INPUTCI"
        ;;
    esac
  fi
}

# Function: get_base_ci
#
# Get base Cloud Image

get_base_ci () {
  handle_output "# Check source Cloud Image exists and grab it if it doesn't" "TEXT"
  BASE_ISO_INPUTCI=$( basename "$ISO_INPUTCI" )
  CI_DIR=$( dirname $ISO_INPUTCI )
  if [ ! -d "$CI_DIR" ]; then
    sudo_create_dir "$CI_DIR"
    sudo_chown "$CI_DIR" "$OS_USER" "$OS_GROUP"
  fi
  if [ "$DO_ISO_FULLFORCEMODE" = "true" ]; then
    handle_output "rm $ISO_WORKDIR/files/$BASE_ISO_INPUTCI" ""
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      rm "$ISO_WORKDIR/files/$BASE_ISO_INPUTCI"
    fi
  fi
  check_base_ci_file
  if [ "$DO_CHECK_CI" = "true" ]; then
    cd "$ISO_WORKDIR/files" || exit ; wget -N "$CI_URL"
  else
    if ! [ -f "$ISO_WORKDIR/files/$BASE_ISO_INPUTCI" ]; then
      if [ "$DO_ISO_TESTMODE" = "false" ]; then
        wget "$CI_URL" -O "$ISO_WORKDIR/files/$BASE_ISO_INPUTCI"
      fi
    fi
  fi
}

# Function: check_base_ci_file
#
# Check base Cloud Image file exists

check_base_ci_file () {
  if [ -f "$ISO_INPUTCI" ]; then
    BASE_ISO_INPUTCI=$( basename "$ISO_INPUTCI" )
    FILE_TYPE=$( file "$ISO_WORKDIR/files/$BASE_ISO_INPUTCI" |cut -f2 -d: |grep -E "QCOW" |wc -l |sed "s/ //g" )
    if [ "$FILE_TYPE" = "0" ]; then
      warning_message "$ISO_WORKDIR/files/$BASE_ISO_INPUTCI is not a valid Cloud Image file"
      exit
    fi
  fi
}
