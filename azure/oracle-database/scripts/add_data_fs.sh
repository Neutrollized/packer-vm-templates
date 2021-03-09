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
# I do this to bypass the unicode character in the output of lsblk sometimes
for i in $(lsblk -o NAME,SIZE | grep sd | grep -v "sd[a||b]" | grep ${ORADATA_SIZE} | awk '{ print $1 }' | sort); do
  echo ${i} | tail -c 5 | head -c 3 >> /tmp/lsblk_datadev.txt
  echo '' >> /tmp/lsblk_datadev.txt
done

ORADATA_DEV=$(uniq -u /tmp/lsblk_datadev.txt)

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
rm /tmp/lsblk_datadev.txt
echo '+ complete!' 
