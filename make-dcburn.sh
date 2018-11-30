#! /bin/sh
#
# Copyright (c) 2009, 2010, 2013, 2015, 2018 Izumi Tsutsui.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

PROG=dcburn
VERSION=20181130

MACHINE=i386

#
# target dependent info
#
if [ "${MACHINE}" = "amd64" ]; then
 MACHINE_ARCH=x86_64
 MACHINE_GNU_PLATFORM=x86_64--netbsd		# for fdisk(8)
 TARGET_ENDIAN=le
 KERN_SET=kern-GENERIC
 EXTRA_SETS= # nothing
 USE_MBR=yes
# BOOTDISK=wd0		# for ATA disk
 BOOTDISK=sd0		# for USB disk
 PRIMARY_BOOT=bootxx_ffsv1
 SECONDARY_BOOT=boot
 SECONDARY_BOOT_ARG= # nothing
fi

if [ "${MACHINE}" = "i386" ]; then
 MACHINE_ARCH=i386
 MACHINE_GNU_PLATFORM=i486--netbsdelf		# for fdisk(8)
 TARGET_ENDIAN=le
 KERN_SET=kern-GENERIC
 EXTRA_SETS= # nothing
 USE_MBR=yes
# BOOTDISK=wd0		# for ATA disk
 BOOTDISK=sd0		# for USB disk
 PRIMARY_BOOT=bootxx_ffsv1
 SECONDARY_BOOT=boot
 SECONDARY_BOOT_ARG= # nothing
fi

if [ -z ${MACHINE_ARCH} ]; then
	echo "Unsupported MACHINE (${MACHINE})"
	exit 1
fi

#
# tooldir settings
#
#NETBSDSRCDIR=/usr/src
#NETBSDSRCDIR=/s/src
#TOOLDIR=/usr/tools/${MACHINE_ARCH}

if [ -z ${NETBSDSRCDIR} ]; then
	NETBSDSRCDIR=/usr/src
fi

if [ -z ${TOOLDIR} ]; then
	_HOST_OSNAME=`uname -s`
	_HOST_OSREL=`uname -r`
	_HOST_ARCH=`uname -p 2> /dev/null || uname -m`
	TOOLDIRNAME=tooldir.${_HOST_OSNAME}-${_HOST_OSREL}-${_HOST_ARCH}
	TOOLDIR=${NETBSDSRCDIR}/obj.${MACHINE}/${TOOLDIRNAME}
	if [ ! -d ${TOOLDIR} ]; then
		TOOLDIR=${NETBSDSRCDIR}/${TOOLDIRNAME}
	fi
fi

if [ ! -d ${TOOLDIR} ]; then
	echo 'set TOOLDIR for dcburn host first'; exit 1
fi
if [ ! -x ${TOOLDIR}/bin/nbmake-${MACHINE} ]; then
	echo 'build tools for dcburn host first'; exit 1
fi

#
# info about ftp to get binary sets
#
FTPHOST=cdn.NetBSD.org
#FTPHOST=ftp.NetBSD.org
#FTPHOST=ftp.jp.NetBSD.org
#FTPHOST=ftp7.jp.NetBSD.org
#FTPHOST=nyftp.NetBSD.org
RELEASE=8.0
RELEASEDIR=pub/NetBSD/NetBSD-${RELEASE}
#RELEASEDIR=pub/NetBSD-daily/HEAD/201011130000Z
PKG_RELEASE=8.0
PACKAGESDIR=pub/pkgsrc/packages/NetBSD/${MACHINE_ARCH}/${PKG_RELEASE}

#
# misc build settings
#
CAT=cat
CKSUM=cksum
CP=cp
DD=dd
DISKLABEL=${TOOLDIR}/bin/nbdisklabel
FDISK=${TOOLDIR}/bin/${MACHINE_GNU_PLATFORM}-fdisk
FTP=ftp
#FTP=lukemftp
FTP_OPTIONS=-V
GZIP=gzip
MKDIR=mkdir
MV=mv
RM=rm
SH=sh
SED=sed
TAR=tar
TOUCH=touch

