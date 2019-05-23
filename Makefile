VERSION=1.8
DEBRELEASE=2
PVERELEASE=1

BUILDDIR=kronosnet-${VERSION}
SRCARCHIVE=kronosnet_${VERSION}.orig.tar.xz
DEBARCHIVE=kronosnet_${VERSION}-${DEBRELEASE}.debian.tar.xz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

MAIN_DEB=libknet1_${VERSION}-${PVERELEASE}_${ARCH}.deb
OTHER_DEBS=								\
	libknet-dev_${VERSION}-${PVERELEASE}_${ARCH}.deb			\
	libknet-doc_${VERSION}-${PVERELEASE}_all.deb			\
	libknet1-dbgsym_${VERSION}-${PVERELEASE}_${ARCH}.deb		\
	libnozzle1-dbgsym_${VERSION}-${PVERELEASE}_${ARCH}.deb		\
	libnozzle1-dev_${VERSION}-${PVERELEASE}_${ARCH}.deb		\

DEBS=${MAIN_DEB} ${OTHER_DEBS}
DSC=kronosnet-${VERSION}-${PVERELEASE}.dsc

all: ${DEBS}
	echo ${DEBS}

${BUILDDIR}: upstream/${SRCARCHIVE} upstream/${DEBARCHIVE} patches/*
	rm -rf ${BUILDDIR}
	ln -sf upstream/${SRCARCHIVE} ${SRCARCHIVE}
	tar -xf upstream/${SRCARCHIVE}
	tar -C ${BUILDDIR} -xf upstream/${DEBARCHIVE}
	cd ${BUILDDIR}; ln -s ../patches patches
	cd ${BUILDDIR}; quilt push -a
	cd ${BUILDDIR}; rm -rf .pc ./patches

deb: ${DEBS}
${OTHER_DEBS}: ${MAIN_DEB}
${MAIN_DEB}: ${BUILDDIR}
	cd ${BUILDDIR}; dpkg-buildpackage -b -us -uc

dsc: ${DSC}
${DSC}: ${BUILDDIR}
	cd ${BUILDDIR}; dpkg-buildpackage -S -us -uc -d -nc

download:
	rm -rf upstream/
	mkdir upstream
	cd upstream; dget https://deb.debian.org/debian/pool/main/k/kronosnet/kronosnet_${VERSION}-${DEBRELEASE}.dsc
	cd upstream; rm -rf *.asc *.dsc ${BUILDDIR}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com upload

.PHONY: clean
clean:
	rm -rf *~ *.deb *.changes *.dsc ${BUILDDIR} *.orig.tar.xz *.debian.tar.xz *.buildinfo

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
