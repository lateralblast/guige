# Function: check_kvm_vm_existd
# 
# Check if KVM VM exists

check_kvm_vm_exists () {
  if [ "$OS_NAME" = "Darwin" ]; then
    KVM_TEST=$(virsh list --all |awk '{ print $2 }' |grep "^$VM_NAME")
  else
    KVM_TEST=$(sudo virsh list --all |awk '{ print $2 }' |grep "^$VM_NAME")
  fi
  if [ "$KVM_TEST" = "$VM_NAME" ]; then
    warning_message "KVM VM $VM_NAME exists"
    VM_EXISTS="true"
  fi
}

# Function: check_kvm_user
#
# Check user KVM permissions

check_kvm_user () {
  KVM_GROUPS="kvm libvirt libvirt-qemu libvirt-dnsmasq"
  for KVM_GROUP in "$KVM_GROUPS"; do
    GROUP_MEMBERS=$( cat /etc/group |grep "^$KVM_GROUP" |cut -f2 -d: ) 
    if [ ! -z "$GROUP_MEMBERS" ]; then
      if ! [[ "$KVM_GROUP" =~ "$USER" ]]; then
        sudo usermod -a -G $KVM_GROUP $USER
      fi
    fi
  done
}

# Function: create_kvm_vm
#
# Create a KVM VM for testing an ISO

create_kvm_vm () {
  if [ -z "$( command -v virsh )" ]; then
    install_required_packages  
  fi
  check_kvm_user
  if [ "$OS_NAME" = "Darwin" ]; then
    VIRT_DIR="/opt/homebrew/var/lib/libvirt"
    QEMU_VER=$( brew info qemu --json |jq -r ".[0].versions.stable" )
    VARS_FILE="/opt/homebrew/Cellar/qemu/$QEMU_VER/share/qemu/edk2-arm-vars.fd"
    BIOS_FILE="/opt/homebrew/Cellar/qemu/$QEMU_VER/share/qemu/edk2-aarch64-code.fd"
    QEMU_ARCH="aarch64"
    QEMU_EMU="/opt/homebrew/bin/qemu-system-aarch64"
    DOM_TYPE="hvf"
    MACHINE="virt-8.2"
    VIDEO="vga"
    SERIAL="system-serial"
    INPUT_BUS="usb"
    IF_TYPE="user"
    CD_BUS="scsi"
  else
    VIRT_DIR="/var/lib/libvirt"
    QEMU_VER=$( qemu-system-amd64 --version |head -1 |awk '{print $4}' |awk -F"." '{print $1"."$2}' )
    if [ "$DO_SECURE_BOOT" = "true" ]; then
      VARS_FILE="/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
      BIOS_FILE="/usr/share/OVMF/OVMF_CODE_4M.ms.fd"
    else
      VARS_FILE="/usr/share/OVMF/OVMF_VARS.fd"
      BIOS_FILE="/usr/share/OVMF/OVMF_CODE.fd"
    fi
    QEMU_ARCH="x86_64"
    QEMU_EMU="/usr/bin/qemu-system-x86_64"
    DOM_TYPE="kvm"
    MACHINE="pc-q35-$QEMU_VER"
    VIDEO="qxl"
    SERIAL="isa-serial"
    INPUT_BUS="ps2"
    IF_TYPE="network"
    CD_BUS="sata"
  fi
  if [ "$ISO_OS_NAME" = "ubuntu" ]; then
    OS_INFO_SITE="ubuntu.com"
  else
    OS_INFO_SITE="rockylinux.org"
  fi
  QEMU_DIR="$VIRT_DIR/qemu"
  QEMU_MAC=$( printf '52:54:00:%02X:%02X:%02X\n' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] )
  NVRAM_DIR="$QEMU_DIR/nvram"
  NVRAM_FILE="$NVRAM_DIR/${VM_NAME}_VARS.fd"
  IMAGE_DIR="$VIRT_DIR/images"
  VM_DISK="$WORK_DIR/$VM_NAME.qcow2"
  if ! [ -f "$BIOS_FILE" ]; then
    BIOS_FILE="/usr/share/edk2/x64/OVMF_CODE.fd"
    VARS_FILE="/usr/share/edk2/x64/OVMF_VARS.fd"
  fi
  if ! [ -f "$BIOS_FILE" ]; then
    TEMP_VERBOSE_MODE="true"
    warning_message "Could not find BIOS file"
    exit
  fi
  information_message "Creating VM disk $VM_DISK"
  execution_message "sudo qemu-img create -f qcow2 $VM_DISK $VM_SIZE"
  if [ "$TEST_MODE" = "false" ]; then
    if [ "$OS_NAME" = "Darwin" ]; then
      qemu-img create -f qcow2 "$VM_DISK" "$VM_SIZE"
    else
      sudo qemu-img create -f qcow2 "$VM_DISK" "$VM_SIZE"
    fi
  fi
  information_message "Generating VM config $XML_FILE"
  XML_FILE="/tmp/$VM_NAME.xml"
  echo "<domain type='$DOM_TYPE'>" > "$XML_FILE"
  echo "  <name>$VM_NAME</name>" >> "$XML_FILE"
  echo "  <metadata>" >> "$XML_FILE"
  echo "    <libosinfo:libosinfo xmlns:libosinfo=\"http://libosinfo.org/xmlns/libvirt/domain/1.0\">" >> "$XML_FILE"
  echo "      <libosinfo:os id=\"http://$OS_INFO_SITE/$ISO_OS_NAME/$ISO_MAJOR_RELEASE.$ISO_MINOR_RELEASE\"/>" >> "$XML_FILE"
  echo "    </libosinfo:libosinfo>" >> "$XML_FILE"
  echo "  </metadata>" >> "$XML_FILE"
  echo "  <memory unit='KiB'>$VM_RAM</memory>" >> "$XML_FILE"
  echo "  <currentMemory unit='KiB'>$VM_RAM</currentMemory>" >> "$XML_FILE"
  echo "  <vcpu placement='static'>$VM_CPUS</vcpu>" >> "$XML_FILE"
  echo "  <resource>" >> "$XML_FILE"
  echo "    <partition>/machine</partition>" >> "$XML_FILE"
  echo "  </resource>" >> "$XML_FILE"
  if [ "$ISO_BOOT_TYPE" = "bios" ]; then
    echo "  <os>" >> "$XML_FILE"
    echo "    <type arch='$QEMU_ARCH' machine='$MACHINE'>hvm</type>" >> "$XML_FILE"
  else
