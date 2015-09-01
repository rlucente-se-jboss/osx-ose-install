#!/bin/bash

#
# NB:  Review this script and make sure that IP addresses match
# your environment.  The current values reflect a VMware Fusion
# installation on OSX with the settings:
#
#    192.168.23.139	ose3-master.example.com
#    192.168.23.141	ose3-node1.example.com
#    192.168.23.142	ose3-node2.example.com
#

# These have to be IP addresses that are compatible with your virtual
# machine environment.  The following values work for VMware Fusion
# on OSX, but for libvirt based installs on Linux, you can use "virsh
# net-dumpxml default" to see what the default network settings are.

IP_MASTR=192.168.23.139
IP_NODE1=192.168.23.141
IP_NODE2=192.168.23.142

# Insert your subscription manager pool id here, if known.  Otherwise,
# this script will try to dynamically determine the pool id.
SM_POOL_ID=

echo "Register for system updates"
subscription-manager register

# if no SM_POOL_ID defined, attempt to find the Red Hat employee
# "kitchen sink" SKU (of course, this only works for RH employees)
if [ "x${SM_POOL_ID}" = "x" ]
then
  SM_POOL_ID=`subscription-manager list --available | \
      grep 'Subscription Name:\|Pool ID:\|System Type' | \
      grep -B2 'Virtual' | \
      grep -A1 'Employee SKU' | \
      grep 'Pool ID:' | awk '{print $3}'`

  # exit if none found
  if [ "x${SM_POOL_ID}" = "x" ]
  then
    echo "No subcription manager pool id found.  Exiting"
    exit 1
  fi
fi

# attach subscription pool and enable channels for updates
subscription-manager attach --pool=$SM_POOL_ID
subscription-manager repos --disable="*"
subscription-manager repos \
--enable="rhel-7-server-rpms" \
--enable="rhel-7-server-extras-rpms" \
--enable="rhel-7-server-optional-rpms" \
--enable="rhel-7-server-ose-3.0-rpms"

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

# speed up updates
yum -y install deltarpm

# do the rest of the yum commands in one transaction
yum shell <<EOF1
  config assumeyes yes
  remove NetworkManager*
  install wget vim-enhanced net-tools bind-utils tmux git
  install python-virtualenv gcc
  install docker
  update
  clean all
  run
  exit
EOF1

sed -i \
's/^\(OPTIONS='\''--selinux-enabled\).*/\1 --insecure-registry 0.0.0.0\/0'\''/g' /etc/sysconfig/docker

docker-storage-setup
systemctl start docker

docker pull registry.access.redhat.com/openshift3/ose-haproxy-router:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/ose-deployer:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/ose-sti-builder:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/ose-docker-builder:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/ose-pod:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/ose-docker-registry:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/ose-keepalived-ipfailover:v3.0.1.0

docker pull registry.access.redhat.com/openshift3/ruby-20-rhel7:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/mysql-55-rhel7:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/php-55-rhel7:v3.0.1.0
docker pull registry.access.redhat.com/jboss-eap-6/eap-openshift:6.4
docker pull registry.access.redhat.com/openshift/hello-openshift

docker pull registry.access.redhat.com/jboss-amq-6/amq-openshift:6.2
docker pull registry.access.redhat.com/openshift3/mongodb-24-rhel7:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/postgresql-92-rhel7:v3.0.1.0
docker pull registry.access.redhat.com/jboss-webserver-3/tomcat8-openshift:3.0
docker pull registry.access.redhat.com/jboss-webserver-3/tomcat7-openshift:3.0
docker pull registry.access.redhat.com/openshift3/nodejs-010-rhel7:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/python-33-rhel7:v3.0.1.0
docker pull registry.access.redhat.com/openshift3/perl-516-rhel7:v3.0.1.0

# now unregister from RHSM
subscription-manager unregister

# remove any mapping to MAC address or UUID for the network interface
for cfg in `find /etc/sysconfig/network-scripts/ifcfg-e*`
do
    sed -i '/^HWADDR/d' $cfg
    sed -i '/^UUID/d' $cfg
done

# make the image very compressible by zeroing all unused bytes
pushd /
sync; sync; cat /dev/zero > zerofill; sync; sync; rm -f zerofill; sync; sync
cd /boot
sync; sync; cat /dev/zero > zerofill; sync; sync; rm -f zerofill; sync; sync
popd

echo
echo Base image has been created.
echo
