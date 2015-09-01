#!/bin/bash

# Simple script to use the docker registry REST api to get the tags
# for each docker image in the following list

images=( openshift3/ose-haproxy-router openshift3/ose-deployer openshift3/ose-sti-builder openshift3/ose-docker-builder openshift3/ose-pod openshift3/ose-docker-registry openshift3/ose-keepalived-ipfailover openshift3/ruby-20-rhel7 openshift3/mysql-55-rhel7 openshift3/php-55-rhel7 jboss-eap-6/eap-openshift openshift/hello-openshift jboss-amq-6/amq-openshift openshift3/mongodb-24-rhel7 openshift3/postgresql-92-rhel7 jboss-webserver-3/tomcat8-openshift jboss-webserver-3/tomcat7-openshift openshift3/nodejs-010-rhel7 openshift3/python-33-rhel7 openshift3/perl-516-rhel7 )

# Install jq utility if missing
if [ "x`brew list | grep jq`" != "xjq" ]
then
    brew update
    brew upgrade --all
    brew install jq
fi

for image in "${images[@]}"
do
    echo $image
    curl -s http://registry.access.redhat.com/v1/repositories/$image/tags | jq '.'
done