TARGETROOTDIR=targetroot.${MACHINE}
DOWNLOADDIR=download.${MACHINE}
WORKDIR=work.${MACHINE}

IMAGE=${WORKDIR}/${MACHINE}.img

#
# target image size settings
#
#IMAGEMB=3840			# for "4GB" USB memory
#IMAGEMB=1880			# for "2GB" USB memory
IMAGEMB=900			# 900MB for 8.0 base distribution
#SWAPMB=256			# 256MB
#SWAPMB=128			# 128MB
SWAPMB=64			# 64MB
IMAGESECTORS=$((${IMAGEMB} * 1024 * 1024 / 512))
SWAPSECTORS=$((${SWAPMB} * 1024 * 1024 / 512))

LABELSECTORS=0
if [ "${USE_MBR}" = "yes" ]; then
#	LABELSECTORS=63		# historical
#	LABELSECTORS=32		# aligned
	LABELSECTORS=2048	# aligned 1MiB for modern flash
fi
BSDPARTSECTORS=$((${IMAGESECTORS} - ${LABELSECTORS}))
FSSECTORS=$((${IMAGESECTORS} - ${SWAPSECTORS} - ${LABELSECTORS}))
FSOFFSET=${LABELSECTORS}
SWAPOFFSET=$((${LABELSECTORS} + ${FSSECTORS}))
FSSIZE=$((${FSSECTORS} * 512))
HEADS=64
SECTORS=32
CYLINDERS=$((${IMAGESECTORS} / ( ${HEADS} * ${SECTORS} ) ))
FSCYLINDERS=$((${FSSECTORS} / ( ${HEADS} * ${SECTORS} ) ))
SWAPCYLINDERS=$((${SWAPSECTORS} / ( ${HEADS} * ${SECTORS} ) ))

# fdisk(8) parameters
MBRSECTORS=63
MBRHEADS=255
MBRCYLINDERS=$((${IMAGESECTORS} / ( ${MBRHEADS} * ${MBRSECTORS} ) ))
MBRNETBSD=169

# makefs(8) parameters
BLOCKSIZE=16384
FRAGSIZE=2048
DENSITY=8192

KERNEL=netbsd-GENERIC
KERNEL_BIN=${KERNEL}.bin

#
# get binary sets
#
URL_SETS=http://${FTPHOST}/${RELEASEDIR}/${MACHINE}/binary/sets
SETS="${KERN_SET} base etc comp ${EXTRA_SETS}"
${MKDIR} -p ${DOWNLOADDIR}
for set in ${SETS}; do
	if [ ! -f ${DOWNLOADDIR}/${set}.tgz ]; then
		echo Fetching server ${set}.tgz...
		${FTP} ${FTP_OPTIONS} \
		    -o ${DOWNLOADDIR}/${set}.tgz ${URL_SETS}/${set}.tgz
	fi
done

#
# create targetroot
#
echo Removing ${TARGETROOTDIR}...
${RM} -rf ${TARGETROOTDIR}
${MKDIR} -p ${TARGETROOTDIR}
for set in ${SETS}; do
	echo Extracting host ${set}...
	${TAR} -C ${TARGETROOTDIR} -zxf ${DOWNLOADDIR}/${set}.tgz
done
# XXX /var/spool/ftp/hidden is unreadable
chmod u+r ${TARGETROOTDIR}/var/spool/ftp/hidden

#
# create target fs
#

# copy secondary boot for bootstrap
# XXX probabry more machine dependent
if [ ! -z ${SECONDARY_BOOT} ]; then
	echo Copying secondary boot...
	${CP} ${TARGETROOTDIR}/usr/mdec/${SECONDARY_BOOT} ${TARGETROOTDIR}
fi

