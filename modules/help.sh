#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: print_cli_help
#
# Print script help information

print_cli_help () {
  echo ""
  echo "Usage: ${script['name']} --action [action] --options [options]"
  echo ""
  switchstart="false"
  while read line; do
    if [[ "${line}" =~ switchstart ]]; then
      switchstart="true"
    fi
    if [[ "${line}" =~ switchend ]] || [[ "${line}" =~ \* ]]; then
      switchstart="false"
    fi
    if [ "${switchstart}" = "true" ]; then
      if [[ "${line}" =~ -- ]] && [[ "${line}" =~ [a-z] ]]; then
        if [[ "${line}" =~ \| ]]; then
          switch_name=$( echo "${line}" |cut -f1 -d "|" )
        else
          switch_name=$( echo "${line}" |cut -f1 -d ")" )
        fi
        switch_name=$( echo "${switch_name}" |sed "s/\-\-//g" )
        switch_name=$( echo "${switch_name}" |sed "s/ //g" )
        switch_default=$( echo ${defaults[$switch_name]} )
      fi
      if [[ "${line}" =~ \# ]] && [[ ! "${line}" =~ switchstart ]]; then
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
    "cli")
      print_cli_help
      ;;
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
      print_cli_help
      exit
      ;;
  esac
}
