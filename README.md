# Blade-Image

Creates an ISO containing the Waggle customized Ubuntu (18.04) installation for x86
machines (i.e. Dell blade servers).

The build process downloads a stock Ubuntu server ISO, unpacks it, makes
installation (ex. preseed) modifications, adds required Debian packages,
copies Waggle specific root file system files, and re-packs the ISO.

## Building the ISO

Builds are created using the `./build.sh` script. For help execute `./build.sh -?`.

To trigger a build simply execute `./build.sh`.

```
./build.sh
```

The output of the build process will be a versioned Waggle customized Ubuntu ISO.
For example: `waggle_blade-1.2.3-4-46ac2f1.iso`

<a name="vm_build"></a>
To build a virtual machine compatible (i.e. fake node ID, smaller partition sizes) ISO
use the following command:

```
./build.sh -v
```

### Version explained

The version `dell-1.2.3-4-46ac2f1` is broken down into the following sections:
- the first 4 values are derived from the most recent
`git` version tag (i.e. `v1.2.3`) applied (using the `git describe` command).
- the string after the last dash (`-`) is the 7 digit git SHA1 of this project at the
time the build was created.

> *Note*:
> This version field will also appear in the resulting file system @
> `/etc/waggle_version_os`.

### <a name="rba"></a> Release Build Assets

Due to a GitHub [2GiB max file size limitation](https://docs.github.com/en/github/administering-a-repository/about-releases#storage-and-bandwidth-quotas) the assets included in the GitHub
release are [split](https://linux.die.net/man/1/split) upon upload. This requires
that they be re-packaged together after download.  This can be done by simply
concatenating the files together.

Recreate the original large file:

```
cat <base file name>-* > <base file name>.iso
```

Example:

```
cat waggle_blade-1.2.3-0-aee27ec.iso-* > waggle_blade-1.2.3-0-aee27ec.iso
```

## Flashing the ISO and Post-flash Configuration

### <a name="flashing_iso"></a> 1) Flashing the ISO

Download the ISO from 1 of the following 2 locations:
- Public AWS [latest stable]: http://54.196.185.44/waggle_blade.iso
- Release page: https://github.com/waggle-sensor/blade-image/releases

> *Note*:
> You can find the list of files available for download in the public AWS by visiting this page: http://54.196.185.44/files/

#### Dell Blade Hardware

> *Note*:
> This installation process will take a _long_ time (~75 minutes).

##### Command Line iDRAC / Remote Flashing

To install the ISO on a Dell Blade, we'll first need to ssh into the iDRAC of
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

> *Note*:
> Image location must be in ipv4 format, and image must be hosted using
> httpfs2. iDRAC is capable of mounting from an apache server.

Finally, to start the OS install we should execute the following to set boot to virtual CD/DVD and then reboot.

```
racadm config -g cfgServerInfo -o cfgServerFirstBootDevice vCD-DVD
serveraction powercycle
```

> *Note*:
> A script to do this and more can be found at: https://github.com/sagecontinuum/nodes/tree/master/sage-blade/Blade-BringUp

> *Note*:
> proceed to the [Login and Program VSN](#vsn) instructions below

##### <a name="idrac_web"></a> iDRAC Web Interface GUI Flashing

It is possible (in a local condition) to use the iDRAC web interface to flash the Dell blade via the
virtual console

1) Make sure the machine is powered-off

2) Login to the iDRAC interface in your browser. You may get a warning about the certificate
being stale or not existing. This can be ignored.

3) Launch the Virtual Console.  You may need to disable pop-ups in your web browser.

4) Click "Connect Virtual Media"

5) Browse for the ISO file in the "Map CD/DVD" section, click the "Map Device" button and close the dialog

6) Click "Boot" and select the "Virtual CD/DVD/ISO" option.

7) Click "Power" and power on the machine.

At this time the Dell blade server should power-on and auto-start the installation of the ISO mounted
from your local machine.  You should see the text "Virtual CD boot Requested by iDRAC" on the blue
"DELL bootloader" screen.

