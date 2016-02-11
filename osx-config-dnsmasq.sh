#!/bin/bash

#
# NB:  Review this script and make sure that the IP addresses match
# your environment.  The current values reflect a VMware Fusion
# installation on OSX with the settings:
#
#    192.168.23.140	ose3-master.example.com
#    192.168.23.141	ose3-node1.example.com
#

IP_MASTR=192.168.23.140
IP_NODE1=192.168.23.141

# install dnsmasq if it's missing
if [ "x`brew list | grep dnsmasq`" != "xdnsmasq" ]
then
    brew update
    brew upgrade --all
    brew install dnsmasq
fi

# configure dnsmasq
cat > $(brew --prefix)/etc/dnsmasq.conf <<EOF1
address=/ose3-master.example.com/${IP_MASTR}
address=/kibana.example.com/${IP_MASTR}
address=/kibana-ops.example.com/${IP_MASTR}
address=/hawkular-metrics.example.com/${IP_MASTR}
address=/ose3-node.example.com/${IP_NODE1}
address=/.cloudapps.example.com/${IP_MASTR}
listen-address=127.0.0.1
EOF1

echo
echo "If prompted, provide the admin password for OSX"

# set resolver to redirect example.com queries to dnsmasq
sudo mkdir -p /etc/resolver

cat <<EOF2 | sudo tee /etc/resolver/example.com
nameserver 127.0.0.1
domain example.com
EOF2

# set launchd to start dnsmasq at startup
sudo cp -fv /usr/local/opt/dnsmasq/*.plist /Library/LaunchDaemons
sudo chown root /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist

# load dnsmasq now
sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
