#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: execute_racadm
#
# Execute racadm commands

execute_racadm () {
  if [ "${options['testmode']}" = "false" ]; then
    handle_output "# Executing racadm" "TEXT"
    ${iso['racadm']} -H "${iso['bmcip']}" -u "${iso['bmcusername']}" -p "${iso['bmcpassword']}" -c "remoteimage -d"
    ${iso['racadm']} -H "${iso['bmcip']}" -u "${iso['bmcusername']}" -p "${iso['bmcpassword']}" -c "remoteimage -c -l ${iso['bootserverip']}:iso['bootserverfile']}"
    ${iso['racadm']} -H "${iso['bmcip']}" -u "${iso['bmcusername']}" -p "${iso['bmcpassword']}" -c "config -g cfgServerInfo -o cfgServerBootOnce 1"
    ${iso['racadm']} -H "${iso['bmcip']}" -u "${iso['bmcusername']}" -p "${iso['bmcpassword']}" -c "config -g cfgServerInfo -o cfgServerFirstBootDevice VCD-DVD"
    ${iso['racadm']} -H "${iso['bmcip']}" -u "${iso['bmcusername']}" -p "${iso['bmcpassword']}" -c "serveraction powercycle"
  fi
}

# Function: check_racadm
#
# Check racadm

check_racadm () {
  handle_output "# Checking racadm" "TEXT"
  racadm_test=$( which racadm |grep "^/" )
  if [ -z "${racadm_test}" ]; then
    if ! [ -f "$HOME/.local/bin/racadm" ]; then
      pip_test=$( which pip |grep "^/" )
      if [ -n "${pip_test}" ]; then
        pip_test=$( pip list |grep rac |awk '{print $1}')
        if [ -z "${pip_testi}" ]; then
          handle_output "pip install --user rac" "TEXT"
          if [ "${options['testmode']}" = "false" ]; then
            pip install --user rac
            iso['racadm']="$HOME/.local/bin/racadm"
          else
            handle_output "# No racadm found" "TEXT"
            exit
          fi
        else
          handle_output "# No racadm found" "TEXT"
          handle_output "# No pip found to install Python racadm module" "TEXT"
          exit
        fi
      fi
    else
      iso['racadm']="$HOME/.local/bin/racadm"
    fi
  else
    iso['racadm']="${racadm_test}"
  fi
}
