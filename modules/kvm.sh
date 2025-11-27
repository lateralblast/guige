#!/usr/bin/env bash

# shellcheck disable=SC2007
# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: check_kvm_vm_existd
#
# Check if KVM VM exists

check_kvm_vm_exists () {
  if [ "${os['name']}" = "Darwin" ]; then
    kvm_test=$(virsh list --all |awk '{ print $2 }' |grep -c "^${iso['name']}" )
  else
    kvm_test=$(sudo virsh list --all |awk '{ print $2 }' |grep -c "^${iso['name']}" )
  fi
  if [ ! "${kvm_test}" = "0" ]; then
    warning_message "KVM VM ${iso['name']} exists"
   iso['exists']="true"
  fi
}

# Function: check_kvm_user
#
# Check user KVM permissions

check_kvm_user () {
  iso['kvmgroups']="kvm libvirt libvirt-qemu libvirt-dnsmasq"
  for kvm_group in ${iso['kvmgroups']}; do
    group_members=$( grep "^${kvm_group}" /etc/group |cut -f2 -d: )
    if [ -n "${group_members}" ]; then
      if ! [[ "${kvm_group}" =~ $USER ]]; then
        sudo usermod -a -G "${kvm_group}" "$USER"
      fi
    fi
  done
}

# Function: check_kvm_config
#
# Check KVM VM config

check_kvm_config () {
  if [ -z "$( command -v virsh )" ]; then
    install_required_kvm_packages
  fi
  if [ "${os['name']}" = "Darwin" ]; then
    iso['brewdir']="/opt/homebrew/Cellar"
    if [ ! -d "${iso['brewdir']}" ]; then
      iso['brewdir']="/usr/local/Cellar"
      iso['virtdir']="${iso['brewdir']}/libvirt"
      iso['bindir']="/usr/local/bin"
    else
      iso['virtdir']="/opt/homebrew/var/lib/libvirt"
      iso['bindir']="/opt/homebrew/bin"
    fi
    iso['imagedir']="${iso['virtdir']}/images"
    if [ ! -d "${iso['virtdir']}" ]; then
      sudo_create_dir "${iso['virtdir']}"
      sudo_chown "${iso['virtdir']}" "${os['user']}" "${os['group']}"
    fi
    if [ ! -d "${iso['imagedir']}" ]; then
      sudo_create_dir "${iso['imagedir']}"
      sudo_chown "${iso['imagedir']}" "${os['user']}" "${os['group']}"
    fi
  else
    iso['virtdir']="/var/lib/libvirt"
    iso['imagedir']="${iso['virtdir']}/images"
    if [ ! -d "${iso['virtdir']}" ]; then
      sudo_create_dir "${iso['virtdir']}"
    fi
    if [ ! -d "${iso['imagedir']}" ]; then
      sudo_create_dir "${iso['imagedir']}"
    fi
  fi
  if [ "${iso['diskfile']}" = "" ]; then
    iso['diskfile']="${iso['workdir']}/${iso['name']}.qcow2"
  fi
  check_kvm_user
  check_kvm_network
}

# Function: create_kvm_ci_vm
#
# Create a KVM VM for testing cloud init

create_kvm_ci_vm () {
  check_kvm_config
  get_base_ci
}

# Function: get_kvm_iso
#
# Get KVM ISO