> *Reference*: 
> https://www.dell.com/support/kbdoc/en-us/000124001/using-the-virtual-media-function-on-idrac-6-7-8-and-9 (following iDRAC 9 steps)

> *Note*:
> proceed to the [Login and Program VSN](#vsn) instructions below

#### Virtual Machine

It is possible to flash a virtual machine compatible ISO (build using the [VM build option](#vm_build)). The following are the instructions (using [VirtualBox](https://www.virtualbox.org/)) to configure your virtual machine.

1) Create a new Ubuntu 64-bit machine with at-least 1024 MB of RAM and at-least a 25GB virtual hard disk.

2) After the machine is created, select "Settings"

3) Under the "Network" tab create 2 adapters: 1 bridged to your machines adapter with Internet access and a 2nd attached to "Internal Network"

4) Under the "Storage" tab attach the VM ISO to the "Empty" IDE controller "Optical Drive"

5) Click "OK" to close "Settings"

6) Click "Start" to boot the Virtual Machine

> *Note*:
> proceed to the [Login and Program VSN](#vsn) instructions below

### <a name="vsn"></a> 2) Login and Program VSN

After installation is completed, we will need to login to the machine to program the machine's VSN.

#### Obtain access to the login prompt

##### iDRAC console

To access the blade via the iDRAC console execute the following command to racadm:

```
console com2
```

> *Note*:
> You can execute the command `getsysinfo` to figure out the "Service Tag" among other information.

##### iDRAC Web Interface

If local iDRAC access is possible you may use the iDRAC web interface to launch the Virtual Console to 
login to the machine. Follow similar instructions [iDRAC Web Interface GUI Flashing](#idrac_web) to get
a shell prompt into the machine.

#### Program the VSN

After entering the login credentials to the machine you will be greeted with the WaggleOS login splash

```
 __          __               _       ____   _____
 \ \        / /              | |     / __ \ / ____|
  \ \  /\  / /_ _  __ _  __ _| | ___| |  | | (___
   \ \/  \/ / _` |/ _` |/ _` | |/ _ \ |  | |\___ \
    \  /\  / (_| | (_| | (_| | |  __/ |__| |____) |
     \/  \/ \__,_|\__, |\__, |_|\___|\____/|_____/
                   __/ | __/ |
                  |___/ |___/

System information as of: Fri Feb 25 00:16:09 UTC 2022

System:      	PowerEdge XR2 (SKU=8C66;ModelName=PowerEdge XR2)
System load: 	0.18 0.29 0.36 (1, 5, 15 min)
Memory usage:	4%	IP Address:	192.168.88.12
Usage on /:  	1%	Uptime:    	2:15 hours
Plugin usage:	1%	Users:     	1
Swap usage:  	0%	Processes: 	351
VSN:         	V028

Ubuntu 18.04.5 LTS (GNU/Linux 4.15.0-112-generic x86_64)
Waggle OS Version: dell-1.0.1-109-g6b5abe4

root@sb-prereg:~#
```

> *Note*:
> You will notice the login prompt of `sb-prereg` which stands for "Sage Blade Pre-Registration".
> This means this node has not yet registered with Beekeeper and there is no reverse tunnel
> established.

At this time you may program the VSN by executing the following command:

```
echo <VSN> > /etc/waggle/vsn
```

> *Note*:
> The identify the proper VSN for the machine, reference the [Production Google Sheet](https://docs.google.com/spreadsheets/d/11u-FfoH-41V_10QchS2af319LNdM42bja4VtLW-Q0wg/edit#gid=0)

### <a name="unlock"></a> 3) Unlock Registration Key

To unlock the registration key(s) and establish the reverse tunnel execute the "unlock" script:

```
/etc/waggle/unlock_registration.sh
```

> *Note*:
> You will be presented with 3 password prompts to unlock 3 keys. The script will notify you if you
> entered the correct password and the key was able to be successfully unlocked.

### 4) Configure Network Access

By default the OS will have the `wan` network interfaces disabled and have no access to the Internet.
The configuration for the `wan` interface can be found here:

```
/etc/NetworkManager/system-connections/wan
```

> *Note*:
> After executing the steps below the machine Waggle software will start reaching out the Internet
> and Waggle cloud based services.

#### DHCP Configuration

The `NetworkManager` `wan` configuration is defaulted for DHCP. If the network environment allows
DHCP then the following commands can be executed to enable the interface and request an IP address.

```
sed 's|\(^autoconnect=\).*|\1true|' /etc/NetworkManager/system-connections/wan
nmcli c reload
```

#### Static IP Address Configuration

If a static IP address is required then the `NetworkManager` `wan` configuration will need to
manually modified to set the static IP configuration.

1) To enable the connection to auto-connect on boot:
```
sed 's|\(^autoconnect=\).*|\1true|' /etc/NetworkManager/system-connections/wan
```

2) Using your favorite editor (i.e. `vim`) open `/etc/NetworkManager/system-connections/wan` to
enter the static IP configuration parameters.

3) Instruct `NetworkManager` to reload the configuration and connect:
```
nmcli c reload
```

### 5) Validate `wan0` Network Traffic

With the network configured, we need to validate the machine is communicating over `wan0`.
While still logged into the console execute the following command to identify if `wan0` is
getting an IP address and there is network traffic

```
ifconfig wan0
```

You will see something like this:

```
wan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.88.236  netmask 255.255.255.0  broadcast 192.168.88.255
        ether 2c:ea:7f:a0:b7:5c  txqueuelen 1000  (Ethernet)
        RX packets 1684121  bytes 1770750552 (1.7 GB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 818408  bytes 76200549 (76.2 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        device interrupt 17
```

Validate that IP address (`inet`) is populated with a valid IP (either from the DHCP
or static IP set above).

Additionally, validate that there is network traffic by executing the following command:

```
iftop -i wan0
```

This will show if there is current network activity on `wan0`. For example:

```
TX:             cum:    121KB   peak:   17.7Kb         rates:   2.37Kb  4.81Kb  2.51Kb
RX:                    31.4KB           9.16Kb                  1.13Kb  2.43Kb  1.30Kb
TOTAL:                  152KB           26.8Kb                  3.50Kb  7.24Kb  3.80Kb
```

Once, it is confirmed that `wan0` has Internet access proceed to testing the Reverse SSH tunnel.

> *Note:*
> If the above `iftop` command doesn't show network activity (i.e. no increasing count in TX/RX) then
> there is an issue with the `wan0` configuration.

### 6) Validate the Reverse SSH Tunnel to Beekeeper

With Internet access enabled, the Waggle reverse tunnel service (`waggle-bk-reverse-tunnel`) will
automatically establish a tunnel to Beekeeper. To validate that connection, open a terminal on
your local machine and attempt to connect to the Dell blade.

```
ssh node-<node ID>
```

> *Note*:
> The node ID for the machine can be identified from the "Waggle login splash" screen
> (see [Login and Program VSN](#vsn)) or the `/etc/waggle/node-id` file.

### 7) Reboot Machine & Validate Reverse SSH Tunnel Auto-Starts

Now that the reverse tunnel has been established the machine needs to be restarted to
program its final hostname (i.e. `sb-core-<node ID>`). Execute a reboot:

```
reboot
```

And after ~5 minutes attempt to re-connect to the machine using the Beekeeper reverse SSH tunnel.

```
ssh node-<node ID>
```

### <a name="preload"></a> 8) Pre-load the AI/ML Base Images

Next the AI/ML base images should be loaded.

1) SSH to the node
```
ssh node-<node ID>
```

2) Execute the following script to load the base images
```
PRELOAD_IMAGES=(
  "waggle/plugin-base:1.1.1-base1.1.1-ros2-foxy"
  "waggle/plugin-base:1.1.1-base1.1.1-ros-noetic"
  "waggle/plugin-base:1.1.1-base"
  "waggle/plugin-base:1.1.1-ml-cuda11.0-amd64"
  "waggle/plugin-base:1.1.1-ml"
)
for f in ${PRELOAD_IMAGES[@]}; do k3s crictl pull $f; done
```

3) Check that all the base images are loaded
```
crictl images | grep plugin-base
```
You should see the following output
```
docker.io/waggle/plugin-base                1.1.1-base                   69a7a9948db6a       297MB
docker.io/waggle/plugin-base                1.1.1-base1.1.1-ros-noetic   fc099ee65cade       497MB
docker.io/waggle/plugin-base                1.1.1-base1.1.1-ros2-foxy    b2272c37b0b5b       420MB
docker.io/waggle/plugin-base                1.1.1-ml                     ff9f8cbc318e4       3.57GB
docker.io/waggle/plugin-base                1.1.1-ml-cuda11.0-amd64      ff9f8cbc318e4       3.57GB
```

> *Note*:
> The loading of the images will require ~4GB of network bandwidth and may take several minutes to download.

Once the base images have been successfully loaded the Dell blade configuration is complete!

## Important folders

### iso_tools

The `iso_tools` folder contains files that need to be installed into the ISO
to facilitate the un-attended installation.  The most important of which is
the `preseed.seed.base` file.  This file "answers" all of the questions asked
during a normal Ubuntu installation to ensure a reliable and identical
installation every time.

### ROOTFS

The `ROOTFS` folder contains all the files that are to be copied to the
resulting Waggle Ubuntu installation root file system. The organization of the folder
is intended to be mirror of the resulting root file system.  For example, if
file 'X' is intended to be installed into `/etc/waggle` with execute permissions
then it must exist within `ROOTFS/etc/waggle` with execute permissions.

## How the "required Debian package" list is created

The `required_deb_packages.txt` and `required_deb_nvidia_packages` file contain the
list of Debian packages (and versions) to be included in the ISO for installation to
the resulting Waggle system. This list contains Debian packages that are **not** already
available within the stock Ubuntu ISO (i.e. `/pool/main`) that are desired to
be installed onto the system at ISO install time.

The Debian packages are downloaded and included within the ISO (i.e. `/pool/contrib`)
so that an Internet connection is _not_ required during the installation. This also
helps control the exact versions of the packages to ensure identical
installations.

This contains both "user applications" (i.e. `ansible=2.5.1+dfsg-1ubuntu0.1`)
and their dependencies (i.e. `python=2.7.15~rc1-1`).

The process to modify this list is the following:

1. Login to a system running the current version of the Waggle OS
(created by this build).
2. Using `apt` install the desired package(s) (i.e. `apt-get install curl --dry-run --no-upgrade --no-install-recommends`).
3. Identify the list of Debian packages that would be installed via the `Inst` (or `Conf`)
lines from the above `apt` command.
4. Update the `required_deb_packages.txt` file with the differences

> *Note*:
> The `--no-upgrade` and `--no-install-recommends` options are listed above
> to prevent unnecessary upgrade of already installed packages and to limit the
> install to only the needed items.  The `--dry-run` option is **important** and
> included to ensure no actual changes are made on the test system.

> *Note*:
> The difference list may contain some packages that were changed in version
> between the "before" and "after".  If the `--no-upgrade` option was included
> when getting the list of Debian packages this mean the version change in an
> installed package **is** required and should be included in the `required_deb_packages.txt`
> file.

> *Note*:
> The resulting list of new Debian packages *could* be checked against
> what is already included in the stock Ubuntu ISO by checking for the
> Debian packages existence in the`/pool/main` folder. If it is desired
> (ex. because the Debian package is large) the Debian package can be installed
> via the preseed (i.e. `pkgsel/include` command).  Just add the Debian package
> name to and it will be installed by the Ubuntu automated installer.
