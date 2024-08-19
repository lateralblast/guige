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
      if ! [ -d "$WORK_DIR/$DIR_ARCH" ]; then
        handle_output "Creating directory $WORK_DIR/$DIR_ARCH" "TEXT"
        create_dir "$WORK_DIR/$DIR_ARCH"
      fi
      handle_output "# Checking docker images" "TEXT"
      DOCKER_IMAGE_CHECK=$( docker images |grep "^$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" |awk '{print $1}' )
      handle_output "# Checking volume images" "TEXT"
      DOCKER_VOLUME_CHECK=$( docker volume list |grep "^$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" |awk '{print $1}' )
      if ! [ "$DOCKER_VOLUME_CHECK" = "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" ]; then
        if [ "$TEST_MODE" = "false" ]; then
          docker volume create "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH"
        fi
      fi
      if ! [ "$DOCKER_IMAGE_CHECK" = "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" ]; then
        if [ "$TEST_MODE" = "false" ]; then
          handle_output "# Creating Docker compose file $WORK_DIR/$DIR_ARCH/docker-compose.yml" "TEXT"
          echo "version: \"3\"" > "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "services:" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "  $SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH:" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    build:" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "      context: ." >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "      dockerfile: Dockerfile" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    image: $SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    container_name: $SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    entrypoint: /bin/bash" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    working_dir: /root" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    platform: linux/$DIR_ARCH" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    volumes:" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "      - /docker/$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH/:/root/$SCRIPT_NAME/" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          print_file "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          handle_output "# Creating Docker config $WORK_DIR/$DIR_ARCH/Dockerfile" "TEXT"
          echo "FROM ubuntu:$CURRENT_DOCKER_UBUNTU_RELEASE" > "$WORK_DIR/$DIR_ARCH/Dockerfile"
          echo "RUN apt-get update && apt-get -o Dpkg::Options::=\"--force-overwrite\" install -y $REQUIRED_PACKAGES" >> "$WORK_DIR/$DIR_ARCH/Dockerfile"
          print_file "$WORK_DIR/$DIR_ARCH/Dockerfile"
          handle_output "# Building docker image $SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" "TEXT"
          docker build "$WORK_DIR/$DIR_ARCH" --tag "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$DIR_ARCH" --platform "linux/$DIR_ARCH"
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
    check_work_dir
    DOCKER_BIN="$WORK_DIR/files/$SCRIPT_BIN"
    DOCKER_MODULE_DIR="$WORK_DIR/files/modules"
    if [ ! -d "$DOCKER_MODULE_DIR" ]; then
      mkdir -p "$DOCKER_MODULE_DIR"
    fi
    cp "$MODULE_PATH"/* "$DOCKER_MODULE_DIR"
    LOCAL_SCRIPT="$WORK_DIR/files/guige_docker_script.sh"
    DOCKER_SCRIPT="$DOCKER_WORK_DIR/files/guige_docker_script.sh"
    cp "$SCRIPT_FILE" "$DOCKER_BIN"
    chmod +x "$DOCKER_BIN"
    if [ "$DO_OLD_INSTALLER" = "true" ]; then
      check_old_work_dir
    fi
    check_docker_config
    handle_output "" ""
    if [ "$DO_DOCKER" = "false" ]; then
      exit
    fi
    if ! [ "$TEST_MODE" = "true" ]; then
      echo "#!/bin/bash" > "$LOCAL_SCRIPT"
      echo "$DOCKER_WORK_DIR/files/$SCRIPT_BIN $SCRIPT_ARGS --workdir $DOCKER_WORK_DIR --preworkdir $WORK_DIR" >> "$LOCAL_SCRIPT"
      if [ "$DO_DOCKER" = "true" ]; then
        BASE_DOCKER_ISO_OUTPUT_FILE=$( basename "$ISO_OUTPUT_FILE" )
        echo "# Output file will be at \"$WORK_DIR/files/$BASE_DOCKER_ISO_OUTPUT_FILE\""
      fi
      verbose_message "# Executing: exec docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule=\"b 7:* rmw\" --platform \"linux/$ISO_ARCH\" --mount source=\"$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$ISO_ARCH,target=/root/$SCRIPT_NAME\" --mount type=bind,source=\"$WORK_DIR/files,target=/root/$SCRIPT_NAME/$NEW_DIR/files\"  \"$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$ISO_ARCH\" /bin/bash \"$DOCKER_SCRIPT\""
      exec docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule="b 7:* rmw" --platform "linux/$ISO_ARCH" --mount source="$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$ISO_ARCH,target=/root/$SCRIPT_NAME" --mount type=bind,source="$WORK_DIR/files,target=/root/$SCRIPT_NAME/$NEW_DIR/files"  "$SCRIPT_NAME-$CURRENT_DOCKER_UBUNTU_RELEASE-$ISO_ARCH" /bin/bash "$DOCKER_SCRIPT"
      exit
    fi
  fi
  DO_PRINT_HELP="false"
}
