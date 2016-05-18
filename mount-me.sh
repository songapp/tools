#!/bin/sh
# Song Jiang modified based on original version
set -e
CONTAINER=target
HOSTPATH=/root/mytest
CONTPATH=/transfer

REALPATH=$(readlink --canonicalize $HOSTPATH)
FILESYS=$(df -P $REALPATH | tail -n 1 | awk '{print $6}')
echo "real path and filesystem is " $REALPATH $FILESYS

while read DEV MOUNT JUNK
do 
  #echo $DEV $MOUNT
  DEV_MAPPER=$(expr match $DEV "/dev*")
  #echo "we got it" $DEV_MAPPER
  if [ $MOUNT = $FILESYS ] && [ $DEV_MAPPER = "4" ] ; then 
     break
  fi
done </proc/mounts
REALDEV=$(readlink --canonicalize $DEV)
echo $DEV $REALDEV $MOUNT
[ $MOUNT = $FILESYS ] # Sanity check!

while read A B C SUBROOT MOUNT JUNK
do [ $MOUNT = $FILESYS ] && break
done < /proc/self/mountinfo 
[ $MOUNT = $FILESYS ] # More sanity check!

SUBPATH=$(echo $REALPATH | sed s,^$FILESYS,,)
DEVDEC=$(printf "%d %d" $(stat --format "0x%t 0x%T" $REALDEV))

echo $SUBROOT $SUBPATH $DEVDEC

docker-enter $CONTAINER sh -c \
	     "[ -b $DEV ] || mknod $REALDEV b $DEVDEC"
docker-enter $CONTAINER mkdir /tmpmnt
docker-enter $CONTAINER mount $REALDEV /tmpmnt
docker-enter $CONTAINER mkdir -p $CONTPATH
docker-enter $CONTAINER mount -o bind /tmpmnt/$SUBROOT/$SUBPATH $CONTPATH
docker-enter $CONTAINER umount /tmpmnt
docker-enter $CONTAINER rmdir /tmpmnt
