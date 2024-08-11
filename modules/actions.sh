#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: process_actions
#
# Process action switch

process_actions () {
  if [ "$ACTION" = "" ]; then
    warning_message "No action specified" "warn"
    exit
  fi
  case $ACTION in
    help|printhelp)
      print_help
      ;;
    usage|printusage)
      print_usage
      ;;
    checkracadm)
      DO_CHECK_RACADM="true"
      ;;
    runracadm)
      DO_CHECK_RACADM="true"
      DO_EXECUTE_RACADM="true"
      ;;
    listvm)
      DO_LIST_VM="true"
      ;;
    createexport)
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_CREATE_EXPORT="true"
      ;;
    createansible)
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_CREATE_ANSIBLE="true"
      ;;
    runansible)
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_CREATE_EXPORT="true"
      DO_CREATE_ANSIBLE="true"
      DO_INSTALL_SERVER="true"
      ;;
    printenv)
      DO_PRINT_ENV="true"
      ;;
    checkdocker)
      DO_DOCKER="false"
      DO_CHECK_DOCKER="true"
      DO_CHECK_WORK_DIR="true"
      ;;
    getiso)
      DO_CHECK_WORK_DIR="true"
      DO_GET_BASE_ISO="true"
      ;;
    installrequired|checkrequired)
      DO_INSTALL_REQUIRED_PACKAGES="true"
      ;;
    checkdirs)
      DO_CHECK_WORK_DIR="true"
      ;;
    justiso)
      DO_CREATE_AUTOINSTALL_ISO_ONLY="true"
      ;;
    createautoinstall)
      DO_PREPARE_AUTOINSTALL_ISO_ONLY="true"
      ;;
    runchrootscript)
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      ;;
    createiso)
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      DO_CREATE_AUTOINSTALL_ISO_FULL="true"
      ;;
    createisoandsquashfs)
      DO_ISO_SQUASHFS_UPDATE="true"
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      DO_CREATE_AUTOINSTALL_ISO_FULL="true"
     ;;
    createdockeriso)
      DO_DOCKER="true"
      DO_CHECK_DOCKER="true"
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      DO_CREATE_AUTOINSTALL_ISO_FULL="true"
      ;;
    createdockerisoandsquashfs)
      DO_ISO_SQUASHFS_UPDATE="true"
      DO_DOCKER="true"
      DO_CHECK_DOCKER="true"
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      DO_CREATE_AUTOINSTALL_ISO_FULL="true"
      ;;
    createkvm)
      VM_TYPE="kvm"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_CREATE_VM="true"
      ;;
    deletekvm)
      VM_TYPE="kvm"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_DELETE_VM="true"
      ;;
    createvm)
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_CREATE_VM="true"
      ;;
    deletevm)
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_DELETE_VM="true"
      ;;
    queryiso)
      DO_ISO_QUERY="true"
      ;;
    unmount)
      DO_UMOUNT_ISO="true"
      ;;
    oldinstaller)
      DO_OLD_INSTALLER="true"
      ;;
    listalliso|listallisos|listiso|listisos)
      DO_LIST_ISOS="true"
      ;;
    test)
      DO_TEST="true"
      ;;
    *)
      handle_output "Action: $ACTION is not a valid action" ""
      exit
      ;;
  esac
  case $DELETE in
    files)
      FORCE_MODE="true"
      ;;
    all)
      FULL_FORCE_MODE="true"
      ;;
    *)
      FORCE_MODE="false"
      FULL_FORCE_MODE="false"
  esac
}
