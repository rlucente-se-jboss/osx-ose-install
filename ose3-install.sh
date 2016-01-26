#!/bin/bash

#
# NB:  Review this script and make sure that IP addresses match
# your environment.  The current values reflect a VMware Fusion
# installation on OSX with the settings:
#
#    192.168.23.140	ose3-master.example.com
#    192.168.23.141	ose3-node.example.com
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
--enable="rhel-7-server-ose-3.1-rpms"

# if this is master
if [ ! -z "`hostname | grep master`" ]
then
  useradd -c "Demo User" demo

  echo "Set the password for user 'demo'"
  passwd demo

  echo "When generating the ssh key, DO NOT SET A PASSWORD!"
  ssh-keygen

  for host in master node
  do
    ssh-copy-id -i ~/.ssh/id_rsa.pub ose3-${host}.example.com
  done
fi

echo "Done."
echo
