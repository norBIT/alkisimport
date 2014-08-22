VERSION = 1.0
P=$(shell cat .pkg || echo 1)

all:

%.py: %.qrc
	pyrcc4 -o $@ $^

osgeo4w:
	mkdir -p osgeo4w/apps/alkis-import/postprocessing.d osgeo4w/bin osgeo4w/etc/postinstall osgeo4w/etc/preremove
	cp alkis-import.cmd osgeo4w/bin
	cp alkis-import.sh re refilter.py alkis-ableitungsregeln.sql alkis-compat.sql alkis-functions.sql alkis-nutzung-und-klassifizierung.sql alkis-schema.sql alkis-signaturen.sql alkis-trigger.sql alkis-wertearten.sql alkisImport.py alkisImportDlg.ui about.ui cleanGeometry.sql custom logo.ico logo.svg osgeo4w/apps/alkis-import
	cp postprocessing.d/nas2alb.sql osgeo4w/apps/alkis-import/postprocessing.d
	cp postinstall.bat osgeo4w/etc/postinstall/alkis-import.cmd
	cp preremove.bat osgeo4w/etc/preremove/alkis-import.cmd
	tar -C osgeo4w -cjf alkis-import-$(VERSION)-$(P).tar.bz2 apps bin etc
	for i in x86 x86_64; do rsync setup.hint alkis-import-$(VERSION)-$(P).tar.bz2 upload.osgeo.org:osgeo4w/$$i/release/alkis-import/; done
	wget -O - http://upload.osgeo.org/cgi-bin/osgeo4w-regen.sh
	echo $$(( $(P) + 1 )) >.pkg

.PHONY: osgeo4w
