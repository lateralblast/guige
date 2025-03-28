#!/usr/bin/env bash

# shellcheck disable=SC2034

# Function: install_required_packages
#
# Install required packages
#
# Example:
# sudo apt install -y p7zip-full lftp wget xorriso

install_required_packages () {
  PACKAGE_LIST="$1"
  handle_output "# Checking required packages are installed" "TEXT"
  for PACKAGE in $PACKAGE_LIST; do
    PACKAGE_VERSION=""
    verbose_message "# Package: $PACKAGE" TEXT
    if [ "$OS_NAME" = "Darwin" ]; then
      PACKAGE_VERSION=$( brew info "$PACKAGE" --json |jq -r ".[0].versions.stable" )
    else
      if [[ "$LSB_RELEASE" =~ "Arch" ]] || [[ "$LSB_RELEASE" =~ "Endeavour" ]]; then
        PACKAGE_VERSION=$( sudo pacman -Q "$PACKAGE" 2> /dev/null |awk '{print $2}' )
      else
        PACKAGE_VERSION=$( sudo dpkg -l "$PACKAGE" 2>&1 |grep "^ii" |awk '{print $3}' )
      fi
    fi
    verbose_message "# $PACKAGE version: $PACKAGE_VERSION" TEXT
    if [ -z "$PACKAGE_VERSION" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        verbose_message "# Installing package $PACKAGE"
        if [ "$OS_NAME" = "Darwin" ]; then
          brew update
          brew install "$PACKAGE"
        else
          if [[ "$LSB_RELEASE" =~ "Arch" ]] || [[ "$LSB_RELEASE" =~ "Endeavour" ]]; then
            sudo pacman -Sy
            echo Y |sudo pacman -Sy "$PACKAGE"
          else
            sudo apt update
            sudo apt install -y "$PACKAGE"
          fi
        fi
      fi
    fi
  done
}

# Function: handle_bios
#
# Handle BIOS and EFI options

handle_bios () {
  if [[ "$ISO_BOOT_TYPE" =~ "efi" ]]; then
    ISO_INSTALL_PACKAGES="$ISO_INSTALL_PACKAGES grub-efi"
    ISO_CHROOT_PACKAGES="$ISO_CHROOT_PACKAGES grub-efi"
  fi
  if [[ "$ISO_BOOT_TYPE" =~ "bios" ]]; then
    ISO_INSTALL_PACKAGES="$ISO_INSTALL_PACKAGES grub-pc"
    ISO_CHROOT_PACKAGES="$ISO_CHROOT_PACKAGES grub-pc"
  fi
}

# Function: process_post_install
#
# Process postinstall switch

process_post_install () {
  if [[ "$ISO_POSTINSTALL" =~ "dist" ]]; then
    DO_INSTALL_ISO_NETWORK_UPDATES="true"
    DO_INSTALL_ISO_DIST_UPGRADE="true"
  fi
  if [[ "$ISO_POSTINSTALL" =~ "packages" ]]; then
    DO_INSTALL_ISO_NETWORK_UPDATES="true"
    DO_INSTALL_ISO_PACKAGES="true"
  fi
  if [[ "$ISO_POSTINSTALL" =~ "updates" ]]; then
    DO_INSTALL_ISO_NETWORK_UPDATES="true"
    DO_INSTALL_ISO_UPDATE="true"
    DO_INSTALL_ISO_UPGRADE="true"
  fi
  if [[ "$ISO_POSTINSTALL" =~ "autoupgrades" ]]; then
    DO_ISO_AUTO_UPGRADES="true"
  fi
  if [[ "$ISO_POSTINSTALL" =~ "all" ]]; then
    DO_INSTALL_ISO_NETWORK_UPDATES="true"
    DO_INSTALL_ISO_UPDATE="true"
    DO_INSTALL_ISO_UPGRADE="true"
    DO_INSTALL_ISO_DIST_UPGRADE="true"
    DO_INSTALL_ISO_PACKAGES="true"
  fi
  if [ "$ISO_POSTINSTALL" = "none" ]; then
    DO_INSTALL_ISO_NETWORK_UPDATES="false"
    DO_INSTALL_ISO_UPDATE="false"
    DO_INSTALL_ISO_UPGRADE="false"
    DO_INSTALL_ISO_DIST_UPGRADE="false"
    DO_INSTALL_ISO_PACKAGES="false"
  fi
}
