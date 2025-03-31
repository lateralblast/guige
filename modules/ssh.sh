#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2046

# Function: get_ssh_key
#
# Get SSH key if option set

get_ssh_key () {
  if ! [ -f "/.dockerenv" ]; then
    if [ "$DO_ISO_SSHKEY" = "true" ]; then
      if [ "$ISO_SSHKEY" = "" ]; then
        if [ "$ISO_SSHKEYFILE" = "" ]; then
          information_message "Attempting to find SSH key file"
          KEY_FILE=$( find $HOME/.ssh -name "*.pub" |head -1 )
          if [ ! "$KEY_FILE" = "" ]; then
            information_message "No SSH key file found"
            information_message "Disabling use of SSH key file"
          else
            information_message "SSH key file found: $KEY_FILE"
            ISO_SSHKEYFILE="$KEY_FILE"
            ISO_SSHKEY=$(<"$ISO_SSHKEYFILE")
          fi
        else
          if ! [ -f "$ISO_SSHKEYFILE" ]; then
            warning_message "SSH Key file ($ISO_SSHKEYFILE) does not exist"
            information_message "Disabling use of SSH key file"
          else
            ISO_SSHKEY=$(<"$ISO_SSHKEYFILE")
          fi
        fi
      fi
    fi
  fi
}
