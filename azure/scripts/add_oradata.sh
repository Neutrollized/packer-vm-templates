#!/bin/bash
set +x

# pre-execution checks
if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

yum list installed | grep oracle-database-preinstall > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "You're missing some prerequisite packages"
  exit 2
fi


ORADATA_SIZE="${1:-512G}"
ORADATA_VG='oraclevg'
ORADATA_LV='oradatalv'


echo '+ finding device name' 
ORADATA_DEV=$(lsblk -o NAME,SIZE | grep ${ORADATA_SIZE} | awk '{ print $1 }')

echo ' + partitioning device' 
/usr/sbin/parted --align optimal /dev/${ORADATA_DEV} \
  mklabel msdos \
  mkpart primary 0% 100%

echo '  + making pv' 
/usr/sbin/pvcreate /dev/${ORADATA_DEV}1

echo '  + making vg' 
/usr/sbin/vgcreate ${ORADATA_VG} /dev/${ORADATA_DEV}1

echo '  + making lv' 
/usr/sbin/lvcreate -l 95%FREE -n ${ORADATA_LV} ${ORADATA_VG}

echo '   + making filesystem' 
/usr/sbin/mkfs.ext4 /dev/${ORADATA_VG}/${ORADATA_LV}


echo '+ adding entry in /etc/fstab' 
echo "/dev/mapper/${ORADATA_VG}-${ORADATA_LV}  /opt/oracle/oradata  ext4  defaults,barrier=0  0 0" >> /etc/fstab
mkdir -p /opt/oracle/oradata
mount -a

echo '+ complete!' 
exit 0
