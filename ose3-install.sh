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

# if this is master
if [ ! -z "`hostname | grep master`" ]
then
  cd
  git clone https://github.com/openshift/training.git

  useradd joe
  useradd alice

  ssh-keygen

  for host in master node1 node2
  do
    ssh-copy-id -i ~/.ssh/id_rsa.pub ose3-${host}.example.com
  done
fi

echo
echo "Install of `hostname` complete.  Continue with 'Run the Installer' at:"
echo
echo "https://github.com/openshift/training/blob/master/02-Installation-and-Scheduler.md"
echo
