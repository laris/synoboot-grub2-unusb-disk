#!/bin/bash

mkdir -p ./boot/grub/i386-pc

mkdir efi
mount -o rw,loop,offset=1048576  ./synoboot.img ./efi
cp -a ./efi/bzImage ./efi/info.txt ./boot/
cp -a ./efi/grub/grubenv ./boot/grub/
cp -a ./efi/grub/grub.cfg ./boot/grub/grub.cfg.orig
sync; umount ./efi; rm -rf ./efi

mkdir kernel
mount -o rw,loop,offset=16777216 ./synoboot.img ./kernel
cd kernel 
cp -a extra.lzma rd.gz  zImage ../boot/
cd ..; sync; umount ./kernel; rm -rf ./kernel

cp -a /usr/lib/grub/i386-pc/* ./boot/grub/i386-pc/

grub-mkimage -C xz -O i386-pc -o ./boot/grub/i386-pc/core.img -p "(hd0,msdos1)/boot/grub" -d ./boot/grub/i386-pc biosdisk part_msdos mdraid09_be ext2

cp ./grub.cfg ./boot/grub/grub.cfg

echo "scp -r ./boot user@DSM-IP:/tmp/"
echo "ssh to DSM and sudo su - to change to root and"
echo "root# mv /tmp/boot /"
echo "root# dd if=/boot/grub/i386-pc/boot.img of=/dev/sda bs=446 count=1"
echo "root# dd if=/boot/grub/i386-pc/core.img of=/dev/sda bs=512 seek=1"
