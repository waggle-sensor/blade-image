# Blade-Image

Creates an ISO containing the Waggle customized Ubuntu (18.04) installation for x86
machines (i.e. Dell blade servers).

The build process downloads a stock Ubuntu server ISO, unpacks it, makes
installation (ex. preseed) modifications, adds required Debian packages,
copies Waggle specific root file system files, and re-packs the ISO.

## Usage

Builds are created using the `./build.sh` script. For help execute `./build.sh -?`.

To trigger a build simply execute `./build.sh`.

```
./build.sh
```

The output of the build process will be a versioned Waggle customized Ubuntu ISO.
For example: `waggle-ubuntu_dell-1.2.3-4-46ac2f1.iso`

### Version explained

The version `dell-1.2.3-4-46ac2f1` is broken down into the following sections:
- `dell-1.2.3-4-46ac2f1`: the first 4 values are derived from the most recent
`git` version tag (i.e. `v1.2.3`) applied (using the `git describe` command).
The string after the last dash (`-`) is the 7 digit git SHA1 of this project at the
time the build was created.

*Note*: This version field will also appear in the resulting file system @
`/etc/waggle_version_os`.

## Important folders

### iso_tools

The `iso_tools` folder contains files that need to be installed into the ISO
to facilitate the un-attended installation.  The most important of which is
the `preseed.seed` file.  This file "answers" all of the questions asked
during a normal Ubuntu installation to ensure a reliable and identical
installation every time.

### ROOTFS

The `ROOTFS` folder contains all the files that are to be copied to the
resulting Ubuntu installation root file system. The organization of the folder
is intended to be mirror of the resulting root file system.  For example, if
file 'X' is intended to be installed into `/etc/waggle` with execute permissions
then it must exist within `ROOTFS/etc/waggle` with execute permissions.

## How to Install to a Dell blade

### 1) Install ISO
To install the iso on a Dell Blade, we'll first need to ssh into the iDRAC of
said Dell Blade, which will take you into racadm.

```
ssh root@x.x.x.x
```

You'll be prompted for a password, the default is 'calvin'.

The following steps are relating to breaking the SSD Raid on the blade which
will allow the image to partition the drive how we would like.

To create the job to break the ssd raid we execute the following:

```
storage converttononraid:Disk.Bay.7:Enclosure.Internal.0-1:RAID.Integrated.1-1
```

To execute this job:

```
jobqueue create RAID.Integrated.1-1 --realtime
```

Next, once this job is completed we can begin mounting the image to the iDRAC.
Execute the following to remove any image already potentially mounted:

```
remoteimage -d
```

Then, to mount our image:

```
remoteimage -c -l http://x.x.x.x/*.iso
```

*Note*: Image location must be in ipv4 format, and image must be hosted using
httpfs2. iDRAC is capable of mounting from an apache server.

Finally, to start the OS install we should execute the following to set boot to virtual CD/DVD and then reboot.

```
racadm config -g cfgServerInfo -o cfgServerFirstBootDevice vCD-DVD
serveraction powercycle
```

*Note*: A script to do this and more can be found at: https://github.com/sagecontinuum/nodes/tree/master/sage-blade/Blade-BringUp

### 2) Unlock Registration Key

TODO: update 

About 10 minutes after the OS installation started, we should be able to access the blade by executing the following command to racadm:

```
console com2
```

You'll be prompted with the login/password for the machine itself.

After logging into the machine itself, we can register the blade with beehive
so that we can access the machine an easier way.

To do so, we need to run the following script.

```
/etc/waggle/unlock_registration.sh
```

After about three minutes our node should be registered with beehive! You can
find the reverse ssh port by executing the following:

```
cat /etc/waggle/reverse_ssh_port
```

### 3) Configure Network Access

By default the OS will have all network interfaces disabled.

#### To enable DHCP

To re-enabled all the interfaces and enabled DHCP IP address allocation simply
delete the `/etc/NetworkManager/conf.d/99-disabled.conf` file and reboot.

#### To set a static IP address

To set a static IP for the `eno1` (or `eno2`) interface use the following steps:

1. Delete the `/etc/NetworkManager/conf.d/99-disabled.conf` file
2. Edit the `/etc/network/interfaces-static` file as necessary for the network
3. Move the `/etc/network/interfaces-static` to `/etc/network/interfaces`
(replacing the existing file)
4. Reboot

## How the "required Debian package" list is created

The `required_deb_packages.txt` file contains a list of Debian packages
(and versions) to be included in the ISO for installation to the resulting
Waggle Ubuntu system.  This list contains Debian packages that are **not** already
available within the stock Ubuntu ISO (i.e. `/pool/main`) that are desired to
be installed onto the system at install time.

The Debian packages are downloaded and included within the ISO (i.e. `/pool/extras`)
so that an Internet connection is not required during the installation. This also
helps control the exact versions of the packages to ensure identical
installations.

This contains both "user applications" (i.e. `ansible=2.5.1+dfsg-1ubuntu0.1`)
and their dependencies (i.e. `python=2.7.15~rc1-1`).

The process to modify this list is the following:

1. Login to a system running the current version of the Waggle Ubuntu OS
(created by this build).
2. Using `apt` install the desired package(s) (i.e. `apt-get install curl --dry-run --no-upgrade --no-install-recommends`).
3. Identify the list of Debian packages that would be installed via the `Inst`
lines from the above `apt` command.
4. Update the `required_deb_packages.txt` file with the differences

*Note*: The `--no-upgrade` and `--no-install-recommends` options are listed above
to prevent unnecessary upgrade of already installed packages and to limit the
install to only the needed items.  The `--dry-run` option is **important** and
included to ensure no actual changes are made on the test system.

*Note*: The difference list may contain some packages that were changed in version
between the "before" and "after".  If the `--no-upgrade` option was included
when getting the list of Debian packages this mean the version change in an
installed package **is** required and should be included in the `required_deb_packages.txt`
file.

*Note*: The resulting list of new Debian packages *could* be checked against
what is already included in the stock Ubuntu ISO by checking for the
Debian packages existence in the`/pool/main` folder. If it is desired
(ex. because the Debian package is large) the Debian package can be installed
via the preseed (i.e. `pkgsel/include` command).  Just add the Debian package
name to and it will be installed by the Ubuntu automated installer.
