
NB:  These instructions are for VMware Fusion running on OSX.  You'll
need to adapt as necessary for your environment.

Configure the VMware DHCP Addresses
-----------------------------------

Life is much much easier if we all have the same subnets and IP
address allocations when running demos, sharing images, etc.  VMware
Fusion does not come with easy to use network configuration utilities,
but you can still tweak the settings.  This procedure is documented
in the [VMware knowledgebase](http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1026510) but the simple set of commands are
described below.  If there is any doubt, please refer to the official
product documentation.

First, shutdown all running guest virtual machines and exit the
VMware Fusion application.  No VMware Fusion processes should be
running for this to work.

Next, for VMware Fusion 4.x and above edit the following file:

    sudo vi /Library/Preferences/VMware\ Fusion/networking

Modify the file so that it contains the following lines:

    answer VNET_1_HOSTONLY_SUBNET 172.16.174.0
    answer VNET_8_HOSTONLY_SUBNET 192.168.23.0

These instructions assume that the above 192.168.23.0/24 subnet is
being used.  If you insist on something else, you'll need to make
changes in the various scripts and instructions.

You can leave the rest of the file contents alone.  After saving
the file, simply launch VMware Fusion to restart the networking
components.

The KB article includes instructions for other versions of VMware
Fusion including the network editor included in VMware Fusion
Professional.  If there are any doubts, refer to the official docs.

Install Brew on OSX
-------------------

