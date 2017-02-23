#!/bin/bash
# Script to disable the firewall
systemctl stop firewalld
systemctl disable firewalld

echo firewalld has been stopped and disabled