echo Removing ${WORKDIR}...
${RM} -rf ${WORKDIR}
${MKDIR} -p ${WORKDIR}

echo Preparing /etc/fstab...
${CAT} > ${WORKDIR}/fstab <<EOF
/dev/${BOOTDISK}a	/		ffs	rw,log		1 1
/dev/${BOOTDISK}b	none		none	sw		0 0
ptyfs		/dev/pts	ptyfs	rw		0 0
kernfs		/kern		kernfs	rw,noauto	0 0
procfs		/proc		procfs	rw,noauto	0 0
EOF
${CP} ${WORKDIR}/fstab  ${TARGETROOTDIR}/etc

echo Preparing /etc/rc.conf...
${CAT} ${TARGETROOTDIR}/etc/rc.conf | \
	${SED} -e 's/rc_configured=NO/rc_configured=YES/' > ${WORKDIR}/rc.conf
${CAT} >> ${WORKDIR}/rc.conf <<EOF
hostname=dcburn
rpcbind=YES		rpcbind_flags="-l"	# -l logs libwrap
dhcpcd=YES
savecore=NO
cron=NO
postfix=NO
wscons=NO
EOF
${CP} ${WORKDIR}/rc.conf ${TARGETROOTDIR}/etc

echo Preparing misc /etc files...
# /etc/boot.cfg
${CAT} > ${WORKDIR}/boot.cfg <<EOF
banner================================================================================
banner=Welcome to DCburn, NetBSD/dreamcast bootable CD-R burner
banner= (Host OS: NetBSD/i386 ${RELEASE})
banner================================================================================
banner=
banner=To set up necessary files, you need Internet connection via DHCP.
banner=
banner=Note ACPI (Advanced Configuration and Power Interface) should work on
banner=all modern and legacy i386 servers.  However if you do encounter a problem
banner=while booting the default kernel on your i386 host, try no ACPI kernels.
menu=Start DCburn:boot netbsd
menu=Start DCburn (with no ACPI i386 host kernel):boot netbsd -2
menu=Start DCburn (with no ACPI, no SMP i386 host kernel):boot netbsd -12
menu=Drop to boot prompt:prompt
timeout=10
EOF
${CP} ${WORKDIR}/boot.cfg ${TARGETROOTDIR}

echo Preparing dcburn Makefile...
${CAT} > ${WORKDIR}/Makefile <<EOF
# A dumb Makefile which create bootable CD-R without file system

FTP_HOST?=cdn.NetBSD.org
FTP_PATH=pub/NetBSD/NetBSD-${RELEASE}
KERNEL?=${KERNEL}
KERNEL_BIN?=\${KERNEL}.bin
PACKAGES_HOST?=cdn.NetBSD.org
PACKAGESDIR=pub/pkgsrc/packages/NetBSD/${MACHINE_ARCH}/${PKG_RELEASE}
#PACKAGES_HOST=teokurebsd.org
#PACKAGESDIR=netbsd/packages/${MACHINE_ARCH}/${PKG_RELEASE}

SCRAMBLE_C_URL?=http://mc.pp.se/dc/files/scramble.c
MAKEIP_TAR_GZ_URL?=http://mc.pp.se/dc/files/makeip.tar.gz

CC?=	cc
FTP?=	ftp
#FTP=	tnftp
#FTP=	wget
GZIP?=	gzip
TAR?=	tar

OBJCOPY?= objcopy

CDRDEV?= /dev/rcd0d
#CDRDEV= /dev/rcd1d
#CDRDEV= /dev/rcd0c
CDRSPEED?= 16
#CDRSPEED= 4

MKISOFS= /usr/pkg/bin/mkisofs
CDRECORD= /usr/pkg/bin/cdrecord
CDRECORD_OPT= -dev=\${CDRDEV} -speed=\${CDRSPEED} driveropts=burnfree

all:	bootcd

makeip.tar.gz:
	\${FTP} \${MAKEIP_TAR_GZ_URL}

