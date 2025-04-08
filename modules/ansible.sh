#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: check_ansible
#
# Check ansible

check_ansible () {
  handle_output "# Checking ansible is installed" "TEXT"
  ansible_bin=$( which ansible )
  ansible_check=$( basename "${ansible_bin}" )
  if [ "${os['name']}" = "Darwin" ]; then
    command="brew install ansible"
  else
    command="sudo apt install -y ansible"
  fi
  handle_output "${ommand}" ""
  if ! [ "${ansible_check}" = "ansible" ]; then
    if [ "${options['testmode']}" = "false" ]; then
      ${command}
    fi
  fi
  handle_output "# Checking ansible collection dellemc.openmanage is installed" "TEXT"
  ansible_check=$( ansible-galaxy collection list |grep "dellemc.openmanage" |awk '{print $1}' |uniq )
  if ! [ "${ansible_check}" = "dellemc.openmanage" ]; then
    if [ "${options['testmode']}" = "false" ]; then
      ansible-galaxy collection install dellemc.openmanage
    fi
  fi
}

# Function: create_ansible
#
# Creates an ansible file for setting up boot device on iDRAC using Redfish

create_ansible () {
  hosts_yaml="${iso['workdir']}/hosts.yaml"
  handle_output "# Creating ansible hosts file ${hosts_yaml}" "TEXT"
  if [ "${options['testmode']}" = "false" ]; then
    echo "---" > "${hosts_yaml}"
    echo "idrac:" >> "${hosts_yaml}"
    echo "  hosts:" >> "${hosts_yaml}"
    echo "    ${iso['hostname']}:" >> "${hosts_yaml}"
    echo "      ansible_host:   ${iso['bmcip']}" >> "${hosts_yaml}"
    echo "      baseuri:        ${iso['bmcip']}" >> "${hosts_yaml}"
    echo "      idrac_user:     ${iso['bmcusername']}" >> "${hosts_yaml}"
    echo "      idrac_password: ${iso['bmcpassword']}" >> "${hosts_yaml}"
    print_file "${hosts_yaml}"
  fi
  idrac_yaml="${iso['workdir']}/idrac.yaml"
  nfs_file=$( basename "${iso['bootserverfile']}" )
  nfs_dir=$( dirname "${iso['bootserverfile']}" )
  if [ "${options['testmode']}" = "false" ]; then
    echo "- hosts: idrac" > "${idrac_yaml}"
    echo "  name: ${iso['volid']}" >> "${idrac_yaml}"
    echo "  gather_facts: False" >> "${idrac_yaml}"
    echo "  vars:" >> "${idrac_yaml}"
    echo "    idrac_osd_command_allowable_values: [\"BootToNetworkISO\", \"GetAttachStatus\", \"DetachISOImage\"]" >> "${idrac_yaml}"
    echo "    idrac_osd_command_default: \"GetAttachStatus\"" >> "${idrac_yaml}"
    echo "    GetAttachStatus_Code:" >> "${idrac_yaml}"
    echo "      DriversAttachStatus:" >> "${idrac_yaml}"
    echo "        \"0\": \"NotAttached\"" >> "${idrac_yaml}"
    echo "        \"1\": \"Attached\"" >> "${idrac_yaml}"
    echo "      ISOAttachStatus:" >> "${idrac_yaml}"
    echo "        \"0\": \"NotAttached\"" >> "${idrac_yaml}"
    echo "        \"1\": \"Attached\"" >> "${idrac_yaml}"
    echo "    idrac_https_port:           ${options['bmcport']}" >> "${idrac_yaml}"
    echo "    expose_duration:            ${iso['bmcexposeduration']}" >> "${idrac_yaml}"
    echo "    command:                    \"{{ idrac_osd_command_default }}\"" >> "${idrac_yaml}"
    echo "    validate_certs:             no" >> "${idrac_yaml}"
    echo "    force_basic_auth:           yes" >> "${idrac_yaml}"
    echo "    share_name:                 ${iso['bootserverip']}:${nfs_dir}/" >> "${idrac_yaml}"
    echo "    ubuntu_iso:                 ${nfs_file}" >> "${idrac_yaml}"
    echo "  collections:" >> "${idrac_yaml}"
    echo "    - dellemc.openmanage" >> "${idrac_yaml}"
    echo "  tasks:" >> "${idrac_yaml}"
    echo "    - name: find the URL for the DellOSDeploymentService" >> "${idrac_yaml}"
    echo "      ansible.builtin.uri:" >> "${idrac_yaml}"
    echo "        url: \"https://{{ baseuri }}/redfish/v1/Systems/System.Embedded.1\"" >> "${idrac_yaml}"
    echo "        user: \"{{ idrac_user }}\"" >> "${idrac_yaml}"
    echo "        password: \"{{ idrac_password }}\"" >> "${idrac_yaml}"
    echo "        method: GET" >> "${idrac_yaml}"
    echo "        headers:" >> "${idrac_yaml}"
    echo "          Accept: \"application/json\"" >> "${idrac_yaml}"
    echo "          OData-Version: \"4.0\"" >> "${idrac_yaml}"
    echo "        status_code: 200" >> "${idrac_yaml}"
    echo "        validate_certs: \"{{ validate_certs }}\"" >> "${idrac_yaml}"
    echo "        force_basic_auth: \"{{ force_basic_auth }}\"" >> "${idrac_yaml}"
    echo "      register: result" >> "${idrac_yaml}"
    echo "      delegate_to: localhost" >> "${idrac_yaml}"
    echo "    - name: find the URL for the DellOSDeploymentService" >> "${idrac_yaml}"
    echo "      ansible.builtin.set_fact:" >> "${idrac_yaml}"
    echo "        idrac_osd_service_url: \"{{ result.json.Links.Oem.Dell.DellOSDeploymentService['@odata.id']} }}\"" >> "${idrac_yaml}"
    echo "      when:" >> "${idrac_yaml}"
    echo "        - result.json.Links.Oem.Dell.DellOSDeploymentService is defined" >> "${idrac_yaml}"
    echo "    - block:" >> "${idrac_yaml}"
    echo "        - name: get ISO attach status" >> "${idrac_yaml}"
    echo "          ansible.builtin.uri:" >> "${idrac_yaml}"
    echo "            url: \"https://{{ baseuri }}{{ idrac_osd_service_url }}/Actions/DellOSDeploymentService.GetAttachStatus\"" >> "${idrac_yaml}"
    echo "            user: \"{{ idrac_user }}\"" >> "${idrac_yaml}"
    echo "            password: \"{{ idrac_password }}\"" >> "${idrac_yaml}"
    echo "            method: POST" >> "${idrac_yaml}"
    echo "            headers:" >> "${idrac_yaml}"
    echo "              Accept: \"application/json\"" >> "${idrac_yaml}"
    echo "              Content-Type: \"application/json\"" >> "${idrac_yaml}"
    echo "              OData-Version: \"4.0\"" >> "${idrac_yaml}"
    echo "            body: \"{}\"" >> "${idrac_yaml}"
    echo "            status_code: 200" >> "${idrac_yaml}"
    echo "            force_basic_auth: \"{{ force_basic_auth }}\"" >> "${idrac_yaml}"
    echo "          register: attach_status" >> "${idrac_yaml}"
    echo "          delegate_to: localhost" >> "${idrac_yaml}"
    echo "        - name: set ISO attach status as a fact variable" >> "${idrac_yaml}"
    echo "          ansible.builtin.set_fact:" >> "${idrac_yaml}"
    echo "            idrac_iso_attach_status: \"{{ idrac_iso_attach_status | default({}) | combine({item.key: item.value}) }}\"" >> "${idrac_yaml}"
    echo "          with_dict:" >> "${idrac_yaml}"
    echo "            DriversAttachStatus: \"{{ attach_status.json.DriversAttachStatus }}\"" >> "${idrac_yaml}"
    echo "            ISOAttachStatus: \"{{ attach_status.json.ISOAttachStatus }}\"" >> "${idrac_yaml}"
    echo "      when:" >> "${idrac_yaml}"
    echo "        - idrac_osd_service_url is defined" >> "${idrac_yaml}"
    echo "        - idrac_osd_service_url|length > 0" >> "${idrac_yaml}"
    echo "    - block:" >> "${idrac_yaml}"
    echo "        - name: detach ISO image if attached" >> "${idrac_yaml}"
    echo "          ansible.builtin.uri:" >> "${idrac_yaml}"
    echo "            url: \"https://{{ baseuri }}{{ idrac_osd_service_url }}/Actions/DellOSDeploymentService.DetachISOImage\"" >> "${idrac_yaml}"
    echo "            user: \"{{ idrac_user }}\"" >> "${idrac_yaml}"
    echo "            password: \"{{ idrac_password }}\"" >> "${idrac_yaml}"
    echo "            method: POST" >> "${idrac_yaml}"
    echo "            headers:" >> "${idrac_yaml}"
    echo "              Accept: \"application/json\"" >> "${idrac_yaml}"
    echo "              Content-Type: \"application/json\"" >> "${idrac_yaml}"
    echo "              OData-Version: \"4.0\"" >> "${idrac_yaml}"
    echo "            body: \"{}\"" >> "${idrac_yaml}"
    echo "            status_code: 200" >> "${idrac_yaml}"
    echo "            force_basic_auth: \"{{ force_basic_auth }}\"" >> "${idrac_yaml}"
    echo "          register: detach_status" >> "${idrac_yaml}"
    echo "          delegate_to: localhost" >> "${idrac_yaml}"
    echo "        - ansible.builtin.debug:" >> "${idrac_yaml}"
    echo "            msg: \"Successfuly detached the ISO image\"" >> "${idrac_yaml}"
    echo "      when:" >> "${idrac_yaml}"
    echo "        - idrac_osd_service_url is defined and idrac_osd_service_url|length > 0" >> "${idrac_yaml}"
    echo "        - idrac_iso_attach_status" >> "${idrac_yaml}"
    echo "        - idrac_iso_attach_status.ISOAttachStatus == \"Attached\" or" >> "${idrac_yaml}"
    echo "          idrac_iso_attach_status.DriversAttachStatus == \"Attached\"" >> "${idrac_yaml}"
    echo "    - name: boot to network ISO" >> "${idrac_yaml}"
    echo "      dellemc.openmanage.idrac_os_deployment:" >> "${idrac_yaml}"
    echo "        idrac_ip: \"{{ baseuri }}\"" >> "${idrac_yaml}"
    echo "        idrac_user: \"{{ idrac_user }}\"" >> "${idrac_yaml}"
    echo "        idrac_password: \"{{ idrac_password }}\"" >> "${idrac_yaml}"
    echo "        share_name: \"{{ share_name }}\"" >> "${idrac_yaml}"
    echo "        iso_image: \"{{ ubuntu_iso }}\"" >> "${idrac_yaml}"
    echo "        expose_duration: \"{{ expose_duration }}\"" >> "${idrac_yaml}"
    echo "      register: boot_to_network_iso_status" >> "${idrac_yaml}"
    echo "      delegate_to: localhost" >> "${idrac_yaml}"
    print_file "${idrac_yaml}"
  fi
}

# Function: install_server
#
# Run ansible playbook to boot server from ISO

install_server () {
  hosts_yaml="${iso['workdir']}/hosts.yaml"
  idrac_yaml="${iso['workdir']}/idrac.yaml"
  handle_output "# Executing ansible playbook ${idrac_yaml}" "TEXT"
  if [ "${options['testmode']}" = "false" ]; then
    ansible-playbook "${idrac_yaml}" -i "${hosts_yaml}"
  fi
}
