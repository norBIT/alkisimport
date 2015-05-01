PKG=alkis-import
VERSION = 1.0
P=$(shell cat .pkg || echo 1)

O4W=osgeo4w/apps/$(PKG)
INSTFILES=\
	alkis-import.sh re refilter.py custom \
	alkisImport.py alkisImportDlg.ui about.ui logo.ico logo.svg \
	alkis-schema.sql \
	alkis-update.sql \
	alkis-functions.sql \
	alkis-compat.sql \
	alkis-signaturen.sql \
	alkis-wertearten.sql \
	alkis-po-tables.sql \
	alkis-ableitungsregeln.sql \
	alkis-nutzung-und-klassifizierung.sql \
	cleanGeometry.sql \
	postprocessing.d/nas2alb.sql \
	postprocessing.d/postnas-keytables.sql

all:

%.py: %.qrc
	pyrcc4 -o $@ $^

osgeo4w:
	mkdir -p osgeo4w/apps/$(PKG)/postprocessing.d osgeo4w/bin osgeo4w/etc/postinstall osgeo4w/etc/preremove
	git archive --format=tar --prefix=$(O4W)/ HEAD | tar -xf - $(addprefix $(O4W)/,$(INSTFILES))
	cp alkis-import.cmd osgeo4w/bin
	cp postinstall.bat osgeo4w/etc/postinstall/$(PKG).cmd
	cp preremove.bat osgeo4w/etc/preremove/$(PKG).cmd
	tar -C osgeo4w --remove-files -cjf osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2 apps bin etc
	for i in x86 x86_64; do rsync setup.hint osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2 upload.osgeo.org:osgeo4w/$$i/release/$(PKG)/; done
	wget -O - http://upload.osgeo.org/cgi-bin/osgeo4w-regen.sh
	echo $$(( $(P) + 1 )) >.pkg

archive:
	mkdir -p archive
	git archive --format=tar --prefix=$(PKG)/ HEAD | bzip2 >archive/$(PKG)-$(VERSION)-$(P).tar.bz2

.PHONY: osgeo4w archive