#    echo "  <os>" >> "$XML_FILE"
    echo "  <os firmware='efi'>" >> "$XML_FILE"
    echo "    <type arch='$QEMU_ARCH' machine='$MACHINE'>hvm</type>" >> "$XML_FILE"
    echo "    <firmware>" >> "$XML_FILE"
    if [ "$DO_SECURE_BOOT" = "true" ]; then
      echo "      <feature enabled='yes' name='enrolled-keys'/>" >> "$XML_FILE"
      echo "      <feature enabled='yes' name='secure-boot'/>" >> "$XML_FILE"
      echo "    </firmware>" >> "$XML_FILE"
      echo "    <loader readonly='yes' secure='yes' type='pflash'>$BIOS_FILE</loader>" >> "$XML_FILE"
      echo "    <nvram template='$VARS_FILE'>$NVRAM_FILE</nvram>" >> "$XML_FILE"
    else
      echo "      <feature enabled='no' name='enrolled-keys'/>" >> "$XML_FILE"
      echo "      <feature enabled='no' name='secure-boot'/>" >> "$XML_FILE"
      echo "    </firmware>" >> "$XML_FILE"
      echo "    <loader readonly='yes' type='pflash'>$BIOS_FILE</loader>" >> "$XML_FILE"
      echo "    <nvram template='$VARS_FILE'>$NVRAM_FILE</nvram>" >> "$XML_FILE"
    fi
    echo "    <bootmenu enable='yes'/>" >> "$XML_FILE"
  fi
  echo "  </os>" >> "$XML_FILE"
  echo "  <features>" >> "$XML_FILE"
  if [ "$OS_NAME" = "Darwin" ]; then
    echo "    <acpi/>" >> "$XML_FILE"
    echo "    <gic version='2'/>" >> "$XML_FILE"
    echo "  </features>" >> "$XML_FILE"
    echo "  <cpu mode='custom' match='exact' check='partial'>" >> "$XML_FILE"
    echo "    <model fallback='forbid'>cortex-a57</model>" >> "$XML_FILE"
    echo "  </cpu>" >> "$XML_FILE"
    echo "  <clock offset='utc'/>" >> "$XML_FILE"
    echo "  <on_poweroff>destroy</on_poweroff>" >> "$XML_FILE"
    echo "  <on_reboot>restart</on_reboot>" >> "$XML_FILE"
    echo "  <on_crash>destroy</on_crash>" >> "$XML_FILE"
  else
    echo "    <acpi/>" >> "$XML_FILE"
    echo "    <apic/>" >> "$XML_FILE"
    echo "    <vmport state='off'/>" >> "$XML_FILE"
    echo "  </features>" >> "$XML_FILE"
    echo "  <cpu mode='host-passthrough' check='none' migratable='on'/>" >> "$XML_FILE"
    echo "  <clock offset='utc'>" >> "$XML_FILE"
    echo "    <timer name='rtc' tickpolicy='catchup'/>" >> "$XML_FILE"
    echo "    <timer name='pit' tickpolicy='delay'/>" >> "$XML_FILE"
    echo "    <timer name='hpet' present='no'/>" >> "$XML_FILE"
    echo "  </clock>" >> "$XML_FILE"
    echo "  <on_poweroff>destroy</on_poweroff>" >> "$XML_FILE"
    echo "  <on_reboot>restart</on_reboot>" >> "$XML_FILE"
    echo "  <on_crash>destroy</on_crash>" >> "$XML_FILE"
    echo "  <pm>" >> "$XML_FILE"
    echo "    <suspend-to-mem enabled='no'/>" >> "$XML_FILE"
    echo "    <suspend-to-disk enabled='no'/>" >> "$XML_FILE"
    echo "  </pm>" >> "$XML_FILE"
  fi
  echo "  <devices>" >> "$XML_FILE"
  echo "    <emulator>$QEMU_EMU</emulator>" >> "$XML_FILE"
  echo "    <disk type='file' device='disk'>" >> "$XML_FILE"
  echo "      <driver name='qemu' type='qcow2' discard='unmap'/>" >> "$XML_FILE"
  echo "      <source file='$VM_DISK'/>" >> "$XML_FILE"
  echo "      <target dev='vda' bus='virtio'/>" >> "$XML_FILE"
