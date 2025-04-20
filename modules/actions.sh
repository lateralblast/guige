#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: process_actions
#
# Process action switch

process_actions () {
  if [ "${iso['action']}" = "" ]; then
    warning_message "No action specified"
    exit
  fi
  if [[ "${iso['action']}" =~ , ]]; then
    actions=$( echo "${iso['action']}" | sed "s/,/ /g" )
  else
    actions="${iso['action']}"
  fi
  for action in ${actions}; do
    case "${action}" in
      checkdocker)
        options['docker']="false"
        options['checkdocker']="true"
        options['checkworkdir']="true"
        ;;
      checkracadm)
        options['checkracadm']="true"
        ;;
      checkshellcheck|shellcheck)
        check_shellcheck
        exit
        ;;
      checkworkdir|checkdirs)
        options['checkworkdir']="true"
        ;;
      createansible)
        options['checkworkdir']="true"
        options['installrequiredpackages']="true"
        options['createansible']="true"
        ;;
      createautoinstall)
        options['createautoinstall']="true"
        ;;
      createcivm)
       iso['type']="kvm"
        options['installrequiredpackages']="true"
        options['createcivm']="true"
        ;;
      createdockeriso)
        options['docker']="true"
        options['checkdocker']="true"
        options['checkworkdir']="true"
        options['installrequiredpackages']="true"
        options['runchrootscript']="true"
        options['fulliso']="true"
       ;;
      createdockerisoandsquashfs)
        options['updatesquashfs']="true"
        options['docker']="true"
        options['checkdocker']="true"
        options['checkworkdir']="true"
        options['installrequiredpackages']="true"
        options['runchrootscript']="true"
        options['fulliso']="true"
        ;;
      createexport)
        options['checkworkdir']="true"
        options['installrequiredpackages']="true"
        options['createexport']="true"
        ;;
      createiso|fulliso)
        options['checkworkdir']="true"
        options['installrequiredpackages']="true"
        options['runchrootscript']="true"
        options['fulliso']="true"
        ;;
      createisoandsquashfs)
        options['updatesquashfs']="true"
        options['checkworkdir']="true"
        options['installrequiredpackages']="true"
        options['runchrootscript']="true"
        options['fulliso']="true"
       ;;
      createisovm)
        iso['type']="kvm"
        options['installrequiredpackages']="true"
        options['createisovm']="true"
        ;;
      deletecivm)
        iso['type']="kvm"
        options['installrequiredpackages']="true"
        options['deletecivm']="true"
        ;;
      deleteisovm)
        iso['type']="kvm"
        options['installrequiredpackages']="true"
        options['deleteisovm']="true"
        ;;
      getiso)
        options['checkworkdir']="true"
        options['getiso']="true"
        ;;
      help|printhelp)
        print_help
        ;;
      installrequired*|checkrequired*)
        options['installrequiredpackages']="true"
        ;;
      justiso)
        options['justiso']="true"
        ;;
      listalliso|listallisos|listiso|listisos)
        options['listisos']="true"
        ;;
      listswitches)
        get_switches
        list_switches
        ;;
      listvm)
        options['listvms']="true"
        ;;
      oldinstaller)
        options['oldinstaller']="true"
        ;;
      printenv)
        options['printenv']="true"
        ;;
      queryiso)
        options['query']="true"
        ;;
      runansible)
        options['checkworkdir']="true"
        options['installrequiredpackages']="true"
        options['createexport']="true"
        options['createansible']="true"
        options['installserver']="true"
        ;;
      runchrootscript|execchrootscript|executechrootscript)
        options['runchrootscript']="true"
        ;;
      runracadm|execracadm|exectureracadm)
        options['checkracadm']="true"
        options['executeracadm']="true"
        ;;
      unmount)
        options['unmount']="true"
        ;;
      usage|printusage)
        print_usage
        ;;
      test)
        options['testmode']="true"
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
