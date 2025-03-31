#!/usr/bin/env bash

# shellcheck disable=SC2129

# Function: execute_racadm
#
# Execute racadm commands

execute_racadm () {
  if [ "$DO_ISO_TESTMODE" = "false" ]; then
    handle_output "# Executing racadm" TEXT
    $RACADM_BIN -H "$ISO_BMCIP" -u "$ISO_BMCUSERNAME" -p "$ISO_BMCPASSWORD" -c "remoteimage -d"
    $RACADM_BIN -H "$ISO_BMCIP" -u "$ISO_BMCUSERNAME" -p "$ISO_BMCPASSWORD" -c "remoteimage -c -l $ISO_BOOTSERVERIP:ISO_BOOTSERVERFILE"
    $RACADM_BIN -H "$ISO_BMCIP" -u "$ISO_BMCUSERNAME" -p "$ISO_BMCPASSWORD" -c "config -g cfgServerInfo -o cfgServerBootOnce 1"
    $RACADM_BIN -H "$ISO_BMCIP" -u "$ISO_BMCUSERNAME" -p "$ISO_BMCPASSWORD" -c "config -g cfgServerInfo -o cfgServerFirstBootDevice VCD-DVD"
    $RACADM_BIN -H "$ISO_BMCIP" -u "$ISO_BMCUSERNAME" -p "$ISO_BMCPASSWORD" -c "serveraction powercycle"
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
          if [ "$DO_ISO_TESTMODE" = "false" ]; then
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
