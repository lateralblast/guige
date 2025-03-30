#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2046

# Function: get_ssh_key
#
# Get SSH key if option set

get_ssh_key () {
  if ! [ -f "/.dockerenv" ]; then
    if [ "$DO_ISO_SSH_KEY" = "true" ]; then
      if [ "$ISO_SSH_KEY" = "" ]; then
        if [ "$ISO_SSH_KEY_FILE" = "" ]; then
          information_message "Attempting to find SSH key file"
          KEY_FILE=$( find $HOME/.ssh -name "*.pub" |head -1 )
          if [ ! "$KEY_FILE" = "" ]; then
            information_message "No SSH key file found"
            information_message "Disabling use of SSH key file"
          else
            information_message "SSH key file found: $KEY_FILE"
            ISO_SSH_KEY_FILE="$KEY_FILE"
            ISO_SSH_KEY=$(<"$ISO_SSH_KEY_FILE")
          fi
        else
          if ! [ -f "$ISO_SSH_KEY_FILE" ]; then
            warning_message "SSH Key file ($ISO_SSH_KEY_FILE) does not exist"
            information_message "Disabling use of SSH key file"
          else
            ISO_SSH_KEY=$(<"$ISO_SSH_KEY_FILE")
          fi
        fi
      fi
    fi
  fi
}
