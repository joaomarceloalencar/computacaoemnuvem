#!/bin/bash
# NFS Client Install

# Install NFS
apt update
apt -y install nfs-common
mount -t nfs 10.0.0.10:/home /home

# Update hostfile
ip -4 -br addr show dev eth0 | awk '{ print $3}' | cut -f1 -d'/' >> /home/hostfile

