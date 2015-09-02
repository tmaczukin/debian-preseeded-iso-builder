#!/bin/bash

set -x

START_DIR=$(pwd)
SOURCE_ISO_URL=http://cdimage.debian.org/debian-cd/8.1.0/amd64/iso-cd/debian-8.1.0-amd64-netinst.iso
WORK_DIR=/tmp/iso-preseed
SOURCE_ISO=${WORK_DIR}/debian-stable-amd64.iso
TARGET_ISO=${WORK_DIR}/debian-stable-amd64-preseed.iso
SOURCE_DIR=${WORK_DIR}/source
TARGET_DIR=${WORK_DIR}/target
INIT_RAMDISK_DIR=${WORK_DIR}/init_ramdisk
PRESEED=${WORK_DIR}/preseed.txt

if [[ ! -d ${WORK_DIR} ]]; then
    mkdir -p ${WORK_DIR}
fi

if [[ ! -f ${SOURCE_ISO} ]]; then
    wget "${SOURCE_ISO_URL}" -O ${SOURCE_ISO}
fi

if [[ -f ${TARGET_ISO} ]]; then
    rm -rf ${TARGET_ISO}
fi

if [[ -d ${SOURCE_DIR} ]]; then
    sudo rm -rf ${SOURCE_DIR}
fi
mkdir -p ${SOURCE_DIR}

if [[ -d ${TARGET_DIR} ]]; then
    sudo rm -rf ${TARGET_DIR}
fi

grep -v "^#" debian-stable-preseed.txt  | grep -v "^$" > ${PRESEED}

sudo mount -o loop ${SOURCE_ISO} ${SOURCE_DIR}

rsync -aH --exclude=TRANS.TBL ${SOURCE_DIR}/* ${TARGET_DIR}
rsync -aH --exclude=TRANS.TBL ${SOURCE_DIR}/.disk ${TARGET_DIR}

sudo umount ${SOURCE_DIR}
rmdir ${SOURCE_DIR}

mkdir -p ${INIT_RAMDISK_DIR}
cd ${INIT_RAMDISK_DIR}

gzip -d < ${TARGET_DIR}/install.amd/initrd.gz | cpio --extract --verbose --make-directories --no-absolute-filenames
cp ${PRESEED} preseed.cfg
find . | cpio -H newc --create --verbose | gzip -f -9 | sudo tee ${TARGET_DIR}/install.amd/initrd.gz >/dev/null 2>&1

cd ${START_DIR}
sudo rm -rf ${INIT_RAMDISK_DIR}

cd ${TARGET_DIR}
md5sum `find -follow -type f` | sudo tee md5sum.txt >/dev/null 2>&1
cd ${START_DIR}

sudo genisoimage -o ${TARGET_ISO} -r -J -no-emul-boot -boot-load-size 4 -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat ${TARGET_DIR}
sudo rm -rf ${TARGET_DIR}
