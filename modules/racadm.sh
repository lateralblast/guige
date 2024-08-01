#!/usr/bin/env bash

# shellcheck disable=SC2129

# Function: execute_racadm
#
# Execute racadm commands

execute_racadm () {
  if [ "$TEST_MODE" = "false" ]; then
    handle_output "# Executing racadm" TEXT
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "remoteimage -d"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "remoteimage -c -l $BOOT_SERVER_IP:BOOT_SERVER_FILE"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "config -g cfgServerInfo -o cfgServerBootOnce 1"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "config -g cfgServerInfo -o cfgServerFirstBootDevice VCD-DVD"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "serveraction powercycle"
  fi
}

# Function: check_racadm
#
# Check racadm

check_racadm () {
  handle_output "# Checking racadm" TEXT
  RACADM_TEST=$( which racadm |grep "^/" )
  if [ -z "$RACADM_TEST" ]; then
    if ! [ -f "$HOME/.local/bin/racadm" ]; then
      PIP_TEST=$( which pip |grep "^/" )
      if [ -n "$PIP_TEST" ]; then
        PIP_TEST=$( pip list |grep rac |awk '{print $1}')
        if [ -z "$PIP_TEST" ]; then
          handle_output "pip install --user rac" ""
          if [ "$TEST_MODE" = "false" ]; then
            pip install --user rac
            RACADM_BIN="$HOME/.local/bin/racadm"
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
      RACADM_BIN="$HOME/.local/bin/racadm"
    fi
  else
    RACADM_BIN="$RACADM_TEST"
  fi
}
