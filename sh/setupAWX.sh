#!/bin/sh

SVCACCT="local"

dnf makecache --timer
dnf -y update
dnf -y install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf -y install docker-ce docker-ce-cli
systemctl disable firewalld
systemctl enable docker --now
usermod -aG docker $SVCACCT
dnf -y python3 git make nodejs epel-release nfs-utils
dnf -y install ansible
pip3 install docker docker-compose
pushd /opt
git clone https://github.com/ansible/awx.git
popd

reboot