Make sure that you install the [HomeBrew](http://brew.sh/) utility on OSX.  This enables
the installation of packages in OSX that weren't included in the
distribution.  Always refer to the official documentation to do
this, but the quick set of instructions are:

    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew update
    brew upgrade --all

The last two commands are something you should do periodically to
make sure that the packages you've installed (and their dependencies)
are up to date.

Configure dnsmasq on OSX
------------------------

Run the following script to configure dnsmasq on OSX.  This script,
which relies on brew, takes advantage of how OSX allows for multiple
DNS resolvers.  All DNS queries to the example.com domain are
redirected to the dnsmasq service.  This is very simple and enables
easy access to the VM's running the OpenShift v3 master and nodes.

    ./osx-config-dnsmasq.sh

Test this by running the command:

    ping -c 3 ose3-master.example.com

This will fail to ping since the VMs aren't yet running but it will
correctly resolve the hostname.  Press CTRL-C to stop the command.

Configure the OSE v3 Guest VMs
------------------------------

For the remaining machines, you can create everything yourself or
skip to "Use Existing Disk Image" and download and use an image for
the base install of the master and nodes.

Create The Base Image
---------------------

This section walks you through creating a "base" virtual machine
image that will be used to create the master and the processing
nodes.

From the Virtual Machine Library window after launching VMware
Fusion, click Add->New... and then press Continue.

Make sure that you've downloaded the RHEL 7.2 ISO image.  On the
Create a New Virtual Machine, select the rhel-server-7.2-x86_64-dvd.iso
image and then press Continue.

On the "Choose Operating System" screen, select "Red Hat Enterprise
Linux 7 64-bit" and press Continue.

Click "Customize Settings" and set the Save As to "ose3-base" then
click Save.

Next, customize the guest VM settings.  Under Processors & Memory
set Processors to 3 cores and Memory to 8192 MB.  VMware Fusion
will share memory pages among instances of virtual machines when
running the same versions of the operating system and included
libraries.  Because of this, you can exceed the physical RAM on
your system.

Under Hard Disk, select Advanced options and then uncheck the box
"Split into multiple files".  Set the hard disk size to 50 GB.
Close the options and boot the virtual machine.

Install RHEL 7.2 with "Minimal" profile.

During the install, click "Installation Destination" option.  Select
the disk and then click the radio button "I will configure
partitioning".  On the Manual Partitioning page, click the link
"Click here to create them automatically".  Change the settings to
the following:

    /boot	500 MiB
    /		30 GiB
    swap	2048 MiB

Select the "/" mount point and on the right hand pane click "Modify"
under the "rhel" volume group.  Set the "Size policy" to "As large
as possible" then click "Save".  Click "Done" and then accept the
changes.

Click the "Network & Host Name" option.  On that page, click the
switch to turn the interface ON and then click Configure.  On the
General tab, select the checkbox labeled "Automatically connect to
this network when it is available".  On the IPv4 Settings tab, set
Method to Manual and click the Add button to add a static IP address.
Use the following settings:

    Address		Netmask		Gateway
    192.168.23.138	24		192.168.23.2

    DNS Servers:     192.168.23.2
    Search domains:  example.com

On the IPv6 Settings tab, set Method to ignore.  Press Save.

Finish the installation.  I set the root password to "redhat".  You
can use anything that's easy for you to remember.

Once the server reboots, copy the ose3-create-base.sh script to
it from the host using:

    scp ose3-create-base.sh root@192.168.23.138:

As root on the guest virtual machine, run the script using:

    ./ose3-create-base.sh

The system will switch to the rescue mode run-level in the console
for the virtual machine.  Follow the instructions when the script
completes to make the image as compressible as possible.

Once complete, you will have an existing disk image to use when
creating the other three virtual machines.  Copy the disk image to
another location so that you can easily reuse it for the master and
node guest VMs.  On the host, type the commands:

    cd ~/Documents/Virtual\ Machines.localized/ose3-base.vmwarevm
    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -d Virtual\ Disk.vmdk
    /Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager -k Virtual\ Disk.vmdk
    cp Virtual\ Disk.vmdk ../ose3-base.vmdk

Use Existing Disk Image
-----------------------

You can save some time by simply downloading a pre-built disk image.
The one that I've created is available here (access is restricted):

    https://drive.google.com/open?id=0BxHotDs3XvN1NFdhQVdfcVl6S1E

in vmdk format.  Simply download, decompress, untar, and then use
them to create the other three virtual machines.  You can expand
it using the command:

    tar zxf ose3-base.vmdk.tgz

Create the guests in the following order:

    IP Address		Name
    192.168.23.141	ose3-node
    192.168.23.140	ose3-master

For each virtual machine, select Add->New... for a new virtual
machine.

Under "Select the Installation Method", select "Create a custom
virtual machine" and press Continue.

Select Red Hat Enterprise Linux 7 64-bit for the OS then press Continue.

For Virtual Disk, select the radio button "Use an existing virtual
disk" then press the "Choose virtual disk..." button.  Select the
.vmdk file that you want to use.  If you downloaded mine from google
drive, you would select "ose3-base.vmdk".  Select the option "Make
a separate copy of the virtual disk" and then press Choose.  Press
Continue.

Press Customize Settings and the set the name based on the list
below.  When creating the base virtual machine, under Processors &
Memory set Processors to 3 cores and Memory to 8192 MB.

Close the settings and start the virtual machine.

Once the machine is started, logon as root using password "redhat"
and then issue the following commands:

    hostnamectl set-hostname <name>

where name is ose3-node.example.com or ose3-master.example.com
depending on the system being installed.

Edit the network configuration file (typically named
/etc/sysconfig/network-scripts/ifcfg-e*) and change the value for
IPADDR.  The modifications are summarized in the following table:

    Name		IPADDR
    ose3-node		192.168.23.141
    ose3-master		192.168.23.140

If your IP subnet is different then the above, you'll need to adjust
these values now.  Specifically, update the 'nameserver' parameter in

    /etc/resolv.conf

and update the 'IPADDR', 'GATEWAY', and 'DNS1' parameters in

    /etc/sysconfig/network-scripts/ifcfg-e*

Reboot the system when finished so the IP address and hostname
changes are now in effect.

Prepare for OSE Installation
----------------------------
Copy ose3-install.sh to each virtual machine after installing:

    scp ose3-install.sh root@<ip-addr>:

Run the script on each virtual machine and reboot before installing
the next virtual machine.

Each guest VM is now ready to install OSE 3. Continue with section
2.4 for Quick Installation and 2.5 for Advanced Installation in the
[Installation and Configuration Guide](https://access.redhat.com/documentation/en/openshift-enterprise/version-3.1/installation-and-configuration).

Post OSE Installation
---------------------

Edit the file /etc/origin/master/master-config.yaml and change the
following stanza:

    authConfig:
      assetPublicURL: https://ose3-master.example.com:8443/console/
      grantConfig:
        method: auto
      identityProviders:
      - challenge: true
        login: true
        name: allow_all
        provider:
          apiVersion: v1
          kind: AllowAllPasswordIdentityProvider
          mappingMethod: claim

The AllowAllPasswordIdentityProvider will enable any username/password
to be used to authenticate to OSE.  This is useful for demonstration
purposes.  Restart the master service so this change takes effect.

    systemctl restart atomic-openshift-master

Make the master schedulable so that we can deploy the router service
and docker registry to it.

    oadm manage-node ose3-master.example.com --schedulable
    oc label node ose3-master.example.com region=infra

Deploy the docker-registry using the following:

    oadm registry --config=/etc/origin/master/admin.kubeconfig \
        --credentials=/etc/origin/master/openshift-registry.kubeconfig \
        --selector='region=infra' \
        --images='registry.access.redhat.com/openshift3/ose-${component}:${version}'

This will take a minute or so.  Afterwards, the docker-registy pod
will be deployed to the master node.

Deploy the router service using the following:

    oadm router --credentials='/etc/origin/master/openshift-router.kubeconfig' \
        --service-account=router \
        --selector='region=infra'

Edit the file /etc/origin/master/master-config.yaml and change the
following stanza to set the default routing subdomain:

    routingConfig:
      subdomain:  "apps.example.com"

The routingConfig will set the default subdomain that is appended
when external routes are created for applications.  Restart the
master service so this change takes effect.

    systemctl restart atomic-openshift-master

To enable the Fuse application templates, issue the command as root:

    oc create -n openshift \
        -f https://raw.githubusercontent.com/jboss-fuse/application-templates/master/fis-image-streams.json

Enable Logging with EFK Stack and Metrics with Hawkular
-------------------------------------------------------

I borrowed heavily from Jim Minter's demobuilder project for a
vagrant OSE all-in-one virtual machine.  The original scripts are
located [here](https://github.com/RedHatEMEA/demobuilder/tree/master/layers/rhel-server-7:gui:ose-3.1/%40target).

To enable the EFK stack and Hawkular metrics, do the following:

    scp install-logging.sh install-metrics.sh server-tls.json root@ose3-master.example.com:
    ssh root@ose3-master.example.com
    ./install-logging.sh
    ./install-metrics.sh

Install OpenShift v3.1 Linux Client on OSX
------------------------------------------

Download the client from the [OpenShift Product Software page](https://access.redhat.com/downloads/content/290/ver=3.1/rhel---7/3.1.1.6/x86_64/product-software).  Make
sure to grab the appropriate version.

Expand the contents into a temporary directory then copy to /usr/share:

    cd /tmp
    tar zxf ~/Downloads/oc-3.1.1.6-macosx.tar.gz
    cd mnt/redhat/staging-cds/ose-clients-3.1.1.6/usr/share
    sudo cp -r atomic-openshift /usr/share

Since you have brew installed (or you *SHOULD*) then simply create
a softlink to /usr/local/bin to add oc to your command search path:

    ln -s /usr/share/atomic-openshift/macosx/oc /usr/local/bin

Using oc CLI
------------

The resolver configuration in OSX is ignored by certain system calls
used by go, so the following command will not work:

    oc login ose3-master.example.com:8443 --insecure-skip-tls-verify -u demo

However, this command with the IP address will work:

    oc login 192.168.23.140:8443 --insecure-skip-tls-verify -u demo