makeip:	makeip.tar.gz
	\${TAR} -zxf makeip.tar.gz
	\${CC} -O -o makeip makeip.c

IP.BIN:	makeip
	./makeip ip.txt IP.BIN

scramble.c:
	\${FTP} \${SCRAMBLE_C_URL}

scramble: scramble.c
	\${CC} -O -o \${.TARGET} scramble.c

\${KERNEL_BIN}.gz:
	\${FTP} http://\${FTP_HOST}/\${FTP_PATH}/dreamcast/binary/kernel/\${.TARGET}

\${KERNEL_BIN}: \${KERNEL_BIN}.gz
	\${GZIP} -dc \${KERNEL_BIN}.gz > \${KERNEL_BIN}

1ST_READ.BIN: scramble \${KERNEL_BIN}
	./scramble \${KERNEL_BIN} \${.TARGET}

\${MKISOFS} \${CDRECORD}:
	pkg_add http://\${PACKAGES_HOST}/\${PACKAGESDIR}/All/cdrtools

data.iso: \${MKISOFS} 1ST_READ.BIN
	\${MKISOFS} -R -l -C 0,11702 -o \${.TARGET} 1ST_READ.BIN

data.raw: IP.BIN data.iso
	( cat IP.BIN ; dd if=data.iso bs=2048 skip=16 ) > \${.TARGET}

audio.raw:
	dd if=/dev/zero bs=2352 count=300 of=\${.TARGET}

bootcd:	\${CDRECORD} data.raw audio.raw
	\${CDRECORD} \${CDRECORD_OPT} -multi -tao -audio audio.raw
	\${CDRECORD} \${CDRECORD_OPT} -multi -tao -xa data.raw
	# see cdrecord(1) man page about -xa vs -xa1 options

clean:
	rm -f data.raw data.iso audio.raw 1ST_READ.BIN
	rm -f IP.BIN
	rm -f makeip scramble
	rm -f IP.TMPL ip.txt makeip.c

cleandir:
	\${MAKE} clean
	rm -f scramble.c
	rm -f makeip.tar.gz
	rm -f \${KERNEL_BIN}.gz
EOF
${CP} ${WORKDIR}/Makefile ${TARGETROOTDIR}/root

echo Preparing spec file for makefs...
# files for DCserv host
${CAT}	${TARGETROOTDIR}/etc/mtree/NetBSD.dist \
	${TARGETROOTDIR}/etc/mtree/special | \
	${SED} -e 's/ size=[0-9]*//' > ${WORKDIR}/spec.${MACHINE}
for set in ${SETS}; do
	if [ -f ${TARGETROOTDIR}/etc/mtree/set.${set} ]; then
		${CAT} ${TARGETROOTDIR}/etc/mtree/set.${set} | \
		    ${SED} -e 's/ size=[0-9]*//' >> ${WORKDIR}/spec.${MACHINE}
	fi
done
${SH} ${TARGETROOTDIR}/dev/MAKEDEV -s all | \
	${SED} -e '/^\. type=dir/d' -e 's,^\.,./dev,' \
	>> ${WORKDIR}/spec.${MACHINE}
# DCserv optional files
${CAT} >> ${WORKDIR}/spec.${MACHINE} <<EOF
./boot				type=file mode=0444
./kern				type=dir  mode=0755
./netbsd			type=file mode=0755
./proc				type=dir  mode=0755
./tmp				type=dir  mode=1777
./root/Makefile			type=file mode=0644
EOF

${MV} ${WORKDIR}/spec.${MACHINE} ${WORKDIR}/spec

echo Creating rootfs...
${TOOLDIR}/bin/nbmakefs -M ${FSSIZE} -B ${TARGET_ENDIAN} \
	-F ${WORKDIR}/spec -N ${TARGETROOTDIR}/etc \
	-o bsize=${BLOCKSIZE},fsize=${FRAGSIZE},density=${DENSITY} \
	${WORKDIR}/rootfs ${TARGETROOTDIR}
