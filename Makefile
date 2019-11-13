PKG=alkis-import
VERSION = 3.0
P=$(shell cat .pkg-$(VERSION) || echo 1)

O4W=osgeo4w/apps/$(PKG)

all:

package:
	mkdir -p osgeo4w/apps/$(PKG)/postprocessing.d osgeo4w/bin osgeo4w/etc/postinstall osgeo4w/etc/preremove
	git archive --format=tar --prefix=$(O4W)/ HEAD | tar -xf -
	cp alkis-import.cmd osgeo4w/bin/$(PKG).cmd
	cp postinstall.bat osgeo4w/etc/postinstall/$(PKG).cmd
	cp preremove.bat osgeo4w/etc/preremove/$(PKG).cmd
	perl -i -pe 's/#VERSION#/$(VERSION)-$(P)/' osgeo4w/apps/$(PKG)/about.ui osgeo4w/apps/$(PKG)/alkisImportDlg.ui
	tar -C osgeo4w --remove-files -cjf osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2 apps bin etc

osgeo4w: package
	for i in x86 x86_64; do rsync setup.hint osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2 upload.osgeo.org:osgeo4w/$$i/release/$(PKG)/; done
	wget -O - https://upload.osgeo.org/cgi-bin/osgeo4w-regen.sh
	wget -O - https://upload.osgeo.org/cgi-bin/osgeo4w-promote.sh
	echo $$(( $(P) + 1 )) >.pkg-$(VERSION)

archive:
	mkdir -p archive
	git archive --format=tar --prefix=$(PKG)/ HEAD | bzip2 >archive/$(PKG)-$(VERSION)-$(P).tar.bz2

.PHONY: osgeo4w archive package
