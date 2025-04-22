#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: docker_exit
#
# Only exit if inside docker

docker_exit () {
  if [ -f "/.dockerenv" ]; then
    exit
  fi
}

# Function: create_docker_config
#
# Create a docker config so we can run this from a non Linux platform
#
# docker-compose.yml
#
# version: "3"
#
# services:
#  guige:
#    build:
#      context: .
#      dockerfile: Dockerfile
#    image: guige-ubuntu-amd64
#    container_name: guige
#    entrypoint: /bin/bash
#    working_dir: /root
#
# Dockerfile
#
# FROM ubuntu:22.04
# RUN apt-get update && apt-get install -y p7zip-full lftp wget xorriso whois squashfs-tools

check_docker_config () {
  if ! [ -f "/.dockerenv" ]; then
    handle_output "# Checking Docker configs" "TEXT"
    docker_test=$( command -v docker )
    if [ -z "${docker_test}" ]; then
      warning_message "Docker not installed"
      exit
    fi
    for arch_dir in ${iso['dockerarch']}; do
      if ! [ -d "${iso['workdir']}/${arch_dir}" ]; then
        handle_output "Creating directory ${iso['workdir']}/${arch_dir}" "TEXT"
        create_dir "${iso['workdir']}/${arch_dir}"
      fi
      handle_output "# Checking docker images" "TEXT"
      docker_image_check=$( docker images |grep "^${script['name']}-${current['dockerubunturelease']}-${arch_dir}" |awk '{print $1}' )
      handle_output "# Checking volume images" "TEXT"
      docker_volume_check=$( docker volume list |grep "^${script['name']}-${current['dockerubunturelease']}-${arch_dir}" |awk '{print $1}' )
      if ! [ "$docker_volume_check" = "${script['name']}-${current['dockerubunturelease']}-${arch_dir}" ]; then
        if [ "${options['testmode']}" = "false" ]; then
          docker volume create "${script['name']}-${current['dockerubunturelease']}-${arch_dir}"
        fi
      fi
      if ! [ "${docker_image_check}" = "${script['name']}-${current['dockerubunturelease']}-${arch_dir}" ]; then
        if [ "${options['testmode']}" = "false" ]; then
          handle_output "# Creating Docker compose file ${iso['workdir']}/${arch_dir}/docker-compose.yml" "TEXT"
          echo "version: \"3\"" > "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "services:" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "  ${script['name']}-${current['dockerubunturelease']}-${arch_dir}:" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "    build:" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "      context: ." >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "      dockerfile: Dockerfile" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "    image: ${script['name']}-${current['dockerubunturelease']}-${arch_dir}" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "    container_name: ${script['name']}-${current['dockerubunturelease']}-${arch_dir}" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "    entrypoint: /bin/bash" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "    working_dir: /root" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "    platform: linux/${arch_dir}" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "    volumes:" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          echo "      - /docker/${script['name']}-${current['dockerubunturelease']}-${arch_dir}/:/root/${script['name']}/" >> "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          print_file "${iso['workdir']}/${arch_dir}/docker-compose.yml"
          handle_output "# Creating Docker config ${iso['workdir']}/${arch_dir}/Dockerfile" "TEXT"
          echo "FROM ubuntu:${current['dockerubunturelease']}" > "${iso['workdir']}/${arch_dir}/Dockerfile"
          echo "RUN apt-get update && apt-get -o Dpkg::Options::=\"--force-overwrite\" install -y ${iso['requiredpackages']}" >> "${iso['workdir']}/${arch_dir}/Dockerfile"
          print_file "${iso['workdir']}/${arch_dir}/Dockerfile"
          handle_output "# Building docker image ${script['name']}-${current['dockerubunturelease']}-${arch_dir}" "TEXT"
          docker build "${iso['workdir']}/${arch_dir}" --tag "${script['name']}-${current['dockerubunturelease']}-${arch_dir}" --platform "linux/${arch_dir}"
        fi
      fi
    done
  fi
}

# Function: create_docker_iso
#
# Use docker to create ISO

