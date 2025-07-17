#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154
# shellcheck disable=SC2317

# Function: print_cli_help
#
# Print script help information

print_cli_help () {
  echo ""
  echo "Usage: ${script['name']} --action [action] --options [options]"
  echo ""
  switchstart="false"
  while read -r line; do
    if [[ "${line}" =~ -- ]] && [[ ! "${line}" =~ regex ]]; then
      switchstart="true"
    fi
    if [[ "${line}" =~ esac ]] || [[ "${line}" =~ \* ]]; then
      switchstart="false"
    fi
    if [ "${switchstart}" = "true" ]; then
      if [[ "${line}" =~ -- ]] && [[ "${line}" =~ [a-z] ]]; then
        if [[ "${line}" =~ \| ]]; then
          switch_name=$( echo "${line}" |cut -f1 -d "|" )
        else
          switch_name=$( echo "${line}" |cut -f1 -d ")" )
        fi
        switch_name="${switch_name//--/}"
        switch_name="${switch_name// /}"
        switch_default="${defaults[$switch_name]}"
      fi
      if [[ "${line}" =~ \# ]]; then
        if [[ "${switch_name}" =~ [a-z] ]]; then
          switch_length="${#switch_name}"
          if [ "${switch_length}" -lt 6 ]; then
            tab_space="\t\t\t"
          else
            if [ "${switch_length}" -lt 14 ]; then
              tab_space="\t\t"
            else
              tab_space="\t"
            fi
          fi
          switch_comment=$( echo "${line}" |cut -f2 -d"#" )
          if [ ! "${switch_default}" = "" ]; then
            echo -e  "--${switch_name}${tab_space}${switch_comment} (default: ${switch_default})"
          else
            echo -e "--${switch_name}${tab_space}${switch_comment}"
          fi
        fi
      fi
    fi
  done < "${script['file']}"
  exit
}

# Function: print_help
#
# Print help

print_help () {
  case "$1" in
    cli)
      print_cli_help
      ;;
    action*)
      print_info "action"
      exit
      ;;
    option*)
      print_info "option"
      exit
      ;;
    postinstall)
      print_postinstall
      exit
      ;;
    examples)
      print_examples
      exit
      ;;
    *)
      print_cli_help
      exit
      ;;
  esac
}
