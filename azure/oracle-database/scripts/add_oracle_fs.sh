#!/bin/bash
set +x

# pre-execution checks
if [[ ${EUID} -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi


ORA_SIZE="${1:-128G}"
ORA_VG='oravg'
ORA_LV_ARRAY=('u01lv' 'logslv' 'mirrorlv' 'archivelv')
ORA_LV_SIZE_ARRAY=('16G' '16G' '16G' '50G')
ORA_MNT_ARRAY=('/u01' '/logs' '/mirror_logs' '/archive_logs')

# arrray size assertion
if [[ (${#ORA_LV_ARRAY[@]} -ne ${#ORA_LV_SIZE_ARRAY[@]}) || (${#ORA_LV_ARRAY[@]} -ne ${#ORA_MNT_ARRAY[@]}) ]]; then
  echo "There's a mismatch in your array sizes"
  exit 2
fi


echo '+ finding device name'
ORA_DEV=$(lsblk -o NAME,SIZE | grep ${ORA_SIZE} | awk '{ print $1 }')

echo ' + partitioning device'
/usr/sbin/parted --align optimal /dev/${ORA_DEV} \
  mklabel msdos \
  mkpart primary 0% 100%

echo '  + making pv'
sleep 3
/usr/sbin/pvcreate /dev/${ORA_DEV}1
echo '  + making vg'
/usr/sbin/vgcreate ${ORA_VG} /dev/${ORA_DEV}1


i=0
while [[ $i -lt ${#ORA_LV_ARRAY[@]} ]]; do
  echo "  + making ${ORA_LV_ARRAY[$i]} lv"
  /usr/sbin/lvcreate -L ${ORA_LV_SIZE_ARRAY[$i]} -n ${ORA_LV_ARRAY[$i]} ${ORA_VG}
  echo '   + making filesystem'
  /usr/sbin/mkfs.xfs /dev/${ORA_VG}/${ORA_LV_ARRAY[$i]}
  echo '    + adding entry in /etc/fstab'
  echo "/dev/mapper/${ORA_VG}-${ORA_LV_ARRAY[$i]}  ${ORA_MNT_ARRAY[$i]}  xfs  defaults  0 0" >> /etc/fstab
  mkdir -p ${ORA_MNT_ARRAY[$i]}

  i=$(( i+1 ))
done


mount -a
echo '+ complete!'
