yum install -y  dhcp tftp-server syslinux xinetd 
[ ! -d  /mnt/esxi ] && mkdir /mnt/esxi
mount /dev/cdrw /mnt/esxi
status=`ls /mnt/esxi/ | wc -l`

# Mount Esxi Iso files
if [ $status -eq 0 ]
	then
		umount /mnt/esxi
		mount /dev/cdrom /mnt/esxi
		cp -ra /mnt/esxi/* /var/lib/tftptool/	
else
	cp -ra /mnt/esxi/* /var/lib/tftptool/
fi

#Config Dhcp Service
cat > /et/dhcp/dhcpd.conf << EOF
ddns-update-style interim;
allow booting;
allow bootp;
class "pxeclients" {
match if substring(option vendor-class-identifier, 0, 9) = "PXEClient";

#DCHP server ip address
next-server 172.25.77.51;
filename = "pxelinux.0";
}
subnet 172.25.77.0 netmask 255.255.255.0 {
range 172.25.77.100 172.25.77.150;
}
EOF
# Get Line Number
lineNum=`nl /etc/xinetd.d/tftp | grep disable |awk '{print $1}'`
sed -i "${lineNum}s/yes/no/g" /etc/xinetd.d/tftp

# Copy linux core files
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/

service dhcpd restart
service xinetd restart

# Config Ks file 
cat > /var/www/html/ks.cfg << EOF
#
# Sample scripted installation file
#
# Accept the VMware End User License Agreement
vmaccepteula
# Set the root password for the DCUI and Tech Support Mode
rootpw mypassword
# Install on the first local disk available on machine
install --firstdisk --overwritevmfs
# Set the network to DHCP on the first network adapter
network --bootproto=dhcp --device=vmnic0
EOF

#Config boot.cfg default
mkdir /var/lib/tftpboot/pxelinux.cfg
cp /mnt/esxi/isolinux.cfg /var/lib/tftpboot/pxelinux.cfg/default
sed  "s/runweasel/http\:\/\/172\.25\.77\.51\:8081\/ks\.cfg/g" //var/lib/tftpboot/boot.cfg
