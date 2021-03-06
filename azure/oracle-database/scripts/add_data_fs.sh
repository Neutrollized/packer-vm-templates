#!/bin/bash
set +x

# pre-execution checks
if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi


ORADATA_SIZE="${1:-256G}"
ORADATA_VG='oradatavg'
ORADATA_LV='datalv'
ORADATA_MNT_PT='/data'


echo '+ finding device name' 
ORADATA_DEV=$(lsblk -o NAME,SIZE | grep sd | grep -v "sd[a||b]" | grep ${ORADATA_SIZE} | awk '{ print $1 }' | grep -v -E '[0-9]$' | head -n 1)

echo ' + partitioning device' 
/usr/sbin/parted --align optimal /dev/${ORADATA_DEV} \
  mklabel msdos \
  mkpart primary 0% 100%

echo '  + making pv' 
sleep 3
/usr/sbin/pvcreate /dev/${ORADATA_DEV}1

echo '  + making vg' 
/usr/sbin/vgcreate ${ORADATA_VG} /dev/${ORADATA_DEV}1

echo '  + making lv' 
/usr/sbin/lvcreate -l 95%FREE -n ${ORADATA_LV} ${ORADATA_VG}

echo '   + making filesystem' 
/usr/sbin/mkfs.xfs /dev/${ORADATA_VG}/${ORADATA_LV}

echo '+ adding entry in /etc/fstab' 
# nobarrier mount option for xfs was deprecated in kernel 4.13 back in late 2017
echo "/dev/mapper/${ORADATA_VG}-${ORADATA_LV}  ${ORADATA_MNT_PT}  xfs  defaults  0 0" >> /etc/fstab
mkdir -p ${ORADATA_MNT_PT}

mount -a
echo '+ complete!' 
