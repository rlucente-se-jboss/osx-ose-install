#!/bin/bash

# Insert your subscription manager pool id here, if known.  Otherwise,
# this script will try to dynamically determine the pool id.
SM_POOL_ID=

function pause {
    echo "Press ENTER to continue"
    read dummy
}

echo "Set SELINUXTYPE to targeted"
sed -i 's/^\(SELINUXTYPE=\)..*/\1targeted/g' /etc/selinux/config

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
--enable="rhel-7-server-ose-3.1-rpms"

# install base packages
yum -y install wget git net-tools bind-utils iptables-services \
    bridge-utils bash-completion

# update to latest packages
yum -y update

# install additional packages
yum -y install atomic-openshift-utils

# install docker
yum -y install docker

sed -i \
's/^\(OPTIONS='\''--selinux-enabled\).*/\1 --insecure-registry 172.30.0.0\/16'\''/g' /etc/sysconfig/docker

# configure docker storage
cat >> /etc/sysconfig/docker-storage-setup <<EOF1
DATA_SIZE=100%VG
EOF1

docker-storage-setup

# verify that the docker thinpool is enabled
cat /etc/sysconfig/docker-storage
lvs
pause

# re-initialize docker
systemctl enable docker
systemctl stop docker
rm -rf /var/lib/docker/*
systemctl restart docker

# set up clock synchronization
yum -y install chrony
systemctl start chronyd
systemctl enable chronyd

# now unregister from RHSM
subscription-manager unregister

# remove any mapping to MAC address or UUID for the network interface
for cfg in `find /etc/sysconfig/network-scripts/ifcfg-e*`
do
    sed -i '/^HWADDR/d' $cfg
    sed -i '/^UUID/d' $cfg
done

# switch to single user mode
echo "System should be in rescue mode in the console.  Provide root"
echo "password when prompted.  Make the image very compressible by zeroing"
echo "all unused bytes:"
echo
echo "    cd /"
echo "    sync; sync; cat /dev/zero > zerofill; sync; sync"
echo "    rm zerofill; sync; sync"
echo "    cd /boot"
echo "    sync; sync; cat /dev/zero > zerofill; sync; sync"
echo "    rm zerofill; sync; sync"
echo "    shutdown"
echo

systemctl isolate rescue.target
