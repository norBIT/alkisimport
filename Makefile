PKG=alkis-import
VERSION = 3.0
P=$(shell cat .pkg-$(VERSION) || echo 1)

all:

osgeo4w/$(PKG)-$(VERSION)-$(P)-src.tar.bz2:
	tar -cjf osgeo4w/$(PKG)-$(VERSION)-$(P)-src.tar.bz2 -T /dev/null

osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2:
	mkdir -p osgeo4w/{apps/$(PKG)/{preprocessing,postprocessing}.d,bin,etc/{postinstall,preremove}}

	git archive --format=tar --prefix=osgeo4w/apps/$(PKG)/ HEAD | tar -xf -
	cp alkis-import.cmd osgeo4w/bin/$(PKG).cmd
	cp postinstall.bat osgeo4w/etc/postinstall/$(PKG).bat
	cp preremove.bat osgeo4w/etc/preremove/$(PKG).bat
	perl -i -pe 's/#VERSION#/$(VERSION)-$(P)/' osgeo4w/apps/$(PKG)/{about.ui,alkisImportDlg.ui}
	tar -C osgeo4w --remove-files -cjf osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2 apps bin etc

osgeo4w/setup.hint:
	cp setup.hint osgeo4w/setup.hint

osgeo4w: osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2 osgeo4w/$(PKG)-$(VERSION)-$(P)-src.tar.bz2 osgeo4w/setup.hint
	rsync --chmod=D775,F664 osgeo4w/setup.hint osgeo4w/$(PKG)-$(VERSION)-$(P){,-src}.tar.bz2 upload.osgeo.org:osgeo4w/v2/x86_64/release/$(PKG)/
	wget -O - https://download.osgeo.org/cgi-bin/osgeo4w-regen-v2.sh

	echo $$(( $(P) + 1 )) >.pkg-$(VERSION)

archive:
	mkdir -p archive
	! [ -f archive/$(PKG)-$(VERSION)-$(P).tar.bz2 ]
	git archive --format=tar --prefix=$(PKG)/ HEAD | bzip2 >archive/$(PKG)-$(VERSION)-$(P).tar.bz2

.PHONY: osgeo4w archive package