if [ ! -f ${WORKDIR}/rootfs ]; then
	echo Failed to create rootfs. Aborted.
	exit 1
fi

echo Installing bootstrap...
${TOOLDIR}/bin/nbinstallboot -v -m ${MACHINE} ${WORKDIR}/rootfs \
    ${TARGETROOTDIR}/usr/mdec/${PRIMARY_BOOT} ${SECONDARY_BOOT_ARG}

echo Creating swap fs
${DD} if=/dev/zero of=${WORKDIR}/swap seek=$((${SWAPSECTORS} - 1)) count=1

echo Copying target disk image...
if [ ${LABELSECTORS} != 0 ]; then
	${DD} if=/dev/zero of=${WORKDIR}/mbrsectors count=${LABELSECTORS}
	${CAT} ${WORKDIR}/mbrsectors ${WORKDIR}/rootfs ${WORKDIR}/swap \
	    > ${IMAGE}
else
	${CAT} ${WORKDIR}/rootfs ${WORKDIR}/swap > ${IMAGE}
fi

if [ ${LABELSECTORS} != 0 ]; then
	echo creating MBR labels...
	${FDISK} -f -u \
	    -b ${MBRCYLINDERS}/${MBRHEADS}/${MBRSECTORS} \
	    -0 -a -s ${MBRNETBSD}/${FSOFFSET}/${BSDPARTSECTORS} \
	    -i -c ${TARGETROOTDIR}/usr/mdec/mbr \
	    -F ${IMAGE}
fi

echo Creating disklabel...
${CAT} > ${WORKDIR}/labelproto <<EOF
type: ESDI
disk: image
label: 
flags:
bytes/sector: 512
sectors/track: ${SECTORS}
tracks/cylinder: ${HEADS}
sectors/cylinder: $((${HEADS} * ${SECTORS}))
cylinders: ${CYLINDERS}
total sectors: ${IMAGESECTORS}
rpm: 3600
interleave: 1
trackskew: 0
cylinderskew: 0
headswitch: 0           # microseconds
track-to-track seek: 0  # microseconds
drivedata: 0 

8 partitions:
#        size    offset     fstype [fsize bsize cpg/sgs]
a:    ${FSSECTORS} ${FSOFFSET} 4.2BSD ${FRAGSIZE} ${BLOCKSIZE} 128
b:    ${SWAPSECTORS} ${SWAPOFFSET} swap
c:    ${BSDPARTSECTORS} ${FSOFFSET} unused 0 0
d:    ${IMAGESECTORS} 0 unused 0 0
EOF

${DISKLABEL} -R -M ${MACHINE} -F ${IMAGE} ${WORKDIR}/labelproto

echo Creating gzipped image...
${GZIP} -9c ${WORKDIR}/${MACHINE}.img > ${WORKDIR}/${PROG}-${VERSION}.img.gz.tmp
${MV} ${WORKDIR}/${PROG}-${VERSION}.img.gz.tmp ${WORKDIR}/${PROG}-${VERSION}.img.gz
(cd ${WORKDIR} ; ${CKSUM} -a sha512 ${PROG}-${VERSION}.img.gz > SHA512 )
(cd ${WORKDIR} ; ${CKSUM} -a md5 ${PROG}-${VERSION}.img.gz > MD5)

echo Creating ${PROG}-${VERSION} image complete.

if [ "${TESTIMAGE}" != "yes" ]; then exit; fi

#
# for test on emulators...
#
if [ "${MACHINE}" = "amd64" -a -x /usr/pkg/bin/qemu-system-x86_64 ]; then
	qemu-system-x86_64 -hda ${IMAGE} -boot c
fi
if [ "${MACHINE}" = "i386" -a -x /usr/pkg/bin/qemu ]; then
	qemu -hda ${IMAGE} -boot c
fi
