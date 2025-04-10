#!/usr/bin/env bash

# shellcheck disable=SC2129

# Function: check_ansible
#
# Check ansible

check_ansible () {
  handle_output "# Checking ansible is installed" "TEXT"
  ANSIBLE_BIN=$( which ansible )
  ANSIBLE_CHECK=$( basename "$ANSIBLE_BIN" )
  if [ "$OS_NAME" = "Darwin" ]; then
    COMMAND="brew install ansible"
  else
    COMMAND="sudo apt install -y ansible"
  fi
  handle_output "$COMMAND" ""
  if ! [ "$ANSIBLE_CHECK" = "ansible" ]; then
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      $COMMAND
    fi
  fi
  handle_output "# Checking ansible collection dellemc.openmanage is installed" "TEXT"
  ANSIBLE_CHECK=$( ansible-galaxy collection list |grep "dellemc.openmanage" |awk '{print $1}' |uniq )
  if ! [ "$ANSIBLE_CHECK" = "dellemc.openmanage" ]; then
    if [ "$DO_ISO_TESTMODE" = "false" ]; then
      ansible-galaxy collection install dellemc.openmanage
    fi
  fi
}

# Function: create_ansible
#
# Creates an ansible file for setting up boot device on iDRAC using Redfish

create_ansible () {
  HOSTS_YAML="$ISO_WORKDIR/hosts.yaml"
  handle_output "# Creating ansible hosts file $HOSTS_YAML" "TEXT"
  if [ "$DO_ISO_TESTMODE" = "false" ]; then
    echo "---" > "$HOSTS_YAML"
    echo "idrac:" >> "$HOSTS_YAML"
    echo "  hosts:" >> "$HOSTS_YAML"
    echo "    $ISO_HOSTNAME:" >> "$HOSTS_YAML"
    echo "      ansible_host:   $ISO_BMCIP" >> "$HOSTS_YAML"
    echo "      baseuri:        $ISO_BMCIP" >> "$HOSTS_YAML"
    echo "      idrac_user:     $ISO_BMCUSERNAME" >> "$HOSTS_YAML"
    echo "      idrac_password: $ISO_BMCPASSWORD" >> "$HOSTS_YAML"
    print_file "$HOSTS_YAML"
  fi
  IDRAC_YAML="$ISO_WORKDIR/idrac.yaml"
  NFS_FILE=$( basename "$ISO_BOOTSERVERFILE" )
  NFS_DIR=$( dirname "$ISO_BOOTSERVERFILE" )
  if [ "$DO_ISO_TESTMODE" = "false" ]; then
    echo "- hosts: idrac" > "$IDRAC_YAML"
    echo "  name: $ISO_VOLID" >> "$IDRAC_YAML"
    echo "  gather_facts: False" >> "$IDRAC_YAML"
    echo "  vars:" >> "$IDRAC_YAML"
    echo "    idrac_osd_command_allowable_values: [\"BootToNetworkISO\", \"GetAttachStatus\", \"DetachISOImage\"]" >> "$IDRAC_YAML"
    echo "    idrac_osd_command_default: \"GetAttachStatus\"" >> "$IDRAC_YAML"
    echo "    GetAttachStatus_Code:" >> "$IDRAC_YAML"
    echo "      DriversAttachStatus:" >> "$IDRAC_YAML"
    echo "        \"0\": \"NotAttached\"" >> "$IDRAC_YAML"
    echo "        \"1\": \"Attached\"" >> "$IDRAC_YAML"
    echo "      ISOAttachStatus:" >> "$IDRAC_YAML"
    echo "        \"0\": \"NotAttached\"" >> "$IDRAC_YAML"
    echo "        \"1\": \"Attached\"" >> "$IDRAC_YAML"
    echo "    idrac_https_port:           $BMC_PORT" >> "$IDRAC_YAML"
    echo "    expose_duration:            $BMC_EXPOSE_DURATION" >> "$IDRAC_YAML"
    echo "    command:                    \"{{ idrac_osd_command_default }}\"" >> "$IDRAC_YAML"
    echo "    validate_certs:             no" >> "$IDRAC_YAML"
    echo "    force_basic_auth:           yes" >> "$IDRAC_YAML"
    echo "    share_name:                 $ISO_BOOTSERVERIP:$NFS_DIR/" >> "$IDRAC_YAML"
    echo "    ubuntu_iso:                 $NFS_FILE" >> "$IDRAC_YAML"
    echo "  collections:" >> "$IDRAC_YAML"
    echo "    - dellemc.openmanage" >> "$IDRAC_YAML"
    echo "  tasks:" >> "$IDRAC_YAML"
    echo "    - name: find the URL for the DellOSDeploymentService" >> "$IDRAC_YAML"
    echo "      ansible.builtin.uri:" >> "$IDRAC_YAML"
    echo "        url: \"https://{{ baseuri }}/redfish/v1/Systems/System.Embedded.1\"" >> "$IDRAC_YAML"
    echo "        user: \"{{ idrac_user }}\"" >> "$IDRAC_YAML"
    echo "        password: \"{{ idrac_password }}\"" >> "$IDRAC_YAML"
    echo "        method: GET" >> "$IDRAC_YAML"
    echo "        headers:" >> "$IDRAC_YAML"
    echo "          Accept: \"application/json\"" >> "$IDRAC_YAML"
    echo "          OData-Version: \"4.0\"" >> "$IDRAC_YAML"
    echo "        status_code: 200" >> "$IDRAC_YAML"
    echo "        validate_certs: \"{{ validate_certs }}\"" >> "$IDRAC_YAML"
    echo "        force_basic_auth: \"{{ force_basic_auth }}\"" >> "$IDRAC_YAML"
    echo "      register: result" >> "$IDRAC_YAML"
    echo "      delegate_to: localhost" >> "$IDRAC_YAML"
    echo "    - name: find the URL for the DellOSDeploymentService" >> "$IDRAC_YAML"
    echo "      ansible.builtin.set_fact:" >> "$IDRAC_YAML"
    echo "        idrac_osd_service_url: \"{{ result.json.Links.Oem.Dell.DellOSDeploymentService['@odata.id'] }}\"" >> "$IDRAC_YAML"
    echo "      when:" >> "$IDRAC_YAML"
    echo "        - result.json.Links.Oem.Dell.DellOSDeploymentService is defined" >> "$IDRAC_YAML"
    echo "    - block:" >> "$IDRAC_YAML"
    echo "        - name: get ISO attach status" >> "$IDRAC_YAML"
    echo "          ansible.builtin.uri:" >> "$IDRAC_YAML"
    echo "            url: \"https://{{ baseuri }}{{ idrac_osd_service_url }}/Actions/DellOSDeploymentService.GetAttachStatus\"" >> "$IDRAC_YAML"
    echo "            user: \"{{ idrac_user }}\"" >> "$IDRAC_YAML"
    echo "            password: \"{{ idrac_password }}\"" >> "$IDRAC_YAML"
    echo "            method: POST" >> "$IDRAC_YAML"
    echo "            headers:" >> "$IDRAC_YAML"
    echo "              Accept: \"application/json\"" >> "$IDRAC_YAML"
    echo "              Content-Type: \"application/json\"" >> "$IDRAC_YAML"
    echo "              OData-Version: \"4.0\"" >> "$IDRAC_YAML"
    echo "            body: \"{}\"" >> "$IDRAC_YAML"
    echo "            status_code: 200" >> "$IDRAC_YAML"
    echo "            force_basic_auth: \"{{ force_basic_auth }}\"" >> "$IDRAC_YAML"
    echo "          register: attach_status" >> "$IDRAC_YAML"
    echo "          delegate_to: localhost" >> "$IDRAC_YAML"
    echo "        - name: set ISO attach status as a fact variable" >> "$IDRAC_YAML"
    echo "          ansible.builtin.set_fact:" >> "$IDRAC_YAML"
    echo "            idrac_iso_attach_status: \"{{ idrac_iso_attach_status | default({}) | combine({item.key: item.value}) }}\"" >> "$IDRAC_YAML"
    echo "          with_dict:" >> "$IDRAC_YAML"
    echo "            DriversAttachStatus: \"{{ attach_status.json.DriversAttachStatus }}\"" >> "$IDRAC_YAML"
    echo "            ISOAttachStatus: \"{{ attach_status.json.ISOAttachStatus }}\"" >> "$IDRAC_YAML"
    echo "      when:" >> "$IDRAC_YAML"
    echo "        - idrac_osd_service_url is defined" >> "$IDRAC_YAML"
    echo "        - idrac_osd_service_url|length > 0" >> "$IDRAC_YAML"
    echo "    - block:" >> "$IDRAC_YAML"
    echo "        - name: detach ISO image if attached" >> "$IDRAC_YAML"
    echo "          ansible.builtin.uri:" >> "$IDRAC_YAML"
    echo "            url: \"https://{{ baseuri }}{{ idrac_osd_service_url }}/Actions/DellOSDeploymentService.DetachISOImage\"" >> "$IDRAC_YAML"
    echo "            user: \"{{ idrac_user }}\"" >> "$IDRAC_YAML"
    echo "            password: \"{{ idrac_password }}\"" >> "$IDRAC_YAML"
    echo "            method: POST" >> "$IDRAC_YAML"
    echo "            headers:" >> "$IDRAC_YAML"
    echo "              Accept: \"application/json\"" >> "$IDRAC_YAML"
    echo "              Content-Type: \"application/json\"" >> "$IDRAC_YAML"
    echo "              OData-Version: \"4.0\"" >> "$IDRAC_YAML"
    echo "            body: \"{}\"" >> "$IDRAC_YAML"
    echo "            status_code: 200" >> "$IDRAC_YAML"
    echo "            force_basic_auth: \"{{ force_basic_auth }}\"" >> "$IDRAC_YAML"
    echo "          register: detach_status" >> "$IDRAC_YAML"
    echo "          delegate_to: localhost" >> "$IDRAC_YAML"
    echo "        - ansible.builtin.debug:" >> "$IDRAC_YAML"
    echo "            msg: \"Successfuly detached the ISO image\"" >> "$IDRAC_YAML"
    echo "      when:" >> "$IDRAC_YAML"
    echo "        - idrac_osd_service_url is defined and idrac_osd_service_url|length > 0" >> "$IDRAC_YAML"
    echo "        - idrac_iso_attach_status" >> "$IDRAC_YAML"
    echo "        - idrac_iso_attach_status.ISOAttachStatus == \"Attached\" or" >> "$IDRAC_YAML"
    echo "          idrac_iso_attach_status.DriversAttachStatus == \"Attached\"" >> "$IDRAC_YAML"
    echo "    - name: boot to network ISO" >> "$IDRAC_YAML"
    echo "      dellemc.openmanage.idrac_os_deployment:" >> "$IDRAC_YAML"
    echo "        idrac_ip: \"{{ baseuri }}\"" >> "$IDRAC_YAML"
    echo "        idrac_user: \"{{ idrac_user }}\"" >> "$IDRAC_YAML"
    echo "        idrac_password: \"{{ idrac_password }}\"" >> "$IDRAC_YAML"
    echo "        share_name: \"{{ share_name }}\"" >> "$IDRAC_YAML"
    echo "        iso_image: \"{{ ubuntu_iso }}\"" >> "$IDRAC_YAML"
    echo "        expose_duration: \"{{ expose_duration }}\"" >> "$IDRAC_YAML"
    echo "      register: boot_to_network_iso_status" >> "$IDRAC_YAML"
    echo "      delegate_to: localhost" >> "$IDRAC_YAML"
    print_file "$IDRAC_YAML"
  fi
}

# Function: install_server
#
# Run ansible playbook to boot server from ISO

install_server () {
  HOSTS_YAML="$ISO_WORKDIR/hosts.yaml"
  IDRAC_YAML="$ISO_WORKDIR/idrac.yaml"
  handle_output "# Executing ansible playbook $IDRAC_YAML" "TEXT"
  if [ "$DO_ISO_TESTMODE" = "false" ]; then
    ansible-playbook "$IDRAC_YAML" -i "$HOSTS_YAML"
  fi
}
