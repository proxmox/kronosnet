include /usr/share/dpkg/pkg-info.mk
include /usr/share/dpkg/architecture.mk

VERSION=$(DEB_VERSION_UPSTREAM)

PACKAGE=kronosnet
BUILDDIR=$(PACKAGE)-$(VERSION)
ORIG_SRC_TAR=$(PACKAGE)_$(DEB_VERSION_UPSTREAM).orig.tar.gz
SRC_SUBMODULE=upstream

ARCH=$(DEB_BUILD_ARCH)

MAIN_DEB=libknet1_$(DEB_VERSION)_$(ARCH).deb
OTHER_DEBS=								\
	libknet-dev_$(DEB_VERSION)_$(ARCH).deb			\
	libknet-doc_$(DEB_VERSION)_all.deb			\
	libknet1-dbgsym_$(DEB_VERSION)_$(ARCH).deb		\
	libnozzle1-dbgsym_$(DEB_VERSION)_$(ARCH).deb		\
	libnozzle-dev_$(DEB_VERSION)_$(ARCH).deb		\
	libnozzle1_$(DEB_VERSION)_$(ARCH).deb

DEBS=$(MAIN_DEB) $(OTHER_DEBS)
DSC=kronosnet-$(DEB_VERSION).dsc

all:
	ls -1 $(DEBS)

$(BUILDDIR): $(SRC_SUBMODULE)/README
	rm -rf $(BUILDDIR)
	cp -a upstream $(BUILDDIR)
	echo "$(DEB_VERSION_UPSTREAM)" >$(BUILDDIR)/.tarball-version
	cp -a debian/ $(BUILDDIR)

deb: $(DEBS)
$(OTHER_DEBS): $(MAIN_DEB)
$(MAIN_DEB): $(BUILDDIR)
	cd $(BUILDDIR); dpkg-buildpackage -b -us -uc
	lintian $(MAIN_DEB) $(OTHER_DEBS)

$(ORIG_SRC_TAR): $(BUILDDIR)
	tar czf $(ORIG_SRC_TAR) --exclude="$(BUILDDIR)/debian" $(BUILDDIR)

dsc: $(DSC)
$(DSC): $(BUILDDIR) $(ORIG_SRC_TAR)
	cd $(BUILDDIR); dpkg-buildpackage -S -us -uc -d -nc

# make sure submodules were initialized
.PHONY: submodule
submodule:
	test -f "$(SRC_SUBMODULE)/README" || git submodule update --init $(SRC_SUBMODULE)

.PHONY: upload
upload: UPLOAD_DIST ?= $(DEB_DISTRIBUTION)
upload: $(DEBS)
	tar cf - $(DEBS) | ssh repoman@repo.proxmox.com upload --product pve --dist $(UPLOAD_DIST)

.PHONY: clean
clean:
	rm -rf *~ *.deb *.changes *.dsc $(BUILDDIR) *.orig.tar.xz *.debian.tar.xz *.buildinfo

.PHONY: dinstall
dinstall: $(DEBS)
	dpkg -i $(DEBS)
