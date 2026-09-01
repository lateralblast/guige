#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: check_ipmitool
#
# Check if ipmitool is installed

check_ipmitool () {
  check_ipmitool=$( command -v ipmitool | grep -c ipmitool )
  if [ -z "${check_ipmitool}" ]; then
    warning_message "ipmitool not found"
    do_exit
  fi
}

# Function: execute_ipmitool
#
# Execute ipmitool command

execute_ipmitool () {
  check_ipmitool
  execute_command "ipmitool -I lanplus -H ${iso['bmcip']} -U ${iso['bmcusername']} -P ${iso['bmcpassword']} ${iso['ipmicommand']}"
}