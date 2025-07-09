#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2153
# shellcheck disable=SC2154

# Function get_input_ci
#
# Get Input CI

get_input_ci () {
  if [ "${iso['release']}" = "${current['devrelease']}" ]; then
    iso['inputci']="${iso['workdir']}/files/${iso['codename']}-server-cloudimg-${iso['arch']}.img"
  else
    case ${iso['build']} in
      "daily-live"|"daily-live-server")
        iso['inputci']="${iso['workdir']}/files/${iso['codename']}-server-cloudimg-${iso['arch']}.img"
        ;;
      *)
        iso['inputci']="${iso['workdir']}/files/ubuntu-${iso['release']}-server-cloudimg-${iso['arch']}.img"
        ;;
    esac
  fi
}

# Function get_output_ci
#
# Get Output CI

get_output_ci () {
  iso['outputcibase']=$( basename "${iso['inputci']}" )
  iso['outputci']="${iso['workdir']}/file/${iso['outputcibase']}"
}

# Funtion update_ci_url
#
# Update CI URL

update_ci_url () {
  iso['inputcibase']=$( basename "${iso['inputci']}" )
  if [ "${iso['osname']}" = "ubuntu" ]; then
    if [ "${iso['release']}" = "${current['devrelease']}" ]; then
      iso['ciurl']="https://cloud-images.ubuntu.com/daily/server/${iso['codename']}/current/${iso['inputcibase']}"
    else
      case ${iso['build']} in
        "daily-live"|"daily-live-server")
          iso['ciurl']="https://cloud-images.ubuntu.com/daily/server/${iso['codename']}/current/${iso['inputcibase']}"
          ;;
        *)
          iso['ciurl']="https://cloud-images.ubuntu.com/releases/${iso['release']}/release/${iso['inputcibase']}"
          ;;
      esac
    fi
  fi
}

# Function: get_base_ci
#
# Get base Cloud Image

get_base_ci () {
  handle_output "# Check source Cloud Image exists and grab it if it doesn't" "TEXT"
  iso['inputcibase']=$( basename "${iso['inputci']}" )
  iso['cidir']=$( dirname "${iso['inputci']}" )
  if [ ! -d "${iso['cidir']}" ]; then
    sudo_create_dir "${iso['cidir']}"
    sudo_chown "${iso['cidir']}" "${os['user']}" "${os['group']}"
  fi
  if [ "${options['forceall']}" = "true" ]; then
    handle_output "rm ${iso['workdir']}/files/${iso['inputcibase']}" ""
    if [ "${options['testmode']}" = "false" ]; then
      rm "${iso['workdir']}/files/${iso['inputcibase']}"
    fi
  fi
  check_base_ci_file
  if [ "${options['checkci']}" = "true" ]; then
    cd "${iso['workdir']}/files" || exit ; wget -N "${iso['ciurl']}"
  else
    if ! [ -f "${iso['workdir']}/files/${iso['inputcibase']}" ]; then
      if [ "${options['testmode']}" = "false" ]; then
        wget "${iso['ciurl']}" -O "${iso['workdir']}/files/${iso['inputcibase']}"
      fi
    fi
  fi
}

# Function: check_base_ci_file
#
# Check base Cloud Image file exists

check_base_ci_file () {
  if [ -f "${iso['inputci']}" ]; then
    iso['inputcibase']=$( basename "${iso['inputci']}" )
    file_type=$( file "${iso['workdir']}/files/${iso['inputcibase']}" |cut -f2 -d: |grep -cE "QCOW" )
    if [ "${file_type}" = "0" ]; then
      warning_message "${iso['workdir']}/files/${iso['inputcibase']} is not a valid Cloud Image file"
      exit
    fi
  fi
}
