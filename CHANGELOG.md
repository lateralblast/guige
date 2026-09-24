# Changelog

All notable changes to the `guige` project are documented in this file.
Dates are in `YYYY-MM-DD` format; entries are derived from the project's original `guige.changelog` file.

## [4.9.9] - 2026-09-24
- Fixed `get_switches` treating any case-arm line containing a bare `*` glob (e.g. `--bmcpass*`) as the end of the switch list, which silently dropped `bmcusername`, `bmcpassword`, `bootserverprotocol`, `bootserverusername`, `bootserverpassword`, `includeusername`, `includepassword`, `checkipmitool`, `checkracadm`, `installrequiredpackages`, `dryrun`, `action`, `option`, `deleteiso`, `listisos`, `listallisos` and `listargs` from ever getting their defaults applied
- Fixed switch names extracted from single-pattern wildcard case arms (e.g. `--action*)`) retaining a stray trailing `*`

## [4.9.8] - 2026-09-24
- Added missing `racadm_powercycle` function so `--action powercycle` works instead of failing with "command not found"

## [4.9.7] - 2026-09-23
- Fixed script only working when run from the repo directory (module/file paths now resolve from the script's real location instead of the current working directory)

## [4.9.6] - 2026-09-22
- Bug fixes

## [4.9.5] - 2026-09-22
- Updated shellcheck message

## [4.9.4] - 2026-09-22
- Cleaned up help information

## [4.9.3] - 2026-09-22
- Updated Ubuntu 26.10 support

## [4.9.2] - 2026-09-21
- Fixed ISO filename generation

## [4.9.1] - 2026-09-19
- Fixed noansible switch

## [4.9.0] - 2026-09-19
- Added IP address checking

## [4.8.9] - 2026-09-18
- Added CIDR to ISO file name

## [4.8.8] - 2026-09-18
- More fixes for delete ISO option

## [4.8.7] - 2026-09-18
- Added delete option for ISO files

## [4.8.6] - 2026-09-18
- Updated how arguments are passed to docker

## [4.8.5] - 2026-09-11
- Cleaned up subiquity config

## [4.8.4] - 2026-09-10
- More fixes for ISO naming

## [4.8.3] - 2026-09-10
- Fixed ISO naming

## [4.8.2] - 2026-09-10
- Fixed nodhcpnics processing

## [4.8.1] - 2026-09-08
- Added code to extract bootserverip from booturl if needed

## [4.8.0] - 2026-09-08
- Added booturl switch

## [4.7.9] - 2026-09-07
- Added nodhcpnic and nodhcpnics options

## [4.7.8] - 2026-09-04
- Added output filename option switches for username and password

## [4.7.7] - 2026-09-02
- Added powercycle and other racadm actions

## [4.7.6] - 2026-09-02
- Updated documentation

## [4.7.5] - 2026-09-02
- Fixed ssh host key checking

## [4.7.4] - 2026-09-01
- Shellcheck compliance fixes

## [4.7.3] - 2026-09-01
- Added inital code for ipmitool integration

## [4.7.2] - 2026-08-31
- Improvements to switch processing

## [4.7.1] - 2026-08-30
- More improvements to list ISO function

## [4.7.0] - 2026-08-30
- Improvements to list ISO function

## [4.6.9] - 2026-08-29
- Updated Ubuntu release to 26.04.1

## [4.6.8] - 2026-08-28
- Fixed dry run option

## [4.6.7] - 2026-08-28
- Added code to save arguments to an output file

## [4.6.6] - 2026-08-28
- Use sshpass when racadm is not available

## [4.6.5] - 2026-08-28
- Fixed racadm

## [4.6.4] - 2026-08-27
- Fixed dryrun option

## [4.6.3] - 2026-08-26
- Added more option switches to command line argument processing

## [4.6.2] - 2026-08-26
- Started adding option switches to command line argument processing

## [4.6.1] - 2026-08-26
- Added more action switches to command line argument processing

## [4.6.0] - 2026-08-26
- Cleaned up default CIDR and default Subnet mask processing

## [4.5.9] - 2026-08-26
- Added check for bash version

## [4.5.8] - 2026-08-26
- Started adding action switches to command line argument processing

## [4.5.7] - 2026-08-23
- Added idrac switch alternatives for bmc switches

## [4.5.6] - 2026-08-21
- Added bootserverprotocol switch

## [4.5.5] - 2026-08-21
- Cleaned up switch processing

## [4.5.4] - 2026-08-21
- Added code to cleanup disk and NIC device names

## [4.5.3] - 2026-05-11
- Bug fixes and improvements

## [4.5.2] - 2026-04-24
- Fixed previous build package cleanup

## [4.5.1] - 2026-04-24
- Fixed output file name generation when parameter values are true or false

## [4.5.0] - 2026-04-24
- Added initial support for Ubuntu 26.04

## [4.4.9] - 2026-04-24
- Fixed autoinstall parameter not being added to output filename

## [4.4.8] - 2025-11-28
- Clean up file name generation

## [4.4.7] - 2025-11-28
- Added shutdown to KVM destroy

## [4.4.6] - 2025-11-28
- Fixed KVM libvirt XML file generation

## [4.4.5] - 2025-11-27
- Bug fixes and improvements

## [4.4.4] - 2025-11-20
- Fixed dryrun option and added check for bridge

## [4.4.3] - 2025-11-20
- Added initial support for Ubuntu 26.04

## [4.4.2] - 2025-11-19
- Added check for xorriso

## [4.4.1] - 2025-11-19
- Set development release to 26.04

## [4.4.0] - 2025-08-01
- Updated blacklist/whitelist code

## [4.3.9] - 2025-07-31
- Added vfio switch and option

## [4.3.8] - 2025-07-24
- Bug fixes and improvements

## [4.3.7] - 2025-07-24
- Re-added ubuntu-advantage-tools to package list after fixing issues with install

## [4.3.6] - 2025-07-24
- Fixed issues with HWE support

## [4.3.5] - 2025-07-24
- Removed ubuntu-advantage-tools from package list due to issues with install

## [4.3.4] - 2025-07-24
- Improved HWE support

## [4.3.3] - 2025-07-23
- Fixed ISO URL determination

## [4.3.2] - 2025-07-23
- Improved docker command line parsing

## [4.3.1] - 2025-07-23
- Add function to printenv inside docker container and exit

## [4.3.0] - 2025-07-23
- Removed package check from running every time to speed up script

## [4.2.9] - 2025-07-23
- Fixed docker required package list

## [4.2.8] - 2025-07-23
- Added action to print and build docker config

## [4.2.7] - 2025-07-23
- Added sudo to docker package install list

## [4.2.6] - 2025-07-22
- Updated docker OS version to fix issues with squashfs

## [4.2.5] - 2025-07-22
- Fixed docker output file determination

## [4.2.4] - 2025-07-22
- Improved input file determination

## [4.2.3] - 2025-07-21
- Fixed unpacksquashfs check

## [4.2.2] - 2025-07-19
- Added code to update filename when multiple interfaces are specified

## [4.2.1] - 2025-07-18
- Updated file namne output for multiple NIC support

## [4.2.0] - 2025-07-18
- Bug fixes for muiltiple NIC support

## [4.1.9] - 2025-07-18
- Added more support for bridges and multiple NICs

## [4.1.8] - 2025-07-17
- Fixed help routine

## [4.1.7] - 2025-07-17
- Fixed bug cloud init bridge config

## [4.1.6] - 2025-07-17
- Fixed bug with serial kernel args check

## [4.1.5] - 2025-07-17
- Added bridge to file name

## [4.1.4] - 2025-07-17
- Added bridge switch

## [4.1.3] - 2025-07-10
- Fixed required packages list for non Linux platforms

## [4.1.2] - 2025-07-10
- Added resolver config update to install script

## [4.1.1] - 2025-07-10
- Improved check for required packages

## [4.1.0] - 2025-07-10
- Added code to ignore environment tests for version and help switches

## [4.0.9] - 2025-07-09
- Improved code to determine oututci

## [4.0.8] - 2025-07-09
- Improved code to determine inputci

## [4.0.7] - 2025-07-09
- Fixed output file determination

## [4.0.6] - 2025-07-09
- Fixed version switch

## [4.0.5] - 2025-05-23
- Improved determination of output file name

## [4.0.4] - 2025-05-22
- Added support for Ubuntu 25.10 server

## [4.0.3] - 2025-05-09
- Improved Volume ID determination

## [4.0.2] - 2025-05-09
- Added Ubuntu 25.10 desktop support

## [4.0.1] - 2025-05-05
- Added path to openssl command

## [4.0.0] - 2025-04-24
- Updated usage information

## [3.9.9] - 2025-04-23
- Cleaned up options

## [3.9.8] - 2025-04-23
- Fixed switch processing

## [3.9.7] - 2025-04-23
- Fixed volid determination

## [3.9.6] - 2025-04-22
- Fixes based on shellcheck recommendations

## [3.9.5] - 2025-04-22
- Improved passing of command line parameters to docker

## [3.9.4] - 2025-04-22
- Fixed SSH key and docker work directory

## [3.9.3] - 2025-04-22
- Fixed passing of command line parameters to docker

## [3.9.2] - 2025-04-22
- Added support for non beta Ubuntu 25.04

## [3.9.1] - 2025-04-21
- Fixed realname

## [3.9.0] - 2025-04-21
- Fixed kernel args determination and application in subiquity

## [3.8.9] - 2025-04-21
- Fixed serial port information determination
- Fixed --boottype switch

## [3.8.8] - 2025-04-21
- Improved bootserverfile processing so it did not impact docker
- Updated switch processing

## [3.8.7] - 2025-04-20
- Cleanup of switches and options and how they are passed to docker

## [3.8.6] - 2025-04-20
- Added code to docker function to pass switches to docker

## [3.8.5] - 2025-04-20
- Add a function to get and list switches

## [3.8.4] - 2025-04-20
- Fixed issue with username not being passed to docker ISO build

## [3.8.3] - 2025-04-20
- Added grubparser to output ISO name

## [3.8.2] - 2025-04-20
- Added IP, CIDR, DNS and gateway to grubparser

## [3.8.1] - 2025-04-20
- Added kernel, layout and locale to grubparser

## [3.8.0] - 2025-04-20
- Updated documentation

## [3.7.9] - 2025-04-19
- Fixed grubparser

## [3.7.8] - 2025-04-19
- Added realname to grub parser

## [3.7.7] - 2025-04-19
- Added switch to parse all applicable values from grub boot command

## [3.7.6] - 2025-04-19
- Added switches for passing value to grub boot command

## [3.7.5] - 2025-04-19
- Fixes for grub parsing

## [3.7.4] - 2025-04-19
- Added inital support for passing parametes to install via grub boot command

## [3.7.3] - 2025-04-17
- Fixed issue with additional arguments not being added to docker script

## [3.7.2] - 2025-04-17
- Added docker_exit function to help with testing

## [3.7.1] - 2025-04-17
- Fixes for ISO URL determination

## [3.7.0] - 2025-04-14
- Fixed iproute2 package check

## [3.6.9] - 2025-04-14
- Improved handling for 25.04

## [3.6.8] - 2025-04-13
- Documentation update

## [3.6.7] - 2025-04-13
- Fixed work directory in docker mode

## [3.6.6] - 2025-04-13
- Added docker test

## [3.6.5] - 2025-04-13
- Documentation update

## [3.6.4] - 2025-04-12
- Added swap partition option to LVM based storage

## [3.6.3] - 2025-04-12
- Fixed LVM based storage stanza

## [3.6.2] - 2025-04-12
- Fixed ZFS storage stanza

## [3.6.1] - 2025-04-12
- Fixed earlypackages and latepackages options

## [3.6.0] - 2025-04-12
- Improved chroot process

## [3.5.9] - 2025-04-11
- Format fixes

## [3.5.8] - 2025-04-11
- Added check for route

## [3.5.7] - 2025-04-11
- Added ipcalc to required packages

## [3.5.6] - 2025-04-11
- Added support for development releases of Ubuntu in release determination

## [3.5.5] - 2025-04-10
- Ubuntu installer bug fixes

## [3.5.4] - 2025-04-10
- Bug fixes for custom install

## [3.5.3] - 2025-04-10
- Added custom install file support to docker ISO creation

## [3.5.2] - 2025-04-10
- Fixed volumemanager code for grubmenu creation

## [3.5.1] - 2025-04-10
- Added SSH key support to docker ISO creation

## [3.5.0] - 2025-04-10
- Fixed disk entry

## [3.4.9] - 2025-04-10
- Fixed grub timeout

## [3.4.8] - 2025-04-10
- Fixed kernel args parameter

## [3.4.7] - 2025-04-09
- Fixed volumemanager list handling

## [3.4.6] - 2025-04-09
- Fixed docker command

## [3.4.5] - 2025-04-09
- Added code to output parameter and option value

## [3.4.4] - 2025-04-09
- Fixed keyboard layout

## [3.4.3] - 2025-04-08
- Fixed live-server ISO URL determination

## [3.4.2] - 2025-04-08
- Added release switch to docker script

## [3.4.1] - 2025-04-08
- Updated documentation

## [3.4.0] - 2025-04-08
- Added iproute2 to required packages

## [3.3.9] - 2025-04-08
- More code cleanup

## [3.3.8] - 2025-04-07
- Improved switches processing

## [3.3.7] - 2025-04-07
- Cleaned up defaults

## [3.3.6] - 2025-04-06
- Added code to handle multiple actions

## [3.3.5] - 2025-04-06
- Fixed default release determination

## [3.3.4] - 2025-04-06
- Updated CIDR determination

## [3.3.3] - 2025-04-06
- Updated options processing

## [3.3.2] - 2025-04-05
- Replaced general help function

## [3.3.1] - 2025-04-05
- Formatting fixes

## [3.3.0] - 2025-04-05
- More fixes based on shellcheck recommendations

## [3.2.9] - 2025-04-05
- Bug fixes

## [3.2.8] - 2025-04-05
- Fixed function to get CIDR from netmask

## [3.2.7] - 2025-04-05
- Code cleanup based on shellcheck suggestions

## [3.2.6] - 2025-04-05
- Bug fixes

## [3.2.5] - 2025-04-05
- Added shellcheck function

## [3.2.4] - 2025-04-04
- Bug fixes

## [3.2.3] - 2025-04-04
- More code cleanup

## [3.2.2] - 2025-04-04
- Bug fixes

## [3.2.1] - 2025-04-04
- Initial migration to new script template

## [3.2.0] - 2025-04-02
- More bug fixes

## [3.1.9] - 2025-04-01
- Bug fixes

## [3.1.8] - 2025-04-01
- Improved CIDR determination

## [3.1.7] - 2025-03-31
- Cleaned up output

## [3.1.6] - 2025-03-31
- Aligned variable names with options

## [3.1.5] - 2025-03-31
- Aligned variable names with actions

## [3.1.4] - 2025-03-31
- Aligned variable names with switches

## [3.1.3] - 2025-03-31
- Fixed btrfs config

## [3.1.2] - 2025-03-30
- Cleaned up volume managers determination

## [3.1.1] - 2025-03-30
- Cleaned up volume group naming determination

## [3.1.0] - 2025-03-30
- Fixed btrfs automated install

## [3.0.9] - 2025-03-30
- Updated SSH key handling

## [3.0.8] - 2025-03-30
- Updated file name determination to include volume managers

## [3.0.7] - 2025-03-29
- Initial documentation update

## [3.0.6] - 2025-03-28
- Updated daily release to 25.x

## [3.0.5] - 2025-03-28
- Cleaned up ISO release number determination/handling

## [3.0.4] - 2025-03-28
- Re-enabled boot from next volume on all releases

## [3.0.3] - 2025-03-28
- Fixes for ZFS root on server

## [3.0.2] - 2025-03-28
- Fixes for server and squashfs

## [3.0.1] - 2025-03-28
- Updated work directory determination

## [3.0.0] - 2025-03-28
- Added early and late flags for package installs

## [2.9.9] - 2025-03-28
- Added custom to generated ISO name for custom user-data and grub.cfg

## [2.9.8] - 2025-03-28
- Subiquity fixes

## [2.9.7] - 2025-03-27
- More fixes

## [2.9.6] - 2025-03-27
- Fixed squashfs

## [2.9.5] - 2025-03-27
- Added flag for multiple ZFS filesystems

## [2.9.4] - 2025-03-27
- Simplified ZFS config in subiquity due to install issues

## [2.9.3] - 2025-03-27
- Cleaned up lvm-auto

## [2.9.2] - 2025-03-27
- Turned squashfs operation code off by default

## [2.9.1] - 2025-03-25
- Impoved check for packages in ISO image

## [2.9.0] - 2025-03-25
- Fixed Arch/Endeavour package check

## [2.8.9] - 2025-03-24
- Fixed unbound variable bugs

## [2.8.8] - 2025-03-24
- Improved support for Ubuntu Desktop

## [2.8.7] - 2024-12-09
- Added code to determine CIDR and Netmask

## [2.8.6] - 2024-12-08
- Added support for Ubuntu 25.04

## [2.8.5] - 2024-08-20
- Fixed KVM config check

## [2.8.4] - 2024-08-19
- Updated code to get base CI file

## [2.8.3] - 2024-08-19
- Added code to get base CI file

## [2.8.2] - 2024-08-19
- Split out CI and ISO variables

## [2.8.1] - 2024-08-18
- Split out code to check KVM config into separate routine

## [2.8.0] - 2024-08-18
- Adjusted KVM VM creation to allow for cloud init VM creation

## [2.7.9] - 2024-08-13
- Fixed release number processing and volume manager selection

## [2.7.8] - 2024-08-13
- Fixed firstoption switch

## [2.7.7] - 2024-08-13
- Updated documentation

## [2.7.6] - 2024-08-13
- Cleaned up options

## [2.7.5] - 2024-08-13
- Added handler for empty SSH keys

## [2.7.4] - 2024-08-13
- Fixed serial config for KVM on MacOS x86

## [2.7.3] - 2024-08-12
- Fixed KVM VM creation of MacOS x86

## [2.7.2] - 2024-08-12
- Fixed routine to determine if VM exists

## [2.7.1] - 2024-08-12
- Fixed release version handling

## [2.7.0] - 2024-08-12
- Update filesystem defaults

## [2.6.9] - 2024-08-11
- Fixed release handling for major release numbers

## [2.6.8] - 2024-08-11
- Fixed package directory cleanup

## [2.6.7] - 2024-08-11
- Added code to set volume managers based on Ubuntu release

## [2.6.5] - 2024-08-01
- Improved SSH key determination

## [2.6.4] - 2024-08-01
- Updated documentation

## [2.6.3] - 2024-08-01
- Fixes for chroot script permissions

## [2.6.2] - 2024-08-01
- Improvements for squashfs mount

## [2.6.1] - 2024-08-01
- Improvements for ISO and squashfs unmount checks

## [2.6.0] - 2024-08-01
- Added strict switch

## [2.5.9] - 2024-08-01
- Added debug switch

## [2.5.8] - 2024-07-17
- Added -eu to shell

## [2.5.7] - 2024-05-28
- Added firstoption switch to set first choice in grub menu

## [2.5.6] - 2024-05-26
- Added compression option for btrfs

## [2.5.5] - 2024-05-25
- Some documentation updates

## [2.5.4] - 2024-05-25
- Added WWN and serial information to subiquity NVMe stanze

## [2.5.3] - 2024-05-25
- Added NVMe option

## [2.5.2] - 2024-05-24
- Added brtfs-compsize to installed packages

## [2.5.1] - 2024-05-24
- Some improvements to subiquity

## [2.5.0] - 2024-05-22
- Added handling for NVMe device naming

## [2.4.9] - 2024-05-22
- Added some handling for older/Intel versions of MacOS

## [2.4.8] - 2024-05-20
- Added better handling for release switch

## [2.4.7] - 2024-05-20
- Updated failback option

## [2.4.6] - 2024-05-20
- Cleaned up options

## [2.4.5] - 2024-05-20
- Fixed ZFS install on 22.04.3

## [2.4.4] - 2024-05-19
- Added refresh-install option

## [2.4.3] - 2024-05-16
- Improved output for ISO creation

## [2.4.2] - 2024-05-16
- Improved mount check for ISO

## [2.4.1] - 2024-05-16
- Updated docker version

## [2.4.0] - 2024-05-15
- Fixed module path when creating ISOs in docker

## [2.3.9] - 2024-05-15
- Fix for default arch on arm64

## [2.3.8] - 2024-05-15
- Bug fixes

## [2.3.7] - 2024-05-14
- Added updates switch

## [2.3.6] - 2024-05-14
- Initial support for Ubuntu 24.10

## [2.3.5] - 2024-05-13
- Added nochroot option

## [2.3.4] - 2024-05-12
- Added additional required packages

## [2.3.3] - 2024-05-10
- Added reorder_uefi

## [2.3.2] - 2024-05-09
- Added build type to VM name

## [2.3.1] - 2024-05-09
- Cleanup after running shellcheck

## [2.3.0] - 2024-05-09
- Some updates for 24.04

## [2.2.9] - 2024-05-09
- Bug fixes and improvements

## [2.2.8] - 2024-03-22
- Updates to kickstart creation

## [2.2.7] - 2024-03-21
- Added check that ISO is mounted

## [2.2.6] - 2024-03-20
- Bug fixes and improved handling of KVM XML generation

## [2.2.5] - 2024-03-20
- Added group check for KVM

## [2.2.4] - 2024-03-19
- Added handling for 22.04.3/4

## [2.2.3] - 2024-03-16
- Added code to import an external custom kickstart file

## [2.2.2] - 2024-03-15
- Updated KVM code to create Rocky Linux VMs

## [2.2.1] - 2024-03-15
- Bugfixes

## [2.2.0] - 2024-03-14
- Added kickstart ISO copy function

## [2.1.9] - 2024-03-14
- Updated kickstart file creation

## [2.1.8] - 2024-03-14
- Updated documentation

## [2.1.7] - 2024-03-14
- Added support to run ksvalidator if present

## [2.1.6] - 2024-03-10
- More kickstart support and bug fixes

## [2.1.5] - 2024-03-10
- More kickstart support

## [2.1.4] - 2024-03-09
- Added code to test kickstart file generation

## [2.1.3] - 2024-03-08
- Improved help/usage option

## [2.1.2] - 2024-03-07
- Removed short args/switches

## [2.1.1] - 2024-03-07
- Added handling for empty switches

## [2.1.0] - 2024-03-07
- Bug fixes

## [2.0.9] - 2024-03-07
- Split code into modules to help with size and editing

## [2.0.8] - 2024-03-06
- Started code for generating kickstart

## [2.0.7] - 2024-03-03
- Started splitting operations out to help with adding other Linux distributions

## [2.0.6] - 2024-03-03
- Fixed HWE kernel package addition

## [2.0.5] - 2024-03-02
- Updates and improvements

## [2.0.4] - 2024-03-01
- Updates and bug fixes

## [2.0.3] - 2024-03-01
- Fixed bug with custom user-date menu option

## [2.0.2] - 2024-03-01
- Added serial kernel arguments to install/trial menu option

## [2.0.1] - 2024-03-01
- Updates to cloud-init config generation

## [2.0.0] - 2024-02-28
- Fixed bug with VM ISO determination

## [1.9.9] - 2024-02-28
- Added function to list VMs

## [1.9.8] - 2024-02-27
- Fixed bugs and added support for QEMU VM on MacOS

## [1.9.7] - 2024-02-26
- Fixed bug with package install on MacOS

## [1.9.6] - 2024-02-26
- Added custom user-data option

## [1.9.5] - 2024-02-26
- Fixed bug with setting defaults

## [1.9.4] - 2024-02-25
- Bug fixes

## [1.9.3] - 2024-02-25
- Added check for packages before adding command to install packages

## [1.9.2] - 2024-02-25
- Bug fixes

## [1.9.1] - 2024-02-25
- Updates and fixes

## [1.9.0] - 2024-02-25
- Code changes to enable future additional of other distros

## [1.8.9] - 2024-02-24
- Code cleanup and bug fixes

## [1.8.8] - 2024-02-24
- Bug fixes

## [1.8.7] - 2024-02-23
- Checked with shellcheck

## [1.8.6] - 2024-02-23
- Bug fixes

## [1.8.5] - 2024-02-23
- Code cleanup

## [1.8.4] - 2024-02-22
- Bug fixes and improvements

## [1.8.3] - 2024-02-22
- Added support for custom autoinstall file

## [1.8.2] - 2024-02-22
- Started adding support for ZFS LVM config

## [1.8.1] - 2024-02-21
- Added XFS and BTRFS support

## [1.8.0] - 2024-02-17
- Added some initial code for being able to copy files from a previous version

## [1.7.9] - 2024-02-12
- Added code to add ZFS as an option for BIOS mode

## [1.7.8] - 2024-02-12
- Bug fixes for ZFS root install

## [1.7.7] - 2024-02-11
- Added bootdisk name to ISO name if not default

## [1.7.6] - 2024-02-11
- Fixed bug with username handling and naming ISO

## [1.7.5] - 2023-12-09
- Added BIOS ISO option with LVM only install

## [1.7.4] - 2023-12-08
- Impoved output file name determination

## [1.7.3] - 2023-12-07
- Documentation update

## [1.7.2] - 2023-12-07
- Fixes and improvements

## [1.7.1] - 2023-12-07
- Added code to determine ISO file from release information when creating KVM VM

## [1.7.0] - 2023-12-07
- Ouput code cleanup

## [1.6.9] - 2023-12-07
- Initial working code to create KVM VM

## [1.6.8] - 2023-12-04
- Added support for creating ISOs on Arch/Endeavour Linux

## [1.6.7] - 2023-11-05
- Added functionality to deal with xz compressed squashfs

## [1.6.6] - 2023-11-04
- More improvements to required packages check

## [1.6.5] - 2023-11-04
- Fixed required packages check

## [1.6.4] - 2023-11-04
- Initial support for Ubuntu 24.04

## [1.6.3] - 2023-10-25
- Added permissions check

## [1.6.2] - 2023-10-25
- Bug fixes

## [1.6.1] - 2023-10-08
- Fix for resolv.conf to stop mirror test failing

## [1.6.0] - 2023-10-07
- Bug fixes

## [1.5.9] - 2023-09-25
- Used wget -N for latest ISO check rather than lftp

## [1.5.8] - 2023-09-20
- Initial fix for lftp

## [1.5.7] - 2023-09-01
- Added options for dpkg

## [1.5.6] - 2023-08-24
- Added overwrite option to apt and dpkg

## [1.5.5] - 2023-08-24
- Added noserial option

## [1.5.4] - 2023-08-24
- Added option to disable serial

## [1.5.3] - 2023-08-24
- Fixed modprobe bug

## [1.5.2] - 2023-08-24
- Updated release information

## [1.5.1] - 2023-08-24
- Added more handling for latest development release

## [1.5.0] - 2023-08-24
- Added more information to printenv command

## [1.4.9] - 2023-05-13
- Bugfix for IP determination

## [1.4.8] - 2023-05-13
- Added initial list and search functionality for ISOs

## [1.4.7] - 2023-05-11
- Fixed NIC device detection

## [1.4.6] - 2023-05-11
- Added support for Ubuntu 23.10

## [1.4.5] - 2023-05-11
- Fixed bug with docker ISO creation

## [1.4.4] - 2023-05-03
- Fixed bug with package_update

## [1.4.3] - 2023-05-03
- Added allow switch to load additional kernel modules

## [1.4.2] - 2023-05-02
- Added block switch to blacklist kernel modules

## [1.4.1] - 2023-05-02
- More improvements to ISO naming

## [1.4.0] - 2023-05-01
- Fixed duplicate hostname in filename

## [1.3.9] - 2023-05-01
- Added fix for esm files during package install

## [1.3.8] - 2023-04-29
- Fixed duplicate IP in filename

## [1.3.7] - 2023-04-28
- Updated first disk code and added first net code

## [1.3.6] - 2023-04-28
- Added step to clean up apt cache

## [1.3.5]
- Improved check for blank password crypt

## [1.3.4] - 2023-04-28
- Fixed apt sources.list sed command

## [1.3.3] - 2023-04-28
- Added additional tags to output filename

## [1.3.2] - 2023-04-27
- Added ansible to default packages

## [1.3.1] - 2023-04-27
- Added NIC and biosdevnames tags to output file name

## [1.3.0] - 2023-04-27
- Added prefix and suffix switches

## [1.2.9] - 2023-04-27
- Added kvm options to install kvm packages

## [1.2.8] - 2023-04-27
- Added cluster option to install cluster packages

## [1.2.7] - 2023-04-19
- Added country switch and code for updating sources.list mirror URL for chroot and ISO

## [1.2.6] - 2023-04-19
- Added isourl switch

## [1.2.5] - 2023-04-19
- Added ttyS4 to serial enablement for Intel IME/AMT

## [1.2.4] - 2023-04-07
- Timezone fix

## [1.2.3] - 2023-04-07
- Added fix for debconf TERM not set error

## [1.2.2] - 2023-04-07
- Added fix for squashfs filename one Ubuntu 22.04 and later

## [1.2.1] - 2023-04-06
- Added support for using openssl to create password hash on MacOS

## [1.2.0] - 2023-04-02
- Added default SSH key option

## [1.1.9] - 2023-04-02
- Added checks for required packages

## [1.1.8] - 2023-04-02
- Fixed localtime symlink

## [1.1.7] - 2023-04-02
- Improved boot directory handling

## [1.1.6] - 2023-04-02
- Removed HWE support

## [1.1.5] - 2023-03-25
- Added code to set timezone to post install

## [1.1.4] - 2023-03-17
- Added serial arguments to default kernel parameters

## [1.1.3] - 2023-03-16
- Code cleanup

## [1.1.2] - 2023-03-10
- Fixed post install package installation

## [1.1.1] - 2023-03-10
- Bug fixes

## [1.1.0] - 2023-03-10
- Docker bug fixes

## [1.0.9] - 2023-03-09
- Bug fixes

## [1.0.8] - 2023-03-09
- Improvements and bug fixes

## [1.0.7] - 2023-03-09
- Disable autoupdates

## [1.0.6] - 2023-03-09
- Added usage information and updated documentation

## [1.0.5] - 2023-03-09
- Code cleanup

## [1.0.4] - 2023-03-08
- Added code to enable biosdevnames

## [1.0.3] - 2023-03-08
- Bug fixes

## [1.0.2] - 2023-03-08
- Added serial support to late-commands

## [1.0.1] - 2023-03-08
- Bug fixes and code cleanup

## [1.0.0] - 2023-02-27
- Bug fixes

## [0.9.9] - 2023-02-27
- Added code to disable Ubuntu Pro messages on Ubuntu 22.04

## [0.9.8] - 2023-02-27
- Added code to enable serial service

## [0.9.7] - 2023-02-27
- Fixed SSH key code and other bugs

## [0.9.6] - 2023-02-26
- Improved Ubuntu version support/flexibility

## [0.9.5] - 2023-02-26
- Bug fixes and documentation updates

## [0.9.4] - 2023-02-26
- Added some handling for detemining Ubuntu update/minor release number

## [0.9.3] - 2023-02-25
- Improved Volume ID determination for Desktop

## [0.9.2] - 2023-02-24
- Bug fixes

## [0.9.1] - 2023-02-24
- Fixed directory mount for docker for daily builds and updated documentation

## [0.9.0] - 2023-02-24
- Code cleanup

## [0.8.9] - 2023-02-17
- Initial support for having bios based install support for zfs

## [0.8.8] - 2023-02-16
- Bug fixes and documentation updates

## [0.8.7] - 2023-02-15
- Bug fixes and added code to change output filename if hostname/username/ip are set

## [0.8.6] - 2023-02-13
- Bug fixes

## [0.8.5] - 2023-02-08
- Improved first disk detection

## [0.8.4] - 2023-02-04
- Improved ISO file check

## [0.8.3] - 2023-02-02
- Code cleanup and bug fixes

## [0.8.2] - 2023-02-01
- Bug fixes and added grubfile options

## [0.8.1] - 2023-02-01
- Bug fixes and added squashfsfile option

## [0.8.0] - 2023-01-31
- Bug fixes

## [0.7.9] - 2023-01-30
- Bug fixes

## [0.7.8] - 2023-01-30
- Added initial racadm functionality to drive iDRAC

## [0.7.7] - 2023-01-29
- Bug fixes and improvements

## [0.7.6] - 2023-01-29
- Bug fixes

## [0.7.5] - 2023-01-28
- Added code to deploy ISO to Dell Server via Ansible

## [0.7.4] - 2023-01-27
- Added option to install addtional drivers

## [0.7.3] - 2023-01-27
- Added option for allowing SSH password access

## [0.7.2] - 2023-01-27
- Added SSH key support

## [0.7.1] - 2023-01-26
- Improved interactive questions code

## [0.7.0]
- Bug fixes for static IP config

## [0.6.9] - 2023-01-26
- Added initial support for static IP config

## [0.6.8] - 2023-01-25
- Collapsed more commandline options

## [0.6.7] - 2023-01-25
- Collapsed some commandline options

## [0.6.6] - 2023-01-24
- Bug fixes for docker support

## [0.6.5] - 2023-01-24
- Added more support for docker

## [0.6.4] - 2023-01-24
- More initial docker support

## [0.6.3] - 2023-01-23
- Added code to create docker config files

## [0.6.2] - 2023-01-23
- Reverted back to handling commandlne arguments in the shell due to issues with getopt(s)

## [0.6.1] - 2023-01-22
- Added code to install ZFS on first available disk

## [0.6.0] - 2023-01-21
- Added NVMe drive to device list

## [0.5.9] - 2023-01-21
- Bug fixes

## [0.5.8] - 2023-01-21
- Improved URL/ISO filename determination

## [0.5.7] - 2023-01-21
- Added code to allow using daily ISOs

## [0.5.6] - 2023-01-21
- Added code to query input ISO for information

## [0.5.5] - 2023-01-20
- Initial code for creating squashfs

## [0.5.4] - 2023-01-19
- Added support for HWE kernel

## [0.5.3] - 2023-01-19
- Added more support for Ubuntu 20.04

## [0.5.2] - 2023-01-19
- More variable and commandline option cleanup

## [0.5.1] - 2023-01-19
- Cleaned up variable names to stop clash with local names variables

## [0.5.0] - 2023-01-18
- Updates to begin adding support for 20.04

## [0.4.9] - 2023-01-18
- Fixes for xorriso command creation

## [0.4.8] - 2023-01-18
- Fixed ISO volid length issue

## [0.4.7] - 2023-01-18
- Bug fixes

## [0.4.6] - 2023-01-17
- Fixed update and package install code/documentation

## [0.4.5] - 2023-01-17
- Added update and package install options

## [0.4.4] - 2023-01-17
- Fixed grub update in late-commands

## [0.4.3] - 2023-01-17
- Fixed copy of packages into source directory for ISO creation

## [0.4.2] - 2023-01-17
- Added LC_ALL=C to chroot apt install commands to reduce locale complaints

## [0.4.1] - 2023-01-17
- Added language/locale switch and fixed bugs

## [0.4.0] - 2023-01-16
- Fixed Ubuntu Release/Codename usage

## [0.3.9] - 2023-01-16
- Finished migrating command line argument handling to new method

## [0.3.8] - 2023-01-16
- Improved command line argument handling

## [0.3.7] - 2023-01-16
- Added kernel args switch

## [0.3.6] - 2023-01-16
- Added grub timeout switch

## [0.3.5] - 2023-01-16
- Added default grub menu switch

## [0.3.4] - 2023-01-15
- Updated LVM config

## [0.3.3] - 2023-01-15
- Added non LVM config

## [0.3.2] - 2023-01-15
- More bug fixes

## [0.3.1] - 2023-01-15
- bug fixes

## [0.3.0] - 2023-01-15
- Added code to create cofigs for different combinations of volume managers and devices

## [0.2.9] - 2023-01-15
- Added initial code for doing non ZFS root

## [0.2.8] - 2023-01-14
- Added switch for static IP mode

## [0.2.7] - 2023-01-14
- Added NIC switch

## [0.2.6] - 2023-01-14
- Bug fixes and documentation updates

## [0.2.5] - 2023-01-14
- Fixed bug with code that copies packages into ISO

## [0.2.4] - 2023-01-14
- Added no unmount option

## [0.2.3] - 2023-01-14
- More fixes

## [0.2.2] - 2023-01-13
- Changed release determination code and ISO URL

## [0.2.1] - 2023-01-13
- Fixed bug with release determination

## [0.2.0] - 2023-01-13
- Added check that ISO file is a valid ISO file

## [0.1.9] - 2023-01-11
- Added code to unmount loopback filesystems

## [0.1.8] - 2023-01-11
- More bug fixes

## [0.1.7] - 2023-01-11
- More fixes

## [0.1.6] - 2023-01-11
- Further code cleanup

## [0.1.5] - 2023-01-10
- Added -f switch to remove previously created files

## [0.1.4] - 2023-01-10
- More code cleanup

## [0.1.3] - 2023-01-09
- More fixes

## [0.1.2]
- Code fixes

## [0.1.1]
- Fixed ISO url

## [0.1.0] - 2023-01-09
- Code cleanup and added release switch

## [0.0.9] - 2023-01-07
- ran commands through a execute function so the script can be used to generate a script

## [0.0.8] - 2023-01-07
- Code cleanup

## [0.0.7] - 2023-01-07
- Bug fixes

## [0.0.6] - 2023-01-07
- Cleaned up code

## [0.0.5] - 2023-01-07
- Cleaned up variables

## [0.0.4] - 2023-01-06
- More functionality

## [0.0.3] - 2023-01-02
- Basic working functionality - Initial commit

## [0.0.2] - 2023-01-02
- Converted to functions

## [0.0.1] - 2023-01-02
- Initial version
