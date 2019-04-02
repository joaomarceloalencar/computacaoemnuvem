#!/bin/bash

ADMIN_PASSWORD="openstack"

# install packages
apt-get update
apt-get install -y git

# create stack user
useradd -s /bin/bash -d /opt/stack -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

# create local.conf
cat <<EOF > /tmp/local.conf
[[local|localrc]]
ADMIN_PASSWORD=$ADMIN_PASSWORD
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
ENABLED_SERVICES+=,heat,h-api,h-api-cfn,h-api-cw,h-eng
enable_service h-eng h-api h-api-cfn h-api-cw
enable_plugin heat https://git.openstack.org/openstack/heat
enable_plugin heat-dashboard https://git.openstack.org/openstack/heat-dashboard
EOF

# clone the repository
sudo -i -u stack bash << EOF
git clone https://git.openstack.org/openstack-dev/devstack
EOF

# copy the local.conf
mv /tmp/local.conf /opt/stack/devstack/
chown stack.stack /opt/stack/devstack/local.conf


# run the installation
sudo -i -u stack bash << EOF
cd devstack
./stack.sh
source openrc
wget http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
openstack image create --container-format bare --disk-format qcow2 --file bionic-server-cloudimg-amd64.img Ubuntu1804
EOF

