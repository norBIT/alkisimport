PKG=alkis-import-dev
VERSION = 2.99
P=$(shell cat .pkg-$(VERSION) || echo 1)

O4W=osgeo4w/apps/$(PKG)
INSTFILES=\
	alkis-import.sh re refilter.py custom \
	alkisImport.py alkisImportDlg.ui about.ui logo.ico logo.svg \
	alkis-schema.sql \
	alkis-schema.gfs \
	alkis-init.sql \
	alkis-clean.sql \
	alkis-update.sql \
	alkis-functions.sql \
	alkis-compat.sql \
	alkis-signaturen.sql \
	alkis-punktsignaturen.sql \
	alkis-wertearten.sql \
	alkis-wertearten-nrw.sql \
	alkis-po-tables.sql \
	alkis-ableitungsregeln.sql \
	cleanGeometry.sql \
	postcreate.d/nas2alb.sql \
	postupdate.d/nas2alb.sql \
	postprocessing.d/nas2alb.sql \
	postprocessing.d/postnas-keytables.sql

all:

%.py: %.qrc
	pyrcc4 -o $@ $^

package:
	mkdir -p osgeo4w/apps/$(PKG)/postprocessing.d osgeo4w/bin osgeo4w/etc/postinstall osgeo4w/etc/preremove
	git archive --format=tar --prefix=$(O4W)/ HEAD | tar -xf - $(addprefix $(O4W)/,$(INSTFILES))
	cp alkis-import.cmd osgeo4w/bin/$(PKG).cmd
	cp postinstall.bat osgeo4w/etc/postinstall/$(PKG).cmd
	cp preremove.bat osgeo4w/etc/preremove/$(PKG).cmd
	perl -i -pe 's/#VERSION#/$(VERSION)-$(P)/' osgeo4w/apps/$(PKG)/about.ui osgeo4w/apps/$(PKG)/alkisImportDlg.ui
	tar -C osgeo4w --remove-files -cjf osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2 apps bin etc

osgeo4w: package
	for i in x86 x86_64; do rsync setup.hint osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2 upload.osgeo.org:osgeo4w/$$i/release/$(PKG)/; done
	wget -O - http://upload.osgeo.org/cgi-bin/osgeo4w-regen.sh
	echo $$(( $(P) + 1 )) >.pkg-$(VERSION)

archive:
	mkdir -p archive
	git archive --format=tar --prefix=$(PKG)/ HEAD | bzip2 >archive/$(PKG)-$(VERSION)-$(P).tar.bz2

.PHONY: osgeo4w archive package
