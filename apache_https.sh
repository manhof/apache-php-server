#!/bin/bash
#https Cert Install
gawk -F= '/^ID=/{print $2}' /etc/os-release > /home/id.txt
serverbuild=$(cat /home/id.txt)
echo " This is the Server Build: " $serverbuild >> /home/test
pub=$1
hostname=$2
new_cert=$3
self_signed=$4
certurl=$5
keyurl=$6
Country=$7
State=$8
City=$9
Org=$10
OrgU=$11
CN=$12
alt_name=$13


self_key_out=/etc/ssl/private/apache-selfsigned.key
self_crt_out=/etc/ssl/certs/apache-selfsigned.crt
gen_key_out= /etc/ssl/private/$CN.key
gen_csr_out= $CN.csr

dphram= /etc/ssl/certs/dhparam.pem

if [[ $serverbuild == *"ubuntu"* ]]
 then
 	 ssl_conf= /etc/apache2/conf-available/ssl-params.conf
	 ssl_dflt= /etc/apache2/sites-available/default-ssl.conf
	 site_dfl= /etc/apache2/sites-available/000-default.conf
elif [[ $serverbuild == *"centos"* ]]
 then
	mkdir /etc/ssl/private
else
    echo "Cannot determine Build Type... Exiting" >> /home/test
	exit 3
fi	  
	
if [[$new_cert == 1 ]]
 then
	echo " Creating a new Cert Request" >> /home/test
	echo "[ req ]" >> /home/san.cnf
	echo "default_bits			= 2048" >> /home/san.cnf
	echo "distinguish_name		= req_distinguished_name" >> /home/san.cnf
	echo "req_extensions		= req_ext" >> /home/san.cnf
	echo "[ req_distinguished_name ]" >> /home/san.cnf
	echo "countryName			= $Country" >> /home/san.cnf
	echo "stateOrProvinceName	= $State" >> /home/san.cnf
	echo "localityName			= $City" >> /home/san.cnf
	echo "organizationName		= $Org $OrgU" >> /home/san.cnf
	echo "commonName			= $CN" >> /home/san.cnf
	echo "[ req_ext ]" >> /home/san.cnf
	echo "subjectAltName = @alt_names" >> /home/san.cnf
	echo "[alt_names]" >> /home/san.cnf
	echo "DNS.1					= $alt_name" >> /home/san.cnf
	if [[ $self_signed == 1 ]]
	 then
		echo "Generating Self Signed Certificate" >> /home/test
		keyout= $self_key_out
		crtout= $self_crt_out
		openssl req -x509 -nodes -newkey rsa:2048 -keyout $keyout -out $crtout -config san.cnf
	else
		echo "generating certificate and key request... will need to put crt file in /etc/ssl/certs/ once recieved" >> /home/test
		echo "will need to update $ssl_conf with file name " >> /home/test
		keyout= $gen_key_out
		csrout= $gen_csr_out
		crtout= ""
		openssl req -newkey rsa:2048 -nodes -keyout $keyout -out $csrout -config /home/san.cnf
	fi
else
	"Downloading Certs" >> /home/test
	curl -o $hostname.crt $curturl
	curl -o $hostname.key $keyurl
	cp *.key  /etc/ssl/private/
	cp *.crt /etc/ssl/certs/
fi
if [[ $serverbuild == *"centos"* ]]
 then
	openssl dhparam -out $dphram 2048
	cat $dphram | tee -a $self_crt_out
	oldcrt= /etc/pki/tls/certs/localhost.crt
	oldkey= /etc/pki/tls/private/localhost.key
	ssl_conf= /etc/httpd/conf.d/ssl.conf
	echo "<VirtualHost *:80>" >> /etc/httpd/conf.d/non-ssl.conf
	echo "        Redirect \"/\" \"https://$pub/\"" >> /etc/httpd/conf.d/non-ssl.conf
	echo "</VirtualHost>"  >> /etc/httpd/conf.d/non-ssl.conf
elif [[ $serverbuild == *"ubuntu"* ]]
 then
	oldcrt= /etc/ssl/certs/ssl-cert-snakeoil.pem
	oldkey= /etc/ssl/private/ssl-cert-snakeoil.key
	sed -i -e 's+DocumentRoot /var/www/html+DocumentRoot /var/www/html\n\t\tRedirect \"/\" \"https://$pub/\"+g' $site_dfl
else
    echo "Cannot determine Build Type... Exiting" >> /home/test
	exit 3
fi	   
echo "# from https://cipherli.st/" >> $ssl_conf
echo "SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH" >> $ssl_conf                
echo "SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1" >> $ssl_conf
echo "SSLHonorCipherOrder On" >> $ssl_conf
echo "Header always set Strict-Transport-Security \"max-age=63072000; includeSubDomains; preload\"" >> $ssl_conf
echo "Header always set X-Frame-Options DENY" >> $ssl_conf
echo "Header always set X-Content-Type-Options nosniff" >> $ssl_conf
echo "# Requires Apache >= 2.4" >> $ssl_conf
echo "SSLCompression off " >> $ssl_conf
echo "SSLUseStapling on " >> $ssl_conf
echo "SSLStaplingCache \"shmcb:logs/stapling-cache(150000)\"" >> $ssl_conf 
echo "# Requires Apache >= 2.4.11" >> $ssl_conf
echo "SSLSessionTickets Off" >> $ssl_conf
echo "SSLOpenSSLConfCmd DHParameters \"$dphram\"" >> $ssl_conf
sed -i -e 's+$oldcrt+$crtout+g' $ssl_dflt
sed -i -e 's+$oldkey+$keyout+g' $ssl_dflt
if [[ $serverbuild == *"ubuntu"* ]]
 then
	a2enmod ssl
	a2enmod headers
	a2ensite default-ssl
	a2enconf ssl-params
fi
apache2ctl configtest >> /home/test
if [[$new_cert == 1 ]]
 then
	if [[ $self_signed == 1 ]]
	then
		systemctl restart apache2
		echo "server has been restarted with self signed cert" >> /home/test
	else
		exit 0
else
	systemctl restart apache2
	echo "server has been updated with public certificate. test to make sure this works"
fi


