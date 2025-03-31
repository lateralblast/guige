#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

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
    for DIR_ARCH in $DOCKER_ARCH; do
      if ! [ -d "$ISO_WORKDIR/$DIR_ARCH" ]; then
        handle_output "Creating directory $ISO_WORKDIR/$DIR_ARCH" "TEXT"
        create_dir "$ISO_WORKDIR/$DIR_ARCH"
      fi
      handle_output "# Checking docker images" "TEXT"
      DOCKER_IMAGE_CHECK=$( docker images |grep "^$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" |awk '{print $1}' )
      handle_output "# Checking volume images" "TEXT"
      DOCKER_VOLUME_CHECK=$( docker volume list |grep "^$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" |awk '{print $1}' )
      if ! [ "$DOCKER_VOLUME_CHECK" = "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" ]; then
        if [ "$DO_ISO_TESTMODE" = "false" ]; then
          docker volume create "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH"
        fi
      fi
      if ! [ "$DOCKER_IMAGE_CHECK" = "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" ]; then
        if [ "$DO_ISO_TESTMODE" = "false" ]; then
          handle_output "# Creating Docker compose file $ISO_WORKDIR/$DIR_ARCH/docker-compose.yml" "TEXT"
          echo "version: \"3\"" > "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "services:" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "  $SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH:" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "    build:" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "      context: ." >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "      dockerfile: Dockerfile" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "    image: $SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "    container_name: $SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "    entrypoint: /bin/bash" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "    working_dir: /root" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "    platform: linux/$DIR_ARCH" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "    volumes:" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          echo "      - /docker/$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH/:/root/$SCRIPT_NAME/" >> "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          print_file "$ISO_WORKDIR/$DIR_ARCH/docker-compose.yml"
          handle_output "# Creating Docker config $ISO_WORKDIR/$DIR_ARCH/Dockerfile" "TEXT"
          echo "FROM ubuntu:$CURRENT_DOCKER_UBUNTU_RELEASE" > "$ISO_WORKDIR/$DIR_ARCH/Dockerfile"
          echo "RUN apt-get update && apt-get -o Dpkg::Options::=\"--force-overwrite\" install -y $REQUIRED_PACKAGES" >> "$ISO_WORKDIR/$DIR_ARCH/Dockerfile"
          print_file "$ISO_WORKDIR/$DIR_ARCH/Dockerfile"
          handle_output "# Building docker image $SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" "TEXT"
          docker build "$ISO_WORKDIR/$DIR_ARCH" --tag "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" --platform "linux/$DIR_ARCH"
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
    check_ISO_WORKDIR
    DOCKER_BIN="$ISO_WORKDIR/files/$SCRIPT_BIN"
    DOCKER_MODULE_DIR="$ISO_WORKDIR/files/modules"
    if [ ! -d "$DOCKER_MODULE_DIR" ]; then
      mkdir -p "$DOCKER_MODULE_DIR"
    fi
    cp "$MODULE_PATH"/* "$DOCKER_MODULE_DIR"
    LOCAL_SCRIPT="$ISO_WORKDIR/files/guige_docker_script.sh"
    DOCKER_SCRIPT="$DOCKER_ISO_WORKDIR/files/guige_docker_script.sh"
    cp "$SCRIPT_FILE" "$DOCKER_BIN"
    chmod +x "$DOCKER_BIN"
    if [ "$DO_ISO_OLDINSTALLER" = "true" ]; then
      check_old_ISO_WORKDIR
    fi
    check_docker_config
    handle_output "" ""
    if [ "$DO_ISO_DOCKER" = "false" ]; then
      exit
    fi
    if ! [ "$DO_ISO_TESTMODE" = "true" ]; then
      echo "#!/bin/bash" > "$LOCAL_SCRIPT"
      echo "$DOCKER_ISO_WORKDIR/files/$SCRIPT_BIN $SCRIPT_ARGS --workdir $DOCKER_ISO_WORKDIR --preworkdir $ISO_WORKDIR" >> "$LOCAL_SCRIPT"
      if [ "$DO_ISO_DOCKER" = "true" ]; then
        BASE_DOCKER_ISO_OUTPUTFILE=$( basename "$ISO_OUTPUTFILE" )
        echo "# Output file will be at \"$ISO_WORKDIR/files/$BASE_DOCKER_ISO_OUTPUTFILE\""
      fi
      verbose_message "# Executing: exec docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule=\"b 7:* rmw\" --platform \"linux/$ISO_ARCH\" --mount source=\"$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$ISO_ARCH,target=/root/$SCRIPT_NAME\" --mount type=bind,source=\"$ISO_WORKDIR/files,target=/root/$SCRIPT_NAME/$NEW_DIR/files\"  \"$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$ISO_ARCH\" /bin/bash \"$DOCKER_SCRIPT\""
      exec docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule="b 7:* rmw" --platform "linux/$ISO_ARCH" --mount source="$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$ISO_ARCH,target=/root/$SCRIPT_NAME" --mount type=bind,source="$ISO_WORKDIR/files,target=/root/$SCRIPT_NAME/$NEW_DIR/files"  "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$ISO_ARCH" /bin/bash "$DOCKER_SCRIPT"
      exit
    fi
  fi
  DO_PRINT_HELP="false"
}
