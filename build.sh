#!/bin/bash

set -x

if [ -f debian-stable-amd64-preseed.iso ]; then
    sudo rm debian-stable-amd64-preseed.iso
fi

grep -v "^#" debian-stable-preseed.txt  | grep -v "^$$" > preseed.txt

if [ ! -f debian-stable-amd64.iso ]; then
    wget http://cdimage.debian.org/debian-cd/7.8.0/amd64/iso-cd/debian-7.8.0-amd64-netinst.iso -O debian-stable-amd64.iso
fi

if [ -d ./tmp ]; then
    rm -rf ./tmp
fi
mkdir ./tmp

sudo mount -o loop debian-stable-amd64.iso ./tmp

if [ -d ./cd ]; then
    rm -rf ./cd
fi
mkdir ./cd

rsync -aH --exclude=TRANS.TBL ./tmp/ ./cd/

sudo umount ./tmp
rmdir ./tmp

mkdir ./irmod
cd ./irmod

gzip -d < ../cd/install.amd/initrd.gz | cpio --extract --verbose --make-directories --no-absolute-filenames
cp ../preseed.txt preseed.cfg
find . | cpio -H newc --create --verbose | gzip -f -9 | sudo tee ../cd/install.amd/initrd.gz > /dev/null

cd ../
rm -rf ./irmod/

cd ./cd
md5sum `find -follow -type f` | sudo tee md5sum.txt > /dev/null
cd ../

sudo genisoimage -o debian-stable-amd64-preseed.iso -r -J -no-emul-boot -boot-load-size 4 -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat ./cd
sudo rm -rf ./cd

