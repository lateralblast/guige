#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: print_env
#
# Print environment

print_env () {
  handle_output "# Setting Variables" TEXT
  handle_output "# OS name:                   [iso['osname']}]                     ${iso['osname']}"          "TEXT"
  handle_output "# Codename:                  [iso['codename']}]                   ${iso['codename']}"        "TEXT"
  handle_output "# Architecture:              [iso['arch']}]                       ${iso['arch']}"            "TEXT"
  handle_output "# Work directory:            [iso['workdir']}]                    ${iso['workdir']}"         "TEXT"
  if [ "${options['docker']}" = "true" ]; then
    handle_output "# Previous Work directory:   [iso['workdir']}]                    ${iso['workdir']}"       "TEXT"
  fi
  if [ "${options['oldinstaller']}" = "true" ]; then
    handle_output "# Old Work directory:        [old['workdir']}]                ${old['workdir']}"           "TEXT"
    handle_output "# Old ISO input file:        [old['inputfile']}]              ${old['inputfile']}"         "TEXT"
    handle_output "# Old ISO URL:               [old['url']}]                    ${old['url']}"               "TEXT"
  fi
  handle_output "# ISO URL:                   [iso['url']}]                        ${iso['url']}"                                           "TEXT"
  handle_output "# Cloud Image URL:           [iso['ciurl']}]                      ${iso['ciurl']}"                                         "TEXT"
  handle_output "# ISO input file:            [iso['inputfile']}]                  ${iso['inputfile']}"                                     "TEXT"
  handle_output "# Cloud Image input file:    [iso['inputci']}]                    ${iso['inputci']}"                                       "TEXT"
  handle_output "# Required packages:         [iso['requiredpackages']}]           ${iso['requiredpackages']}"                              "TEXT"
  handle_output "# ISO output file:           [iso['outputfile']}]                 ${iso['outputfile']}"                                    "TEXT"
  handle_output "# Cloud Image output file:   [iso['outputci']}]                   ${iso['outputci']}"                                      "TEXT"
  handle_output "# SCP command:               [iso['scpcommand']}]                 ${iso['bmcusername']}@${os['ip']}:${iso['outputfile']}"  "TEXT"
  handle_output "# ISO Release:               [iso['release']}]                    ${iso['release']}"                                       "TEXT"
  handle_output "# ISO Release (Major):       [iso['majorrelease']}]               ${iso['majorrelease']}"                                  "TEXT"
  handle_output "# ISO Release (Minor):       [iso['minorrelease']}]               ${iso['minorrelease']}"                                  "TEXT"
  handle_output "# ISO Build:                 [iso['build']}]                      ${iso['build']}"                                         "TEXT"
  handle_output "# ISO Volume ID:             [iso['volid']}]                      ${iso['volid']}"                                         "TEXT"
  handle_output "# ISO mount directory:       [iso['mountdir']}]                   ${iso['mountdir']}"                                      "TEXT"
  if [ "${options['oldinstaller']}" = "true" ]; then
    handle_output "# Old ISO mount directory:   [old['mountdir']}]               ${old['mountdir']}"           "TEXT"
    handle_output "# Old install squashfs file: [old['installsquashfile']}]      ${old['installsquashfile']}"  "TEXT"
  fi
  handle_output "# ISO squashfs file:         [iso['squashfsfile']}]               ${iso['squashfsfile']}"     "TEXT"
  handle_output "# Check latest ISO:          [options['latest']}]                 ${options['latest']}"       "TEXT"
  handle_output "# Hostname:                  [iso['hostname']}]                   ${iso['hostname']}"         "TEXT"
  handle_output "# Username:                  [iso['username']}]                   ${iso['username']}"         "TEXT"
  handle_output "# Realname:                  [iso['realname']}]                   ${iso['realname']}"         "TEXT"
  handle_output "# Password:                  [iso['password']}]                   ${iso['password']}"         "TEXT"
  handle_output "# Password Hash:             [iso['passwordcrypt']}]              ${iso['passwordcrypt']}"    "TEXT"
  if [ "${options['sshkey']}" =  "true" ]; then
    handle_output "# SSH Key file:              [iso['sshkeyfile']}]                 ${iso['sshkeyfile']}"     "TEXT"
    handle_output "# SSH Key:                   [iso['sshkey']}]                     ${iso['sshkey']}"         "TEXT"
  fi
  handle_output "# Timezone:                  [iso['timezone']}]                   ${iso['timezone']}"         "TEXT"
  if [ -n "${iso['sshkeyfile']}" ]; then
    handle_output "# SSH Key file:              [iso['sshkeyfile']}]                 ${iso['sshkeyfile']}"     "TEXT"
  fi
  handle_output "# NIC:                       [iso['nic']}]                        ${iso['nic']}"              "TEXT"
  handle_output "# DHCP:                      [options['dhcp']}]                   ${options['dhcp']}"         "TEXT"
  if [ "${options['dhcp']}" = "false" ]; then
    handle_output "# IP:                        [iso['ip']}]                         ${iso['ip']}"             "TEXT"
    handle_output "# CIDR:                      [iso['cidr']}]                       ${iso['cidr']}"           "TEXT"
    handle_output "# Netmask:                   [iso['netmask']}]                    ${iso['netmask']}"        "TEXT"
    handle_output "# Gateway:                   [iso['gateway']}]                    ${iso['gateway']}"        "TEXT"
    handle_output "# Nameservers:               [iso['dns']}]                        ${iso['dns']}"            "TEXT"
  fi
  handle_output "# Kernel:                    [iso['kernel']}]                     ${iso['kernel']}"                     "TEXT"
  handle_output "# Kernel arguments:          [iso['kernelargs']}]                 ${iso['kernelargs']}"                 "TEXT"
  handle_output "# Kernel serial arguments:   [iso['kernelserialargs']}]           ${iso['kernelserialargs']}"           "TEXT"
  handle_output "# Block kernel modules:      [iso['blocklist']}]                  ${iso['blocklist']}"                  "TEXT"
  handle_output "# Allow kernel modules:      [iso['allowlist']}]                  ${iso['allowlist']}"                  "TEXT"
  handle_output "# Allow password login:      [iso['allowpassword']}]              ${iso['allowpassword']}"              "TEXT"
  handle_output "# Keyboard Layout:           [iso['Layout']}]                     ${iso['layout']}"                     "TEXT"
  handle_output "# Locale:                    [iso['locale']}]                     ${iso['locale']}"                     "TEXT"
  handle_output "# LC_ALL:                    [iso['lcall']}]                      ${iso['lcall']}"                      "TEXT"
  handle_output "# Root disk(s):              [iso['disk']}]                       ${iso['disk']}"                       "TEXT"
  handle_output "# Volme Manager(s):          [iso['volumemanager']}]              ${iso['volumemanager']}"              "TEXT"
  handle_output "# GRUB Menu:                 [iso['grubmenu']}]                   ${iso['grubmenu']}"                   "TEXT"
  handle_output "# GRUB Timeout:              [iso['grubtimeout']}]                ${iso['grubtimeout']}"                "TEXT"
  handle_output "# AI Directory:              [iso['autoinstalldir']}]             ${iso['autoinstalldir']}"             "TEXT"
  handle_output "# Install mount:             [iso['installmount']}]               ${iso['installmount']}"               "TEXT"
  handle_output "# Install target:            [iso['targetmount']}]                ${iso['targetmount']}"                "TEXT"
  handle_output "# Recreate squashfs:         [options['updatesquashfs']}]         ${options['updatesquashfs']}"         "TEXT"
  handle_output "# Run chroot script:         [options['chroot']}]                 ${options['chroot']}"                 "TEXT"
  handle_output "# Squashfs packages:         [iso['chrootpackages']}]             ${iso['chrootpackages']}"             "TEXT"
  handle_output "# Additional packages:       [iso['packages']}]                   ${iso['packages']}"                   "TEXT"
  handle_output "# Network updates:           [options['networkupdates']}]         ${options['networkupdates']}"         "TEXT"
  handle_output "# Install packages:          [options['installpackages']}]        ${options['installpackages']}"        "TEXT"
  handle_output "# Install updates:           [options['packageupdates']}]         ${options['packageupdates']}"         "TEXT"
  handle_output "# Install upgrades:          [options['packageupgrades']}]        ${options['packageupgrades']}"        "TEXT"
  handle_output "# Dist upgrades:             [options['distupgrade']}]            ${options['distupgrade']}"            "TEXT"
  handle_output "# Swap size:                 [iso['swap']}]                       ${iso['swap']}"                       "TEXT"
  handle_output "# VM Memory size:            [iso['ram']}]                        ${iso['ram']}"                        "TEXT"
  if [ "${options['createexport']}" = "true" ] || [ "${options['createansible']}" = "true" ]; then
    handle_output "# Bootserver IP:             [iso['bootserverip']}]               ${iso['bootserverip']}"             "TEXT"
    handle_output "# Bootserver file:           [iso['bootserverfile']}]             ${iso['bootserverfile']}"           "TEXT"
  fi
  if [ "${options['createansible']}" = "true" ] ; then
    handle_output "# BMC IP:                    [iso['bmcip']}]                      ${iso['bmcip']}"                    "TEXT"
    handle_output "# BMC Username:              [iso['bmcusername']}]                ${iso['bmcusername']}"              "TEXT"
    handle_output "# BMC Password:              [iso['bmcpassword']}]                ${iso['bmcpassword']}"              "TEXT"
  fi
  if [ "${iso['osname']}" = "rocky" ]; then
    handle_output "# Install Mode:              [iso['installmode']}]                ${iso['installmode']}"              "TEXT"
    handle_output "# Install Source:            [iso['installsource']}]              ${iso['installsource']}"            "TEXT"
    handle_output "# Install Username:          [iso['installusername']}]            ${iso['installusername']}"          "TEXT"
    handle_output "# Install Password:          [iso['installpassword']}]            ${iso['installpassword']}"          "TEXT"
    handle_output "# Install Password Crypt:    [iso['installpasswordcrypt']}]       ${iso['installpasswordcrypt']}"     "TEXT"
    handle_output "# Password Algorithm:        [iso['passwordalgorithm']}]          ${iso['passwordalgorithm']}"        "TEXT"
    handle_output "# Bootloader Location:       [iso['bootloader']}]                 ${iso['bootloader']}"               "TEXT"
    handle_output "# SELinux Mode:              [iso['selinux']}]                    ${iso['selinux']}"                  "TEXT"
    handle_output "# Firewall:                  [iso['firewall']}]                   ${iso['firewall']}"                 "TEXT"
    handle_output "# Allow Services:            [iso['allowservice']}]               ${iso['allowservice']}"             "TEXT"
    handle_output "# Enable Network on boot:    [iso['onboot']}]                     ${iso['onboot']}"                   "TEXT"
    handle_output "# Network Boot Procol:       [iso['bootproto']}]                  ${iso['bootproto']}"                "TEXT"
    handle_output "# Enable Services:           [iso['enableservice']}]              ${iso['enableservice']}"            "TEXT"
    handle_output "# Disable Services:          [iso['disableservice']}]             ${iso['disableservice']}"           "TEXT"
    handle_output "# User GECOS field:          [iso['gecos']}]                      ${iso['gecos']}"                    "TEXT"
    handle_output "# User Groups:               [iso['groups']}]                     ${iso['groups']}"                   "TEXT"
    handle_output "# Boot Partition Size:       [iso['bootsize']}]                   ${iso['bootsize']}"                 "TEXT"
    handle_output "# PE Size:                   [iso['pesize']}]                     ${iso['pesize']}"                   "TEXT"
    handle_output "# Volume Group Name:         [iso['vgname']}]                     ${iso['vgname']}"                   "TEXT"
    handle_output "# Install SSH User:          [iso['sshuser']}]                    ${iso['sshuser']}"                  "TEXT"
    handle_output "# Install SSH Password:      [iso['sshpassword']}]                ${iso['sshpassword']}"              "TEXT"
    handle_output "# Do setup on first boot:    [options['firstboot']}]              ${options['firstboot']}"            "TEXT"
  else
    handle_output "# Fallback:                  [iso['fallback']}]                   ${iso['fallback']}"                 "TEXT"
  fi
  handle_output "# Serial Port:               [iso['serialporta']}]                ${iso['serialporta']}"                "TEXT"
  handle_output "# Serial Port:               [iso['serialportb']}]                ${iso['serialportb']}"                "TEXT"
  handle_output "# Serial Port Address:       [iso['serialportaddressa']}]         ${iso['serialportaddressa']}"         "TEXT"
  handle_output "# Serial Port Address:       [iso['serialportaddressb']}]         ${iso['serialportaddressb']}"         "TEXT"
  handle_output "# Serial Port Speed:         [iso['serialportspeeda']}]           ${iso['serialportspeeda']}"           "TEXT"
  handle_output "# Serial Port Speed:         [iso['serialportspeedb']}]           ${iso['serialportspeedb']}"           "TEXT"
  handle_output "# Use biosdevnames:          [options['biosdevname']}]            ${options['biosdevname']}"            "TEXT"
  handle_output "# OEM Install:               [iso['oeminstall']}]                 ${iso['oeminstall']}"                 "TEXT"
  handle_output "# Source ID:                 [iso['sourceid']}]                   ${iso['sourceid']}"                   "TEXT"
  handle_output "# Search Drivers:            [options['searchdrivers']}]          ${options['searchdrivers']}"          "TEXT"
  handle_output "# Preserve Sources:          [options['preservesources']}]        ${options['preservesources']}"        "TEXT"
  if [ "${options['autoinstall']}" = "true" ]; then
    handle_output "# Custom user-data:          [iso['autoinstallfile']}]            ${iso['autoinstallfile']}"          "TEXT"
  fi
  if [ "${options['printenv']}" = "true" ] || [ "${options['interactivemode']}" = "true" ]; then
    temp['verbose']="false"
  fi
  if [ "${options['printenv']}" = "true" ]; then
    exit
  fi
}