#  echo "      <boot order='2'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </disk>" >> "$XML_FILE"
  if [ "$OS_NAME" = "Darwin" ]; then
    echo "    <disk type='file' device='cdrom'>" >> "$XML_FILE"
    echo "      <driver name='qemu' type='raw'/>" >> "$XML_FILE"
    echo "      <source file='$VM_ISO'/>" >> "$XML_FILE"
    echo "      <backingStore/>" >> "$XML_FILE"
    echo "      <target dev='sda' bus='$CD_BUS'/>" >> "$XML_FILE"
    echo "      <readonly/>" >> "$XML_FILE"
#    echo "      <boot order='1'/>" >> "$XML_FILE"
    echo "      <alias name='scsi0-0-0-0'/>" >> "$XML_FILE"
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> "$XML_FILE"
    echo "    </disk>" >> "$XML_FILE"
    echo "    <controller type='scsi' index='0' model='virtio-scsi'>" >> "$XML_FILE"
    echo "      <alias name='scsi0'/>" >> "$XML_FILE"
    echo "      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>" >> "$XML_FILE"
    echo "    </controller>" >> "$XML_FILE"
    echo "    <controller type='virtio-serial' index='0'>" >> "$XML_FILE"
    echo "      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>" >> "$XML_FILE"
    echo "    </controller>" >> "$XML_FILE"
  else
    echo "    <disk type='file' device='cdrom'>" >> "$XML_FILE"
    echo "      <driver name='qemu' type='raw'/>" >> "$XML_FILE"
    echo "      <source file='$VM_ISO'/>" >> "$XML_FILE"
    echo "      <target dev='sda' bus='$CD_BUS'/>" >> "$XML_FILE"
    echo "      <readonly/>" >> "$XML_FILE"
    echo "      <boot order='1'/>" >> "$XML_FILE"
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> "$XML_FILE"
    echo "    </disk>" >> "$XML_FILE"
    echo "    <controller type='virtio-serial' index='0'>" >> "$XML_FILE"
    echo "      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>" >> "$XML_FILE"
    echo "    </controller>" >> "$XML_FILE"
  fi
  echo "    <controller type='usb' index='0' model='qemu-xhci' ports='15'>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='0' model='pcie-root'/>" >> "$XML_FILE"
  echo "    <controller type='pci' index='1' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='1' port='0x10'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='2' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='2' port='0x11'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='3' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='3' port='0x12'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='4' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='4' port='0x13'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='5' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='5' port='0x14'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='6' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='6' port='0x15'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='7' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='7' port='0x16'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='8' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='8' port='0x17'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='9' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='9' port='0x18'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0' multifunction='on'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='10' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='10' port='0x19'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x1'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='11' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='11' port='0x1a'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x2'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='12' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='12' port='0x1b'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x3'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='13' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='13' port='0x1c'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x4'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='14' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='14' port='0x1d'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x5'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='sata' index='0'>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <interface type='$IF_TYPE'>" >> "$XML_FILE"
  echo "      <mac address='$QEMU_MAC'/>" >> "$XML_FILE"
  if [ ! "$OS_NAME" = "Darwin" ]; then
    echo "      <source network='default'/>" >> "$XML_FILE"
  fi
  echo "      <model type='virtio'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </interface>" >> "$XML_FILE"
  echo "    <serial type='pty'>" >> "$XML_FILE"
  echo "      <target type='$SERIAL' port='0'>" >> "$XML_FILE"
  if [ "$OS_NAME" = "Darwin" ]; then
    echo "        <alias name='$SERIAL'/>" >> "$XML_FILE"
  else
    echo "        <model name='$SERIAL'/>" >> "$XML_FILE"
  fi
  echo "      </target>" >> "$XML_FILE"
  echo "    </serial>" >> "$XML_FILE"
  echo "    <console type='pty'>" >> "$XML_FILE"
  echo "      <target type='serial' port='0'/>" >> "$XML_FILE"
  echo "    </console>" >> "$XML_FILE"
  echo "    <channel type='unix'>" >> "$XML_FILE"
  echo "      <target type='virtio' name='org.qemu.guest_agent.0'/>" >> "$XML_FILE"
  echo "      <address type='virtio-serial' controller='0' bus='0' port='1'/>" >> "$XML_FILE"
  echo "    </channel>" >> "$XML_FILE"
  echo "    <input type='tablet' bus='usb'>" >> "$XML_FILE"
  echo "      <address type='usb' bus='0' port='1'/>" >> "$XML_FILE"
  echo "    </input>" >> "$XML_FILE"
  echo "    <input type='mouse' bus='$INPUT_BUS'/>" >> "$XML_FILE"
  echo "    <input type='keyboard' bus='$INPUT_BUS'/>" >> "$XML_FILE"
  echo "    <sound model='ich9'>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>" >> "$XML_FILE"
  echo "    </sound>" >> "$XML_FILE"
  echo "    <video>" >> "$XML_FILE"
  if [ "$OS_NAME" = "Darwin" ]; then
    echo "      <model type='$VIDEO' vram='65536' heads='1' primary='yes'/>" >> "$XML_FILE"
  else
    echo "      <model type='$VIDEO' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>" >> "$XML_FILE"
  fi
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>" >> "$XML_FILE"
  echo "    </video>" >> "$XML_FILE"
  if [ ! "$OS_NAME" = "Darwin" ]; then
    echo "    <audio id='1' type='spice'/>" >> "$XML_FILE"
    echo "    <channel type='spicevmc'>" >> "$XML_FILE"
    echo "      <target type='virtio' name='com.redhat.spice.0'/>" >> "$XML_FILE"
    echo "      <address type='virtio-serial' controller='0' bus='0' port='2'/>" >> "$XML_FILE"
    echo "    </channel>" >> "$XML_FILE"
    echo "    <graphics type='spice' autoport='yes'>" >> "$XML_FILE"
    echo "      <listen type='address'/>" >> "$XML_FILE"
    echo "      <image compression='off'/>" >> "$XML_FILE"
    echo "    </graphics>" >> "$XML_FILE"
    echo "    <redirdev bus='usb' type='spicevmc'>" >> "$XML_FILE"
    echo "      <address type='usb' bus='0' port='2'/>" >> "$XML_FILE"
    echo "    </redirdev>" >> "$XML_FILE"
    echo "    <redirdev bus='usb' type='spicevmc'>" >> "$XML_FILE"
    echo "      <address type='usb' bus='0' port='3'/>" >> "$XML_FILE"
    echo "    </redirdev>" >> "$XML_FILE"
    echo "    <watchdog model='itco' action='reset'/>" >> "$XML_FILE"
  fi
  echo "    <memballoon model='virtio'>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </memballoon>" >> "$XML_FILE"
  echo "    <rng model='virtio'>" >> "$XML_FILE"
  echo "      <backend model='random'>/dev/urandom</backend>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </rng>" >> "$XML_FILE"
  echo "  </devices>" >> "$XML_FILE"
  echo "</domain>" >> "$XML_FILE"
  print_file "$XML_FILE"
  information_message "Importing VM config $XML_FILE"
  if [ "$TEST_MODE" = "false" ]; then
    if [ "$OS_NAME" = "Darwin" ]; then
      execution_message "virsh define $XML_FILE"
      virsh define "$XML_FILE"
      verbose_message "To start the VM and connect to console run the following command:" TEXT
      verbose_message "" TEXT
      verbose_message "virsh start $VM_NAME ; virsh console $VM_NAME" TEXT
    else
      execution_message "sudo virsh define $XML_FILE"
      sudo virsh define "$XML_FILE"
      verbose_message "To start the VM and connect to console run the following command:" TEXT
      verbose_message "" TEXT
      verbose_message "sudo virsh start $VM_NAME ; sudo virsh console $VM_NAME" TEXT
    fi
  fi
}

# Function: delete_kvm_vm
#
# Delete a KVM VM

delete_kvm_vm () {
  if [ -z "$( command -v virsh )" ]; then
    install_required_packages  
  fi
  if [ "$TEST_MODE" = "false" ]; then
    if [ "$OS_NAME" = "Darwin" ]; then
      information_message "Stopping KVM VM $VM_NAME"
      execute_command "virsh -c \"qemu:///session\" destroy $VM_NAME"
      information_message "Deleting VM $VM_NAME"
      execute_command "virsh undefine $VM_NAME --nvram"
    else
      information_message "Stopping KVM VM $VM_NAME"
      execute_command "sudo virsh destroy $VM_NAME"
      information_message "Deleting VM $VM_NAME"
      execute_command "sudo virsh undefine $VM_NAME --nvram"
    fi
  fi
}

# Function: list_kvm_vm
#
# List KVM VMs

list_kvm_vm () {
  if [ -z "$( command -v virsh )" ]; then
    install_required_packages  
  fi
  if [ "$OS_NAME" = "Darwin" ]; then
    virsh list --all
  else
    sudo virsh list --all
  fi
}
