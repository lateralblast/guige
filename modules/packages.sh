#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2154

# Function: install_package
#
# Install Package

install_package () {
  package="$1"
  package_version=""
  verbose_message "# package: ${package}" TEXT
  if [ "${os['name']}" = "Darwin" ]; then
    package_version=$( brew info "${package}" --json |jq -r ".[0].versions.stable" )
  else
    if [[ "${iso['release']}" =~ "Arch" ]] || [[ "${iso['release']}" =~ "Endeavour" ]]; then
      package_version=$( sudo pacman -Q "${package}" 2> /dev/null |awk '{print $2}' )
    else
      package_version=$( sudo dpkg -l "${package}" 2>&1 |grep "^ii" |awk '{print $3}' )
    fi
  fi
  verbose_message "# ${package} version: ${package_version}" "TEXT"
  if [ -z "${package_version}" ]; then
    if [ "${options['testmode']}" = "false" ]; then
      verbose_message "# Installing package ${package}"
      if [ "${os['name']}" = "Darwin" ]; then
        brew update
        brew install "${package}"
      else
        if [[ "${iso['release']}" =~ "Arch" ]] || [[ "${iso['release']}" =~ "Endeavour" ]]; then
          sudo pacman -Sy
          echo Y |sudo pacman -Sy "${package}"
        else
          sudo apt update
          sudo apt install -y "${package}"
        fi
      fi
    fi
  fi
}

# Function: install_required_packages
#
# Install required packages
#
# Example:
# sudo apt install -y p7zip-full lftp wget xorriso

install_required_packages () {
  package_list="$1"
  handle_output "# Checking required packages are installed" "TEXT"
  for package in ${package_list}; do
    install_package "${package}"    
  done
}

# Function: handle_bios
#
# Handle BIOS and EFI options

handle_bios () {
  if [[ "${iso['boottype']}" =~ "efi" ]]; then
    iso['packages']="${iso['packages']} grub-efi"
    iso['chrootpackages']="${iso['chrootpackages']} grub-efi"
  fi
  if [[ "${iso['boottype']}" =~ "bios" ]]; then
    iso['packages']="${iso['packages']} grub-pc"
    iso['chrootpackages']="${iso['chrootpackages']} grub-pc"
  fi
}

# Function: process_post_install
#
# Process postinstall switch

process_post_install () {
  if [[ "${iso['postinstall']}" =~ "dist" ]]; then
    options['networkupdates']="true"
    options['distupgrade']="true"
  fi
  if [[ "${iso['postinstall']}" =~ "packages" ]]; then
    options['networkupdates']="true"
    options['installpackages']="true"
  fi
  if [[ "${iso['postinstall']}" =~ "updates" ]]; then
    options['networkupdates']="true"
    options['packageupdates']="true"
    options['packageupgrades']="true"
  fi
  if [[ "${iso['postinstall']}" =~ "autoupgrades" ]]; then
    options['autoupgrade']="true"
  fi
  if [[ "${iso['postinstall']}" =~ "all" ]]; then
    options['networkupdates']="true"
    options['packageupdates']="true"
    options['packageupgrades']="true"
    options['distupgrade']="true"
    options['installpackages']="true"
  fi
  if [ "${iso['postinstall']}" = "none" ]; then
    options['networkupdates']="false"
    options['packageupdates']="false"
    options['packageupgrades']="false"
    options['distupgrade']="false"
    options['installpackages']="false"
  fi
}
