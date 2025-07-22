#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: print_info
#
# Print information

print_info () {
  info="$1"
  echo ""
  if [ "${info}" = "action" ]; then
    echo "Usage: ${script['bin']} --${info} [${info}]"
  else
    echo "Usage: ${script['bin']} --action [action] --${info} [${info}]"
  fi
  echo ""
  echo "${info}(s):"
  echo "---------"
  module_file="${script['dir']}/modules/${info}s.sh"
  if [ -f "${module_file}" ]; then
    while read -r line; do
      if [[ "${line}" =~ .*"# ${info}".* ]]; then
        if [[ "${info}" =~ option ]]; then
          IFS='-' read -r param desc <<< "${line}"
          IFS=']' read -r param default <<< "${param}"
          IFS='[' read -r _ param <<< "${param}"
          param="${param//\'/}"
          IFS='=' read -r _ default <<< "${default}"
          default="${default//\'/}"
          default="${default//\"/}"
          default="${default// /}"
          default="${default/\#${info}/}"
          param="${param} (default = ${default})"
        else
          IFS='#' read -r param desc <<< "${line}"
          desc="${desc/${info} -/}"
        fi
        echo "${param}"
        echo "  ${desc}"
      fi
    done < "${module_file}"
    echo ""
  fi
}

# Function: print_usage
#
# Print script usage information

print_actions () {
  print_info "action"
}

print_options () {
  print_info "option"
}

print_postinstall () {
  cat <<-postinstall_usage

postinstall
-----------

distupgrade:            Do distribution upgrade as part of install process
packages:               Install packages as part of install process
updates:                Do updates as part of install process
upgrades:               Do upgrades as part of install process
all:                    Do all updates as part of install process
postinstall_usage
}

print_examples () {
  cat <<-examples

Examples
--------

Create an ISO with a static IP configuration:

${0##*/} --action createiso --options verbose --ip 192.168.1.211 --cidr 24 --dns 8.8.8.8 --gateway 192.168.1.254
examples
}


# Function: print_all_usage
#
# Print script usage information

print_all_usage () {
  print_actions
  print_options
  print_postinstall
  print_examples
}

# Function: print_usage
#
# Print script usage information

print_usage () {
  case "$1" in
    "actions")
      print_actions
      exit
      ;;
    "options")
      print_options
      exit
      ;;
    "postinstall")
      print_postinstall
      exit
      ;;
    "examples")
      print_examples
      exit
      ;;
    *)
      print_all_usage
      exit
      ;;
  esac
}
