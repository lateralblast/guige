#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2046

# Function: get_ssh_key
#
# Get SSH key if option set

get_ssh_key () {
  if ! [ -f "/.dockerenv" ]; then
    if [ "${options['sshkey']}" = "true" ]; then
      if [ "${iso['sshkey']}" = "" ]; then
        if [ "${iso['sshkeyfile']}" = "" ]; then
          information_message "Attempting to find SSH key file"
          key_file=$( find $HOME/.ssh -name "*.pub" |head -1 )
          if [ ! "${key_file}" = "" ]; then
            information_message "No SSH key file found"
            information_message "Disabling use of SSH key file"
          else
            information_message "SSH key file found: ${key_file}"
            iso['sshkeyfile']="${key_file}"
            iso['sshkey']=$(<"${iso['sshkeyfile']}")
          fi
        else
          if ! [ -f "${iso['sshkeyfile']}" ]; then
            warning_message "SSH Key file (${iso['sshkeyfile']}) does not exist"
            information_message "Disabling use of SSH key file"
          else
            iso['sshkey']=$(<"${iso['sshkeyfile']}")
          fi
        fi
      fi
    fi
  fi
}