get_kvm_iso () {
  options['autoinstall']="true"
  if [ "${iso['vmiso']}" = "" ]; then
    iso['build']=${iso['build']//\//-}
    iso['vmiso']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-${iso['build']}-${iso['arch']}.iso"
    if [ ! -f "${iso['vmiso']}" ]; then
      iso['outputfile']="${iso['vmiso']}"
      update_output_file_name
      iso['vmiso']="${iso['outputfile']}"
      if [ ! -f "${iso['vmiso']}" ]; then
        iso_dir="${iso['workdir']}/files"
        iso_file=$( ls -Art "${iso_dir}"/*.iso |head -1 )
        iso['vmiso']="${iso_dir}/${iso_file}"
      fi
    fi
  fi
  if [ ! -f "${iso['vmiso']}" ]; then
    warning_message "ISO ${iso['vmiso']} does not exist"
    do_exit
  fi
}

# Function: set_cdrom_device
#
# Set cdrom device

set_cdrom_device () {
  cdrom_device="/tmp/${iso['name']}_cdrom.xml"
  if [ -f "${cdrom_device}" ]; then
    rm "${cdrom_device}"
  fi
  get_kvm_iso
  tee "${cdrom_device}" << CDROM_DEVICE
  <disk type='file' device='cdrom'>
    <driver name='qemu' type='raw'/>
    <source file='${iso['vmiso']}'/>
    <target dev='sda' bus='sata'/>
    <readonly/>
    <address type='drive' controller='0' bus='0' target='0' unit='0'/>
  </disk>
CDROM_DEVICE
  if [ -f "${cdrom_device}" ]; then
    if [ "${os['name']}" = "Darwin" ]; then
      execute_command "virsh update-device ${iso['name']} ${cdrom_device}"
    else
      execute_command "sudo virsh update-device ${iso['name']} ${cdrom_device}"
    fi
  fi
}

# Function: create_kvm_iso_vm
#
# Create a KVM VM for testing an ISO

create_kvm_iso_vm () {
  check_kvm_config
  get_kvm_iso
  if [ "${os['name']}" = "Darwin" ]; then
    iso['qemuver']=$( brew info qemu --json |jq -r ".[0].versions.stable" )
    iso['qemuvir']=$( echo "${iso['qemuver']}" |awk -F. '{print $1"."$2}' )
    if [ "${iso['arch']}" = "amd64" ] || [ "${iso['arch']}" = "x86_64" ]; then
      iso['varsfile']="${iso['brewdir']}/qemu/${iso['qemuver']}/share/qemu/edk2-i386-vars.fd"
      iso['biosfile']="${iso['brewdir']}/qemu/${iso['qemuver']}/share/qemu/edk2-x86_64-code.fd"
      iso['qemuarch']="x86_64"
      iso['qemu']="${iso['bindir']}/qemu-system-x86_64"
      iso['machine']="pc-q35-${iso['qemuvir']}"
      iso['serial']="isa-serial"
    else
      iso['varsfile']="${iso['brewdir']}/qemu/${iso['qemuver']}/share/qemu/edk2-arm-vars.fd"
      iso['biosfile']="${iso['brewdir']}/qemu/${iso['qemuver']}/share/qemu/edk2-aarch64-code.fd"
      iso['qemuarch']="aarch64"
      iso['qemu']="${iso['bindir']}/qemu-system-aarch64"
      iso['machine']="virt-${iso['qemuvir']}"
      iso['serial']="system-serial"
    fi
    iso['domaintype']="qemu"
    iso['video']="vga"
    iso['inputbus']="usb"
    iso['iftype']="user"
    iso['cdbus']="scsi"
    options['secureboot']="false"
  else
    iso['qemuver']=$( qemu-system-amd64 --version |head -1 |awk '{print $4}' |awk -F"." '{print $1"."$2}' )
    if [ "${options['secureboot']}" = "true" ]; then
      iso['varsfile']="/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
      iso['biosfile']="/usr/share/OVMF/OVMF_CODE_4M.ms.fd"
    else
      iso['varsfile']="/usr/share/OVMF/OVMF_VARS.fd"
      iso['biosfile']="/usr/share/OVMF/OVMF_CODE.fd"
    fi
    iso['qemuarch']="x86_64"
    iso['qemu']="/usr/bin/qemu-system-x86_64"
    iso['domaintype']="kvm"
    iso['machine']="pc-q35-${iso['qemuver']}"
    iso['video']="qxl"
    iso['serial']="isa-serial"
    iso['inputbus']="ps2"
    iso['iftype']="network"
    iso['cdbus']="sata"
  fi
  if [ "${iso['osname']}" = "ubuntu" ]; then
    iso['infosite']="ubuntu.com"
  else
    iso['infosite']="rockylinux.org"
  fi
  iso['qemudir']="${iso['virtdir']}/qemu"
  iso['macaddress']=$( printf '52:54:00:%02X:%02X:%02X\n' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] )
  iso['nvramdir']="${iso['qemudir']}/nvram"
  if [ ! -d "${iso['nvramdir']}" ]; then
    sudo_create_dir "${iso['nvramdir']}"
    sudo_chown "${iso['nvramdir']}" "${os['user']}" "${os['group']}"
  fi
  iso['nvramfile']="${iso['nvramdir']}/${iso['name']}_VARS.fd"
  if ! [ -f "${iso['biosfile']}" ]; then
    iso['biosfile']="/usr/share/edk2/x64/OVMF_CODE.fd"
    iso['varsfile']="/usr/share/edk2/x64/OVMF_VARS.fd"
  fi
  if ! [ -f "${iso['biosfile']}" ]; then
    temp['verbose']="true"
    warning_message "Could not find BIOS file (tried ${iso['biosfile']})"
    exit
  fi
  information_message "Creating VM disk ${iso['diskfile']}"
  execute_message "sudo qemu-img create -f qcow2 ${iso['diskfile']} ${iso['disksize']}"
  if [ "${options['testmode']}" = "false" ]; then
    if [ "${os['name']}" = "Darwin" ]; then
      qemu-img create -f qcow2 "${iso['diskfile']}" "${iso['disksize']}"
    else
      sudo qemu-img create -f qcow2 "${iso['diskfile']}" "${iso['disksize']}"
    fi
  fi
  information_message "Generating VM config ${iso['xmlfile']}"
  iso['xmlfile']="/tmp/${iso['name']}.xml"
  echo "<domain type='${iso['domaintype']}'>" > "${iso['xmlfile']}"
  echo "  <name>${iso['name']}</name>" >> "${iso['xmlfile']}"
  echo "  <metadata>" >> "${iso['xmlfile']}"
  echo "    <libosinfo:libosinfo xmlns:libosinfo=\"http://libosinfo.org/xmlns/libvirt/domain/1.0\">" >> "${iso['xmlfile']}"
  echo "      <libosinfo:os id=\"http://${iso['infosite']}/${iso['osname']}/${iso['majorrelease']}.${iso['minorrelease']}\"/>" >> "${iso['xmlfile']}"
  echo "    </libosinfo:libosinfo>" >> "${iso['xmlfile']}"
  echo "  </metadata>" >> "${iso['xmlfile']}"
  echo "  <memory unit='KiB'>${iso['ram']}</memory>" >> "${iso['xmlfile']}"
  echo "  <currentMemory unit='KiB'>${iso['ram']}</currentMemory>" >> "${iso['xmlfile']}"
  echo "  <vcpu placement='static'>${iso['cpus']}</vcpu>" >> "${iso['xmlfile']}"
  if [ "${iso['boottype']}" = "bios" ]; then
    echo "  <os>" >> "${iso['xmlfile']}"
    echo "    <type arch='${iso['qemuarch']}' machine='${iso['machine']}'>hvm</type>" >> "${iso['xmlfile']}"
  else
    echo "  <os firmware='efi'>" >> "${iso['xmlfile']}"
    echo "    <type arch='${iso['qemuarch']}' machine='${iso['machine']}'>hvm</type>" >> "${iso['xmlfile']}"
    echo "    <firmware>" >> "${iso['xmlfile']}"
    if [ "${options['secureboot']}" = "true" ]; then
      echo "      <feature enabled='yes' name='enrolled-keys'/>" >> "${iso['xmlfile']}"
      echo "      <feature enabled='yes' name='secure-boot'/>" >> "${iso['xmlfile']}"
      echo "    </firmware>" >> "${iso['xmlfile']}"
      echo "    <loader readonly='yes' secure='yes' type='pflash'>${iso['biosfile']}</loader>" >> "${iso['xmlfile']}"
#      echo "    <nvram template='${iso['varsfile']}'>${iso['nvramfile']}</nvram>" >> "${iso['xmlfile']}"
    else
      echo "      <feature enabled='no' name='enrolled-keys'/>" >> "${iso['xmlfile']}"
      echo "      <feature enabled='no' name='secure-boot'/>" >> "${iso['xmlfile']}"
      echo "    </firmware>" >> "${iso['xmlfile']}"
      echo "    <loader readonly='yes' type='pflash'>${iso['biosfile']}</loader>" >> "${iso['xmlfile']}"
#      echo "    <nvram template='${iso['varsfile']}'>${iso['nvramfile']}</nvram>" >> "${iso['xmlfile']}"
    fi
  fi
  echo "    <boot dev='hd'/>" >> "${iso['xmlfile']}"
  echo "  </os>" >> "${iso['xmlfile']}"
  echo "  <features>" >> "${iso['xmlfile']}"
  if [ "${os['name']}" = "Darwin" ]; then
    echo "    <acpi/>" >> "${iso['xmlfile']}"
    if [ "${iso['arch']}" = "amd64" ] || [ "${iso['arch']}" = "x86_64" ]; then
      iso['cpufallback']="qemu64"
    else
      echo "    <gic version='2'/>" >> "${iso['xmlfile']}"
      iso['cpufallback']="cortex-a57"
    fi
    echo "  </features>" >> "${iso['xmlfile']}"
    echo "  <cpu mode='custom' match='exact' check='partial'>" >> "${iso['xmlfile']}"
    echo "    <model fallback='forbid'>${iso['cpufallback']}=</model>" >> "${iso['xmlfile']}"
    echo "  </cpu>" >> "${iso['xmlfile']}"
    echo "  <clock offset='utc'/>" >> "${iso['xmlfile']}"
    echo "  <on_poweroff>destroy</on_poweroff>" >> "${iso['xmlfile']}"
    echo "  <on_reboot>restart</on_reboot>" >> "${iso['xmlfile']}"
    echo "  <on_crash>destroy</on_crash>" >> "${iso['xmlfile']}"
  else
    echo "    <acpi/>" >> "${iso['xmlfile']}"
    echo "    <apic/>" >> "${iso['xmlfile']}"
    echo "    <vmport state='off'/>" >> "${iso['xmlfile']}"
    echo "  </features>" >> "${iso['xmlfile']}"
    echo "  <cpu mode='host-passthrough' check='none' migratable='on'/>" >> "${iso['xmlfile']}"
    echo "  <clock offset='utc'>" >> "${iso['xmlfile']}"
    echo "    <timer name='rtc' tickpolicy='catchup'/>" >> "${iso['xmlfile']}"
    echo "    <timer name='pit' tickpolicy='delay'/>" >> "${iso['xmlfile']}"
    echo "    <timer name='hpet' present='no'/>" >> "${iso['xmlfile']}"
    echo "  </clock>" >> "${iso['xmlfile']}"
    echo "  <on_poweroff>destroy</on_poweroff>" >> "${iso['xmlfile']}"
    echo "  <on_reboot>restart</on_reboot>" >> "${iso['xmlfile']}"
    echo "  <on_crash>destroy</on_crash>" >> "${iso['xmlfile']}"
    echo "  <pm>" >> "${iso['xmlfile']}"
    echo "    <suspend-to-mem enabled='no'/>" >> "${iso['xmlfile']}"
    echo "    <suspend-to-disk enabled='no'/>" >> "${iso['xmlfile']}"
    echo "  </pm>" >> "${iso['xmlfile']}"
  fi
  echo "  <devices>" >> "${iso['xmlfile']}"
  echo "    <emulator>${iso['qemu']}</emulator>" >> "${iso['xmlfile']}"
  echo "    <disk type='file' device='disk'>" >> "${iso['xmlfile']}"
  echo "      <driver name='qemu' type='qcow2' discard='unmap'/>" >> "${iso['xmlfile']}"
  echo "      <source file='${iso['diskfile']}'/>" >> "${iso['xmlfile']}"
  echo "      <target dev='vda' bus='virtio'/>" >> "${iso['xmlfile']}"
#  echo "      <boot order='2'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>" >> "${iso['xmlfile']}"
  echo "    </disk>" >> "${iso['xmlfile']}"
  if [ "${os['name']}" = "Darwin" ]; then
    echo "    <disk type='file' device='cdrom'>" >> "${iso['xmlfile']}"
    echo "      <driver name='qemu' type='raw'/>" >> "${iso['xmlfile']}"
    echo "      <source file='${iso['inputfile']}'/>" >> "${iso['xmlfile']}"
    echo "      <backingStore/>" >> "${iso['xmlfile']}"
    echo "      <target dev='sda' bus='${iso['cdbus']}'/>" >> "${iso['xmlfile']}"
    echo "      <readonly/>" >> "${iso['xmlfile']}"
#    echo "      <boot order='2'/>" >> "${iso['xmlfile']}"
    echo "      <alias name='scsi0-0-0-0'/>" >> "${iso['xmlfile']}"
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> "${iso['xmlfile']}"
    echo "    </disk>" >> "${iso['xmlfile']}"
    echo "    <controller type='scsi' index='0' model='virtio-scsi'>" >> "${iso['xmlfile']}"
    echo "      <alias name='scsi0'/>" >> "${iso['xmlfile']}"
    echo "      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>" >> "${iso['xmlfile']}"
    echo "    </controller>" >> "${iso['xmlfile']}"
    echo "    <controller type='virtio-serial' index='0'>" >> "${iso['xmlfile']}"
    echo "      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>" >> "${iso['xmlfile']}"
    echo "    </controller>" >> "${iso['xmlfile']}"
  else
    echo "    <disk type='file' device='cdrom'>" >> "${iso['xmlfile']}"
    echo "      <driver name='qemu' type='raw'/>" >> "${iso['xmlfile']}"
    echo "      <source file='${vm['inputfile']}'/>" >> "${iso['xmlfile']}"
    echo "      <target dev='sda' bus='${iso['cdbus']}'/>" >> "${iso['xmlfile']}"
    echo "      <readonly/>" >> "${iso['xmlfile']}"
#    echo "      <boot order='1'/>" >> "${iso['xmlfile']}"
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> "${iso['xmlfile']}"
    echo "    </disk>" >> "${iso['xmlfile']}"
    echo "    <controller type='virtio-serial' index='0'>" >> "${iso['xmlfile']}"
    echo "      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>" >> "${iso['xmlfile']}"
    echo "    </controller>" >> "${iso['xmlfile']}"
  fi
  echo "    <controller type='usb' index='0' model='qemu-xhci' ports='15'>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='0' model='pcie-root'/>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='1' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='1' port='0x10'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='2' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='2' port='0x11'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='3' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='3' port='0x12'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='4' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='4' port='0x13'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='5' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='5' port='0x14'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='6' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='6' port='0x15'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='7' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='7' port='0x16'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='8' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='8' port='0x17'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='9' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='9' port='0x18'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0' multifunction='on'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='10' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='10' port='0x19'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x1'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='11' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='11' port='0x1a'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x2'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='12' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='12' port='0x1b'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x3'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='13' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='13' port='0x1c'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x4'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='pci' index='14' model='pcie-root-port'>" >> "${iso['xmlfile']}"
  echo "      <model name='pcie-root-port'/>" >> "${iso['xmlfile']}"
  echo "      <target chassis='14' port='0x1d'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x5'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <controller type='sata' index='0'>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>" >> "${iso['xmlfile']}"
  echo "    </controller>" >> "${iso['xmlfile']}"
  echo "    <interface type='${iso['iftype']}'>" >> "${iso['xmlfile']}"
  echo "      <mac address='${iso['macaddress']}'/>" >> "${iso['xmlfile']}"
  if [ ! "${os['name']}" = "Darwin" ]; then
    echo "      <source network='default'/>" >> "${iso['xmlfile']}"
  fi
  echo "      <model type='virtio'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>" >> "${iso['xmlfile']}"
  echo "    </interface>" >> "${iso['xmlfile']}"
  echo "    <serial type='pty'>" >> "${iso['xmlfile']}"
  echo "      <target type='${iso['serial']}' port='0'>" >> "${iso['xmlfile']}"
  echo "        <alias name='${iso['serial']}'/>" >> "${iso['xmlfile']}"
  echo "      </target>" >> "${iso['xmlfile']}"
  echo "    </serial>" >> "${iso['xmlfile']}"
  echo "    <console type='pty'>" >> "${iso['xmlfile']}"
  echo "      <target type='serial' port='0'/>" >> "${iso['xmlfile']}"
  echo "    </console>" >> "${iso['xmlfile']}"
  echo "    <channel type='unix'>" >> "${iso['xmlfile']}"
  echo "      <target type='virtio' name='org.qemu.guest_agent.0'/>" >> "${iso['xmlfile']}"
  echo "      <address type='virtio-serial' controller='0' bus='0' port='1'/>" >> "${iso['xmlfile']}"
  echo "    </channel>" >> "${iso['xmlfile']}"
  echo "    <input type='tablet' bus='usb'>" >> "${iso['xmlfile']}"
  echo "      <address type='usb' bus='0' port='1'/>" >> "${iso['xmlfile']}"
  echo "    </input>" >> "${iso['xmlfile']}"
  echo "    <input type='mouse' bus='${iso['inputbus']}'/>" >> "${iso['xmlfile']}"
  echo "    <input type='keyboard' bus='${iso['inputbus']}'/>" >> "${iso['xmlfile']}"
  echo "    <sound model='ich9'>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>" >> "${iso['xmlfile']}"
  echo "    </sound>" >> "${iso['xmlfile']}"
  echo "    <video>" >> "${iso['xmlfile']}"
  echo "      <model type='virtio' heads='1' primary='yes'/>" >> "${iso['xmlfile']}"
  echo "      <alias name='video0'/>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>" >> "${iso['xmlfile']}"
  echo "    </video>" >> "${iso['xmlfile']}"
  if [ ! "${os['name']}" = "Darwin" ]; then
    echo "    <audio id='1' type='spice'/>" >> "${iso['xmlfile']}"
    echo "    <channel type='spicevmc'>" >> "${iso['xmlfile']}"
    echo "      <target type='virtio' name='com.redhat.spice.0'/>" >> "${iso['xmlfile']}"
    echo "      <address type='virtio-serial' controller='0' bus='0' port='2'/>" >> "${iso['xmlfile']}"
    echo "    </channel>" >> "${iso['xmlfile']}"
    echo "    <graphics type='spice' autoport='yes' listen='127.0.0.1'>" >> "${iso['xmlfile']}"
    echo "      <listen type='address' address='127.0.0.1'/>" >> "${iso['xmlfile']}"
    echo "      <image compression='off'/>" >> "${iso['xmlfile']}"
    echo "    </graphics>" >> "${iso['xmlfile']}"
    echo "    <redirdev bus='usb' type='spicevmc'>" >> "${iso['xmlfile']}"
    echo "      <address type='usb' bus='0' port='2'/>" >> "${iso['xmlfile']}"
    echo "    </redirdev>" >> "${iso['xmlfile']}"
    echo "    <redirdev bus='usb' type='spicevmc'>" >> "${iso['xmlfile']}"
    echo "      <address type='usb' bus='0' port='3'/>" >> "${iso['xmlfile']}"
    echo "    </redirdev>" >> "${iso['xmlfile']}"
    echo "    <watchdog model='itco' action='reset'/>" >> "${iso['xmlfile']}"
  fi
  echo "    <memballoon model='virtio'>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>" >> "${iso['xmlfile']}"
  echo "    </memballoon>" >> "${iso['xmlfile']}"
  echo "    <rng model='virtio'>" >> "${iso['xmlfile']}"
  echo "      <backend model='random'>/dev/urandom</backend>" >> "${iso['xmlfile']}"
  echo "      <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>" >> "${iso['xmlfile']}"
  echo "    </rng>" >> "${iso['xmlfile']}"
  echo "  </devices>" >> "${iso['xmlfile']}"
  echo "</domain>" >> "${iso['xmlfile']}"
  print_file "${iso['xmlfile']}"
  information_message "Importing VM config ${iso['xmlfile']}"
  if [ "${options['testmode']}" = "false" ]; then
    if [ "${os['name']}" = "Darwin" ]; then
      execute_message "virsh define ${iso['xmlfile']}"
      virsh define "${iso['xmlfile']}"
      set_cdrom_device
      verbose_message "To start the VM and connect to console run the following command:" TEXT
      verbose_message "" TEXT
      verbose_message "virsh start ${iso['name']} ; virsh console ${iso['name']}" TEXT
    else
      execute_message "sudo virsh define ${iso['xmlfile']}"
      sudo virsh define "${iso['xmlfile']}"
      set_cdrom_device
      verbose_message "To start the VM and connect to console run the following command:" TEXT
      verbose_message "" TEXT
      verbose_message "sudo virsh start ${iso['name']} ; sudo virsh console ${iso['name']}" TEXT
    fi
  fi
}

# Function: check_kvm_network
#
# Check KVM network

check_kvm_network () {
  if [ "${os['name']}" = "Darwin" ]; then
    bridge_test=$( virsh net-list --all |grep -c "${iso['bridge']}" )
  else
    bridge_test=$( sudo virsh net-list --all |grep -c "${iso['bridge']}" )
  fi
  if [ "${bridge_test}" = "0" ]; then
    warning_message "KVM network ${iso['bridge']} does not exist"
    do_exit
  fi
}

# Function: delete_kvm_vm
#
# Delete a KVM VM

delete_kvm_vm () {
  if [ -z "$( command -v virsh )" ]; then
    install_required_kvm_packages
  fi
  if [ "${options['testmode']}" = "false" ]; then
    iso['status']=$( virsh list --all |grep -c "shut off" )
    if [ "${os['name']}" = "Darwin" ]; then
      if [ "${iso['status']}" = "0" ]; then
        information_message "Stopping KVM VM ${iso['name']}"
        execute_command "virsh -c \"qemu:///session\" destroy ${iso['name']} 2> /dev/null"
      fi
      information_message "Deleting VM ${iso['name']}"
      execute_command "virsh -c \"qemu:///session\" undefine ${iso['name']} --nvram 2> /dev/null"
    else
      if [ "${iso['status']}" = "0" ]; then
        information_message "Stopping KVM VM ${iso['name']}"
        execute_command "sudo virsh destroy ${iso['name']} 2> /dev/null"
      fi
      information_message "Deleting VM ${iso['name']}"
      execute_command "sudo virsh undefine ${iso['name']} --nvram 2> /dev/null"
    fi
  fi
}

# Function: list_kvm_vm
#
# List KVM VMs

list_kvm_vm () {
  if [ -z "$( command -v virsh )" ]; then
    install_required_kvm_packages
  fi
  if [ "${os['name']}" = "Darwin" ]; then
    virsh list --all
  else
    sudo virsh list --all
  fi
}
