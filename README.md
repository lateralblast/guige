![Cat with shield](https://raw.githubusercontent.com/lateralblast/guige/master/guige.jpg)

GUIGE
-----

Generic Ubuntu ISO Generation Engine

A guige (/ɡiːʒ/, /ɡiːd͡ʒ/) is a long strap, typically made of leather,
used to hang a shield on the shoulder or neck when not in use.

Version
-------

Current version: 4.0.0

License
-------

CC BY-SA: https://creativecommons.org/licenses/by-sa/4.0/

Fund me here: https://ko-fi.com/richardatlateralblast

Introduction
------------

This script provides a wrapper for the Ubuntu ISO creation process.
I wrote this as I didn't want to have to install and use Cubic or a similar GUI point and click tool to create an ISO.
I wanted to be able to automate the process.

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

- [Command Line Examples](https://github.com/lateralblast/modest/wiki/Examples)
- [Usage Information](https://github.com/lateralblast/modest/wiki/Usage)
- [Grub Command Line Processing](https://github.com/lateralblast/modest/wiki/Grub)
- [Prerequisites](https://github.com/lateralblast/modest/wiki/Prerequisites)
- [Manual Process Behind Creating An ISO](https://github.com/lateralblast/modest/wiki/Process)


Todo
----

Things I plan to do:

- Get ZFS root to work with BIOS based installs (currently ZFS root only works with EFI based installs)

Thanks
------

Thanks to Mark Lane for testing, suggestions, etc.
