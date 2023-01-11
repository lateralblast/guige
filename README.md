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

A guige (/ɡiːʒ/, /ɡiːd͡ʒ/) is a long strap, typically made of leather, 
used to hang a shield on the shoulder or neck when not in use. 

Currently this is WIP and this comment will be removed when the first working edition is complete.
It is being converted from a set of shell commands.

In particular this script provides support for creating autoinstall ISO with:

- ZFS root 
- Adding packages to installation

So that the additional packages added to the install do not require network access,
the squashfs filesystem is mounted and the packages are installed into it with the download option,
then the packages are copied to the ISO image that is created.
Doing it this way also ensures packages dependencies are also handled.

Rather than being directly run, the commands are wrappered and run through
an execute function so that the script can be used to produce another script.


Usage
-----

You can get help using the -h switch:

```
  Usage: guige.sh [OPTIONS...]
    -C  Run chroot script
    -c  Create ISO (perform all steps)
    -D  Use defaults
    -d  Get base ISO
    -H: Hostname
    -h  Help/Usage Information
    -I  Interactive mode (will ask for input rather than using command line options or defaults)
    -i: Input/base ISO file
    -L: LSB release
    -o: Output ISO file
    -P: Password
    -p: Packages to add to ISO
    -R: Realname
    -r  Install required packages on host
    -T: Timezone
    -t  Test mode
    -U: Username
    -V  Script Version
    -v  Verbose output
    -W: Work directory
    -w  Check work directories

```

Examples
--------

Install required packages:

```
./guide.sh -r
```

Download base ISO (jammy)

```
./guide.sh -d -L jammy
```

Create ISO (performs all steps):

```
./guide.sh -c -L jammy
```

Run the previous command but in test mode (don't execute commands) to produce output suitable for creating a script:


```
./guide.sh -c -t -L jammy
```



