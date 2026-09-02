#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: execute_racadm
#
# Execute racadm commands

execute_racadm () {
  handle_output "# Executing racadm" "TEXT"
  if [ "${iso['sshpass']}" = "" ]; then
    execute_command "${iso['racadm']} -r ${iso['bmcip']} -u ${iso['bmcusername']} -p ${iso['bmcpassword']} remoteimage -d"
    if [ "${iso['bootserverprotocol']}" = "smb" ]; then
      execute_command "${iso['racadm']} -r ${iso['bmcip']} -u ${iso['bmcusername']} -p ${iso['bmcpassword']} remoteimage -c -u \"${iso['bootserverusername']}\" -p \"${iso['bootserverpassword']}\" -l //${iso['bootserverip']}${iso['bootserverfile']}"
    else
      execute_command "${iso['racadm']} -r ${iso['bmcip']} -u ${iso['bmcusername']} -p ${iso['bmcpassword']} remoteimage -c -u \"${iso['bootserverusername']}\" -p \"${iso['bootserverpassword']}\" -l ${iso['bootserverip']}:${iso['bootserverfile']}"
    fi
    execute_command "${iso['racadm']} -r ${iso['bmcip']} -u ${iso['bmcusername']} -p ${iso['bmcpassword']} config -g cfgServerInfo -o cfgServerBootOnce 1"
    execute_command "${iso['racadm']} -r ${iso['bmcip']} -u ${iso['bmcusername']} -p ${iso['bmcpassword']} config -g cfgServerInfo -o cfgServerFirstBootDevice VCD-DVD"
    execute_command "${iso['racadm']} -r ${iso['bmcip']} -u ${iso['bmcusername']} -p ${iso['bmcpassword']} serveraction powercycle"
  else
    execute_command "${iso['sshpass']} -p${iso['bmcpassword']} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l ${iso['bmcusername']} ${iso['bmcip']} \"racadm remoteimage -d\""
    if [ "${iso['bootserverprotocol']}" = "smb" ]; then
      execute_command "${iso['sshpass']} -p${iso['bmcpassword']} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l ${iso['bmcusername']} ${iso['bmcip']} \"racadm remoteimage -c -u \\\"${iso['bootserverusername']}\\\" -p \\\"${iso['bootserverpassword']}\\\" -l //${iso['bootserverip']}${iso['bootserverfile']}\""
    else
      execute_command "${iso['sshpass']} -p${iso['bmcpassword']} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l ${iso['bmcusername']} ${iso['bmcip']} \"racadm remoteimage -c -u \\\"${iso['bootserverusername']}\\\" -p \\\"${iso['bootserverpassword']}\\\" -l ${iso['bootserverip']}:${iso['bootserverfile']}\""
    fi
    execute_command "${iso['sshpass']} -p${iso['bmcpassword']} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l ${iso['bmcusername']} ${iso['bmcip']} \"racadm config -g cfgServerInfo -o cfgServerBootOnce 1\""
    execute_command "${iso['sshpass']} -p${iso['bmcpassword']} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l ${iso['bmcusername']} ${iso['bmcip']} \"racadm config -g cfgServerInfo -o cfgServerFirstBootDevice VCD-DVD\""
    execute_command "${iso['sshpass']} -p${iso['bmcpassword']} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l ${iso['bmcusername']} ${iso['bmcip']} \"racadm serveraction powercycle\""
  fi
}

# Function: check_racadm
#
# Check racadm

check_racadm () {
  handle_output "# Checking racadm" "TEXT"
  racadm_test=$( command -v racadm )
  if [ -z "${racadm_test}" ] || [ "${options['usesshpass']}" = "true" ]; then
    warning_message "Cannot find racadm"
    sshpass_test=$( command -v sshpass )
    if [ -z "${sshpass_test}" ]; then
      warning_message "Cannot find sshpass"
      do_exit
    else
      iso['sshpass']="${sshpass_test}"
    fi
  else
    iso['racadm']="${racadm_test}"
  fi
}