create_docker_iso () {
  if ! [ -f "/.dockerenv" ]; then
    check_workdir
    docker['bin']="${iso['workdir']}/files/${script['bin']}"
    docker['moduledir']="${iso['workdir']}/files/modules"
    if [ ! -d "${docker['moduledir']}" ]; then
      mkdir -p "${docker['moduledir']}"
    fi
    execute_command "cp ${script['modules']}/* ${docker['moduledir']}"
    local_script="${iso['workdir']}/files/guige_docker_script.sh"
    docker['script']="${iso['dockerworkdir']}/files/guige_docker_script.sh"
    execute_command "cp ${script['file']} ${docker['bin']}"
    execute_command "chmod +x ${docker['bin']}"
    if [ "${options['oldinstaller']}" = "true" ]; then
      check_old_workdir
    fi
    check_docker_config
    handle_output "" ""
    if [ "${options['docker']}" = "false" ]; then
      exit
    fi
    if [ ! "${options['testmode']}" = "true" ]; then
      verbose_message "Creating ${local_script}"
      echo "#!/bin/bash" > "${local_script}"
      script_args="--action ${iso['action']} --options ${iso['options']}"
      if [ "${options['autoinstall']}" = "true" ]; then
        if [ -f "${iso['autoinstallfile']}" ]; then
          execute_command "cp ${iso['autoinstallfile']} ${iso['workdir']}/files/user-data"
          iso['autoinstallfile']="${iso['dockerworkdir']}/files/user-data"
          script_args="${script_args} --autoinstallfile ${iso['autoinstallfile']}"
        fi
      fi
      if [ "${options['sshkey']}" = "true" ]; then
        get_ssh_key
        if [ -f "${iso['sshkeyfile']}" ]; then
          execute_command "cp ${iso['sshkeyfile']} ${iso['workdir']}/files/sshkeyfile"
          iso['sshkeyfile']="${iso['dockerworkdir']}/files/sshkeyfile"
          script_args="${script_args} --sshkeyfile ${iso['sshkeyfile']}"
        fi
      fi
      verbose_message "# Checking command line arguements to pass to docker container"
      get_switches
      ignore_switches="outputfile inputfile workdir preworkdir dockerworkdir"
      for arg_name in ${switches[@]}; do
        arg_value="${iso[${arg_name}]}"
        def_value="${defaults[${arg_name}]}"
        if [[ ! "${ignore_switches}" =~ ${arg_name} ]]; then
          verbose_message "# Checking ${arg_name}"
          if [[ ! "${script_args}" =~ "--${arg_name} {arg_value}" ]]; then
            if [ "${arg_value}" != "${def_value}" ] && [ "${arg_value}" != "" ]; then
              script_args="${script_args} --${arg_name} \"${arg_value}\""
              verbose_message "# Adding --${arg_name} \"${arg_value}\""
            fi
          else
            verbose_message "# command line contains --${arg_name} ${arg_value}"
          fi
        fi
      done
      echo "${iso['dockerworkdir']}/files/${script['bin']} ${script_args} --workdir ${iso['dockerworkdir']} --preworkdir ${iso['workdir']}" >> "${local_script}"
      print_file "${local_script}"
      execute_command "chmod +x ${local_script}"
      if [ "${options['docker']}" = "true" ]; then
        docker['outputfilebase']=$( basename "${iso['outputfile']}" )
        echo "# Output file will be at \"${iso['workdir']}/files/${docker['outputfilebase']}\""
      fi
      verbose_message "# Executing: exec docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule=\"b 7:* rmw\" --platform \"linux/${iso['arch']}\" --mount source=\"${script['name']}-${current['dockerubunturelease']}-${iso['arch']},target=/root/${script['name']}\" --mount type=bind,source=\"${iso['workdir']}/files,target=/root/${script['name']}/${iso['osname']}/${iso['build']}/${iso['release']}/files\"  \"${script['name']}-${current['dockerubunturelease']}-${iso['arch']}\" /bin/bash \"${docker['script']}\""
      exec docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule="b 7:* rmw" --platform "linux/${iso['arch']}" --mount source="${script['name']}-${current['dockerubunturelease']}-${iso['arch']},target=/root/${script['name']}" --mount type=bind,source="${iso['workdir']}/files,target=/root/${script['name']}/${iso['osname']}/${iso['build']}/${iso['release']}/files"  "${script['name']}-${current['dockerubunturelease']}-${iso['arch']}" /bin/bash "${docker['script']}"
      exit
    fi
  fi
  options['help']="false"
}
