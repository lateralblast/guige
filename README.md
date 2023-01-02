![alt tag](https://raw.githubusercontent.com/lateralblast/guige/master/guige.jpg)

GUIGE
-----

Generic Ubuntu ISO Generation Engine

Version
-------

Current version 0.0.3

Introduction
------------

This script provides a wrapper for the Ubuntu ISO creation process.

Currently this is WIP and this comment will be removed when the first working edition is complete.
It is being converted from a set of shell commands.

I particular this script provides support for creating autoinstall ISO with:

- ZFS root 
- Adding packages to installation

So that the additional packages added to the install do not require network access,
the squashfs filesystem is mounted and the packages are installed into it with the download option,
then the packages are copied to the ISO image that is created.