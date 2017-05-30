#!/bin/bash
gawk -F= '/^ID=/{print $2}' /etc/os-release > /home/id.txt
serverbuild=$(cat /home/id.txt)
echo " This is the Server Build: " $serverbuild >> /home/test
echo "Firewall Configuration" >> /home/test
if [[ $serverbuild == *"ubuntu"* ]]
 then
	ufw allow in OpenSSH
    ufw allow in "Apache Full"
    ufw enable
    ufw status >> /home/test
elif [[ $serverbuild == *"centos"* ]]
 then
	dnf install firewalld -y
	firewall-offline-cmd --zone=public --add-interface=eth0
	firewall-offline-cmd --set-default-zone=public
	firewall-offline-cmd --zone=public --add-service=ssh
	firewall-offline-cmd --zone=public --add-service=https
	firewall-offline-cmd --zone=public --add-service=https	firewall-
	echo "Default Zone" >> /home/test
	firewall-offline-cmd --get-default-zone >> /home/test
	firewall-offline-cmd --info-zone=public >> /home/test
	systemctl start firewalld
	systemctl enable firewalld
else
	echo "Cannot determine Build Type... Exiting" >> /home/test
	exit 3
fi  
echo "END FIREWALL CONFIG" >> /home/test
