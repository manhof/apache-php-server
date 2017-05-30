#!/bin/bash
#apache php configuration setup 
gawk -F= '/^ID=/{print $2}' /etc/os-release > /home/id.txt
serverbuild=$(cat /home/id.txt)
echo " This is the Server Build: " $serverbuild >> /home/test
if [[ $serverbuild == *"ubuntu"* ]]
 then
	rm -rf /etc/apache2/mods-enabled/dir.conf
    echo "<IfModule mod_dir.c>" >> /etc/apache2/mods-enabled/dir.conf
    echo "    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm" >> /etc/apache2/mods-enabled/dir.conf
    echo "</IfModule>" >> /etc/apache2/mods-enabled/dir.conf
    systemctl restart apache2 
    echo "apache updated to look for php first " >> /home/test
elif [[ $serverbuild == *"centos"* ]]
 then
	sed -i -e 's+DirectoryIndex index.html+DirectoryIndex index.html index.php+g' /etc/httpd/conf/httpd.conf
else
    echo "Cannot determine Build Type... Exiting" >> /home/test
	exit 3
fi	   
