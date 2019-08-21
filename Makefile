VERSION=1.10
DEBRELEASE=0+really1.8-2
PVERELEASE=pve2

BUILDDIR=kronosnet-${VERSION}
SRC_SUBMODULE=upstream

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

MAIN_DEB=libknet1_${VERSION}-${PVERELEASE}_${ARCH}.deb
OTHER_DEBS=								\
	libknet-dev_${VERSION}-${PVERELEASE}_${ARCH}.deb			\
	libknet-doc_${VERSION}-${PVERELEASE}_all.deb			\
	libknet1-dbgsym_${VERSION}-${PVERELEASE}_${ARCH}.deb		\
	libnozzle1-dbgsym_${VERSION}-${PVERELEASE}_${ARCH}.deb		\
	libnozzle-dev_${VERSION}-${PVERELEASE}_${ARCH}.deb		\
	libnozzle1_${VERSION}-${PVERELEASE}_${ARCH}.deb

DEBS=${MAIN_DEB} ${OTHER_DEBS}
DSC=kronosnet-${VERSION}-${PVERELEASE}.dsc

all:
	ls -1 ${DEBS}

${BUILDDIR}: upstream/README patches/*
	rm -rf ${BUILDDIR}
	cp -a upstream ${BUILDDIR}
	cp -a debian/ ${BUILDDIR}
	cd ${BUILDDIR}; ln -s ../patches patches
	cd ${BUILDDIR}; quilt push -a
	cd ${BUILDDIR}; rm -rf .pc ./patches

deb: ${DEBS}
${OTHER_DEBS}: ${MAIN_DEB}
${MAIN_DEB}: ${BUILDDIR}
	cd ${BUILDDIR}; dpkg-buildpackage -b -us -uc
	lintian ${MAIN_DEB} ${OTHER_DEBS}

dsc: ${DSC}
${DSC}: ${BUILDDIR}
	cd ${BUILDDIR}; dpkg-buildpackage -S -us -uc -d -nc

# make sure submodules were initialized
.PHONY: submodule
submodule:
	test -f "${SRC_SUBMODULE}/README" || git submodule update --init ${SRC_SUBMODULE}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com upload

.PHONY: clean
clean:
	rm -rf *~ *.deb *.changes *.dsc ${BUILDDIR} *.orig.tar.xz *.debian.tar.xz *.buildinfo

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
