#!/bin/bash
# Master Node

# Install NFS
apt update
apt -y install nfs-kernel-server
echo "/home       10.0.0.0/16(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
systemctl restart nfs-kernel-server

# Create SSH Keys
ssh-keygen -t dsa  -f /home/ubuntu/.ssh/id_dsa -N ""
cat /home/ubuntu/.ssh/id_dsa.pub >> /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu.ubuntu /home/ubuntu/.ssh

# Disable host verification
cat <<EOF >> /etc/ssh/ssh_config
Host 10.0.*
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
   LogLevel ERROR
EOF

# Create hostfile
echo "10.0.0.10" >> /home/hostfile


