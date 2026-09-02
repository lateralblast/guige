![Cat with shield](https://raw.githubusercontent.com/lateralblast/guige/master/guige.jpg)

GUIGE
-----

Generic Ubuntu ISO Generation Engine

A guige (/ɡiːʒ/, /ɡiːd͡ʒ/) is a long strap, typically made of leather,
used to hang a shield on the shoulder or neck when not in use.

Version
-------

Current version: 4.7.7

License
-------

CC BY-SA: https://creativecommons.org/licenses/by-sa/4.0/

Fund me here: https://ko-fi.com/richardatlateralblast

Introduction
------------

This script provides a wrapper for the Ubuntu ISO creation process.
I wrote this as I didn't want to have to install and use Cubic or a similar GUI point and click tool to create an ISO.
I wanted to be able to automate the process.

To speed up the running of the script, I've disabled the package check running each time,
so the first time you get the script, you should run the package check, e.g.

```
./guige.sh --action installrequiredpackages
```

Features
--------

The script has the following features/capabilites:

- Import a an existing custom cloud-init config file
- Add packages to the ISO so that they can be installed without needing network
- Do ZFS based root installs
- Pass parameters to the install via the grub boot command line
- Install to the first SCSI/NVME disk by default
- Configure the first network with link by default

Status
------

Current status:

- The code is currently in the process of being cleaned up
  - ZFS root has been tested and currently works
  - btrfs root has been tested and currently works
  - xfs root has been tested and currently works
  - I'm working on a more complex ZFS storage configuration, but it is not currently working
    - The basic default configuration is working
- Default mode is UEFI with ZFS and LVM install options
- BIOS ISO does not support ZFS
- BIOS ISO mode will build installer with only LVM install
- I've noticed some race conditions in the Ubuntu installer where the installer will crash sometimes and not others
  - I'm yet to determine what causes this race condition
  - Simplifying storage configurations appears to help

Documentation
-------------

Further Documentation is available in the Wiki:

https://github.com/lateralblast/modest/wiki

Links to documentation/resources:

- [Command Line Examples](https://github.com/lateralblast/guige/wiki/Examples)
- [Usage Information](https://github.com/lateralblast/guige/wiki/Usage)
- [Grub Command Line Processing](https://github.com/lateralblast/guige/wiki/Grub)
- [Prerequisites](https://github.com/lateralblast/guige/wiki/Prerequisites)
- [Manual Process Behind Creating An ISO](https://github.com/lateralblast/guige/wiki/Process)

Todo
----

Things I plan to do:

- Get ZFS root to work with BIOS based installs (currently ZFS root only works with EFI based installs)

Help
----

```

Usage: guige --action [action] --options [options]

--allowpassword			          Allow password access via SSH
--allowservice			          Allow Services
--arch				                Architacture
--autoinstalldir		          Directory where autoinstall config files are stored on ISO
--basedir			                Base directory for script to do work
--bios				                BIOS boot type
--blacklist			              Block kernel module(s)
--bmcip				                BMC/iDRAC IP
--bootloader			            Boot Loader Location
--bootserverfile			        Boot sever file
--bootserverip			          Bootserver IP
--bootsize			              Boot partition size
--boottype			              Boot type
--build				                Type of ISO to build
--builddockerconfig		        Build Docker config
--bridge			                Bridge name
--bridges			                Bridge names
--checkdocker			            Check Docker
--checkshellcheck		          Shellcheck script
--checkworkdir			          Check work directories
--chrootpackages		          List of packages to add to ISO
--cidr				                CIDR
--cidrs				                CIDRs
--codename			              Release codename
--ipmicommand			            IPMI command
--compression			            Compression algorithm
--confdef			                Force confdef
--confnew			                Force confnew
--country			                Country
--cpus				                Number of CPUs
--createansible			          Create ansible
--createautoinstall		        Create autoinstall
--createcivm			            Create cloud-init based VM
--createdockeriso		          Create ISO using docker
--createdockerisoandsquashfs  Create ISO and update squashfs using docker
--createexport			          Create export
--createiso			              Create ISO
--createisoandsquashfs		    Create ISO and update squashfs
--createisovm			            Create ISO based VM
--debug				                Set debug flag (set -x)
--delete			                Remove previously created files
--deletecivm			            Delete cloud-init based VM
--deleteisovm			            Delete ISO based VM
--depends			                Force depends
--dhcp				                DHCP network configuration
--disableservice		          Disable service(s)
--disk				                Boot Disk devices
--diskfile			              Disk file
--diskserial			            Disk serial
--disksize			              Disk size
--diskwwn			                Disk WWN
--dns				                  DNS server IP
--dnsoptions			            DNS Options
--dockerworkdir			          Disk WWN
--efi				                  EFI boot type
--enableservice			          Enable service(s)
--fallback			              Installation fallback
--firewall			              Firewall
--firstboot			              Enable firstboot
--firstoption			            First menu option (e.g. grub menu)
--gateway			                Gateway IP
--gecos				                User GECOS field
--getiso			                Get ISO
--groups			                Groups to add user to
--grubfile			              Import grub file
--grubmenu			              Import grub menu
--grubtimeout			            Grub timeout
--grubparseall			          Parse grub for all parameters
--grubcidr			              Pass CIDR to config from grub boot command
--grubdisk			              Pass disk to config from grub boot command
--grubdns			                Pass nameserver to config from grub boot command
--grubgateway			            Pass gateway to config from grub boot command
--grubhostname			          Pass hostname to config from grub boot command
--grubip			                Pass IP to config from grub boot command
--grubkernel			            Pass kernel package to config from grub boot command
--grublocale			            Pass locale to config from grub boot command
--grublayout			            Pass keyboard layout to config from grub boot command
--grubnic			                Pass NIC to config from grub boot command
--grubpassword			          Pass password to config from grub boot command
--grubrealname			          Pass realname to config from grub boot command
--grubusername			          Pass username to config from grub boot command
--help				                Print help
--hostname			              Hostname
--inputci			                Import Cloud Image
--inputfile			              Import ISO/file
--ipmi				                Connect to BMC/iDRAC via IPMI
--installmode			            Install mode
--installmount			          Where the install mounts the CD during install
--installpassword		          Temporary install password for remote access during install
--installsource			          Install source
--installusername		          Install user
--ip				                  IP addresses
--ips				                  IP address
--isolinuxfile			          Import isolinux file
--kernel			                Kernel to install
--kernelargs			            Kernel arguments
--kernelserialargs		        Kernel serial arguments
--kvm				                  Install KVM packages
--vmiso				                KVM/VM Import ISO/file
--volid				                ISO Volume ID
--layout			                Keyboard layout
--lcall				                LC_ALL
--listswitches			          List switches
--listvm			                List VMs
--locale			                Local
--lvname			                Logical Volume Name
--name				                VM name
--netmask			                Netmask
--nfs				                  Use NFS for boot server URL
--nic				                  NIC to use for installation
--nics				                NICs to use for installation
--oeminstall			            OEM Install
--oldinstaller			          Use old installer
--oldinputfile			          Old release ISO
--oldisourl			              Old ISO URL
--oldrelease			            Old release
--onboot			                Enable network on boot
--outputci			              Output CI file
--outputfile			            Output ISO file
--overwrite			              Force overwrite
--packages			              Additional packages to install
--password			              Password
--passwordalgorithm		        Password Algorithm
--pesize			                PE size
--postinstall			            Import post install script
--prefix			                Output file name prefix
--preworkdir			            Docker work directory
--printdockerconfig		        Print Docker config
--printenv			              Print environment variables
--pvname			                Physical Volume Name
--ram				                  RAM size
--realname			              User real name field
--release			                OS release
--releasename			            OS releasename
--requiredpackages		        Required Packages
--requireddockerpackages	    Required Packages
--rootsize			              Root volume size
--runracadm			              Run racadm
--racadmcommand			          RACADM command
--search			                Search output for value
--searchdomain			          Search domain
--selinux			                SELinux Mode
--serialport			            Serial port
--serialportaddress		        Serial port address
--serialportspeed		          Serial port speed
--shell				                User shell
--smb				                  Use SMB for boot server URL
--sourceid			              Source ID
--squashfsfile			          Squashfs file
--sshkey			                SSH key
--sshkeyfile			            SSH key file
--static			                Static IP configuration
--strict			                Enable strict mode
--sudoers			                Sudoers entry
--suffix			                Output file name suffix
--swap				                Swap device
--swapsize			              Swap size
--targetmount			            Install target
--timezone			              Timezone
--type				                VM type
--updates			                Updates to install
--autoinstallfile		          Import autoinstall config file
--username			              Username
--usage				                Usage information
--usesshpass			            Use SSH Pass
--url				                  ISO URL
--verbose			                Verbose output
--version			                Display version
--vfio				                VM type
--vgname			                Volume Group Name
--volumemanager			          Volumemanager(s)
--whitelist			              Allow/load additional kernel modules(s)
--workdir			                Work directory
--zfsfilesystems		          Additional ZFS filesystems
--zfsroot			                ZFS root name

```

Thanks
------

Thanks to Mark Lane for testing, suggestions, etc.
