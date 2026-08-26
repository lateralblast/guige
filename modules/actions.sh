#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: process_actions
#
# Process action switch

process_actions () {
  action_names="${1}"
  if [[ "${action_names}" =~ , ]]; then
    action_names="${action_names//,/ }"
  fi
  for action_name in ${action_names}; do
    case "${action_name}" in
      builddockerconfig)            # action - Build Docker config
        check_docker_config
        do_exit
        ;;
      checkdocker)                  # action - Check Docker
        options['docker']="false"
        options['checkdocker']="true"
        options['checkworkdir']="true"
        ;;
      checkracadm)                  # action - Check racadm
        options['checkracadm']="true"
        ;;
      checkshellcheck|shellcheck)   # action - Shellcheck script
        check_shellcheck
        do_exit
        ;;
      checkworkdir|checkdirs)       # action - Check work directories
        options['checkworkdir']="true"
        ;;
      createansible)                # action - Create ansible
        options['checkworkdir']="true"
        options['createansible']="true"
        ;;
      createautoinstall)            # action - Create autoinstall
        options['createautoinstall']="true"
        ;;
      createcivm)                   # action - Create cloud-init based VM
        iso['type']="kvm"
        options['createcivm']="true"
        ;;
      createdockeriso)              # action - Create ISO using docker
        options['docker']="true"
        options['checkdocker']="true"
        options['checkworkdir']="true"
        options['runchrootscript']="true"
        options['fulliso']="true"
        ;;
      createdockerisoandsquashfs)   # action - Create ISO and update squashfs using docker
        options['updatesquashfs']="true"
        options['docker']="true"
        options['checkdocker']="true"
        options['checkworkdir']="true"
        options['runchrootscript']="true"
        options['fulliso']="true"
        ;;
      createexport)                 # action - Ceate export
        options['checkworkdir']="true"
        options['createexport']="true"
        ;;
      createiso|fulliso)            # action - Create ISO
        options['checkworkdir']="true"
        options['runchrootscript']="true"
        options['fulliso']="true"
        ;;
      createisoandsquashfs)         # action - Create ISO and update squashfs
        options['updatesquashfs']="true"
        options['checkworkdir']="true"
        options['runchrootscript']="true"
        options['fulliso']="true"
        ;;
      createisovm)                  # action - Create ISO based VM
        iso['type']="kvm"
        options['createisovm']="true"
        ;;
      deletecivm|deletevm)          # action - Delete cloud-init based VM
        iso['type']="kvm"
        options['deletevm']="true"
        ;;
      deleteisovm)                  # action - Delete ISO based VM
        iso['type']="kvm"
        options['deletevm']="true"
        ;;
      getiso)                       # action - Get ISO
        options['checkworkdir']="true"
        options['getiso']="true"
        ;;
      help|printhelp)               # action - Print help
        print_help
        ;;
      installreq*|checkreq*)        # action - Install/Check required packages
        options['installrequiredpackages']="true"
        install_required_packages
        do_exit
        ;;
      justiso)                      # action - Just ISO
        options['justiso']="true"
        ;;
      listalliso*|listiso*)         # action - List ISOs
        options['listisos']="true"
        ;;
      listswitches)                 # action - List switches
        get_switches
        list_switches
        ;;
      listvm)                       # action - List VMs
        options['listvms']="true"
        ;;
      oldinstaller)                 # action - Use old installer
        options['oldinstaller']="true"
        ;;
      printdockerconfig)            # action - Print Docker config
        options['printdockerconfig']="true"
        check_docker_config
        do_exit
        ;;
      printdockerenv)               # action - Create ISO using docker
        options['docker']="true"
        options['checkdocker']="true"
        options['checkworkdir']="true"
        options['printdockerenv']="true"
        ;;
      printenv)                     # action - Print environment
        options['printenv']="true"
        ;;
      queryiso)                     # action - Query ISO
        options['query']="true"
        ;;
      runansible)                   # action - Run ansible
        options['checkworkdir']="true"
        options['installrequiredpackages']="true"
        options['createexport']="true"
        options['createansible']="true"
        options['installserver']="true"
        ;;
      runchrootscript)              # action - Run chroot script
        options['runchrootscript']="true"
        ;;
      runracadm|executeracadm)      # action - Run racadm
        options['checkracadm']="true"
        options['executeracadm']="true"
        ;;
      unmount)                      # action - Unmount ISOs etc
        options['unmount']="true"
        ;;
      usage|printusage)             # action - Print usage information
        print_usage
        ;;
      *)
        warning_message "Action \"${iso['action']}\" is not a valid action"
        exit
        ;;
    esac
  done
  case ${iso['delete']} in
    files)
      options['force']="true"
      ;;
    all)
      options['forceall']="true"
      ;;
    *)
      options['force']="false"
      options['forceall']="false"
  esac
}
