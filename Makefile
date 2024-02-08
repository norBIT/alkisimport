SHELL=bash
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
PKG=alkis-import$(shell git rev-parse --abbrev-ref HEAD | sed -e "s/^/-/; /^-master$$/d")
GID=7.1.2
SHORTCUT=$(shell echo " ($(BRANCH))" | grep -Fxv " (master)")
VERSION=4.1

P=$(shell cat .pkg-$(PKG)-$(VERSION) 2>/dev/null || echo 1)
O4WPKG=osgeo4w/$(PKG)-$(VERSION)-$(P).tar.bz2
O4WSRCPKG=osgeo4w/$(PKG)-$(VERSION)-$(P)-src.tar.bz2

all:
	@echo "PKG:$(PKG)"
	@echo "VERSION:$(VERSION)"
	@echo "BINARY:$(P)"
	@echo "SHORTCUT:$(SHORTCUT)"
	@echo "O4WPKG:$(O4WPKG)"
	@echo "O4WSRCPKG:$(O4WSRCPKG)"

$(O4WSRCPKG):
	# empty
	tar -cjf $(O4WSRCPKG) -T /dev/null

package: $(O4WPKG)

$(O4WPKG): tables.lst alkis-functions.sql alkis-import.cmd postinstall.bat preremove.bat
	mkdir -p osgeo4w/{apps/$(PKG)/{preprocessing,postprocessing}.d,bin,etc/{postinstall,preremove}}

	git tag osgeo4w-$(VERSION)-$(P)
	git archive --format=tar --prefix=osgeo4w/apps/$(PKG)/ HEAD | tar -xf -
	cp alkis-functions.sql osgeo4w/apps/$(PKG)/
	sed -e "s/@PKG@/$(PKG)/g; s/@VERSION/$(VERSION)/g; s/@SHORTCUT@/$(SHORTCUT)/g;" alkis-import.cmd >osgeo4w/bin/$(PKG).cmd
	sed -e "s/@PKG@/$(PKG)/g; s/@VERSION/$(VERSION)/g; s/@SHORTCUT@/$(SHORTCUT)/g;" postinstall.bat >osgeo4w/etc/postinstall/$(PKG).bat
	sed -e "s/@PKG@/$(PKG)/g; s/@VERSION/$(VERSION)/g; s/@SHORTCUT@/$(SHORTCUT)/g;" preremove.bat >osgeo4w/etc/preremove/$(PKG).bat
	cp tables.lst osgeo4w/apps/$(PKG)/
	perl -i -pe 's/#VERSION#/$(VERSION)-$(P)/' osgeo4w/apps/$(PKG)/{about.ui,alkisImportDlg.ui}
	tar -C osgeo4w --remove-files -cjf $(O4WPKG) apps bin etc

upload: versioncheck $(O4WPKG) $(O4WSRCPKG)
	sed -e "s/@GID@/$(GID)/" setup.hint >osgeo4w/setup.hint
	rsync --chmod=D775,F664 osgeo4w/setup.hint $(O4WPKG) $(O4WSRCPKG) upload.osgeo.org:osgeo4w/v2/x86_64/release/$(PKG)/
	wget -O - https://download.osgeo.org/cgi-bin/osgeo4w-regen-v2.sh
	echo $$(( $(P) + 1 )) >.pkg-$(PKG)-$(VERSION)

alkis-functions.sql tables.lst: alkis-functions.sql.in alkis-schema.sql alkis-schema.gfs
	sed -ne 's/^CREATE TABLE \([^ ]*\) (.*$$/\1/p' alkis-schema.sql | sort -u >tables.tmp
	sed -ne 's/^INSERT INTO \([^(]*\) (.*$$/\1/p' alkis-schema.sql | sort -u >catalogs.tmp
	sed -ne "s/^    <Name>\(.*\)<\/Name>/\1/p;" alkis-schema.gfs | sort -u >datatables.tmp
	paste -s -d "," <tables.tmp >tables.lst
	sed \
		-e "s#@TABLES@#('$$(paste -s tables.tmp | sed -e "s/\t/','/g")')#" \
		-e "s#@CATALOGS@#('$$(paste -s catalogs.tmp | sed -e "s/\t/','/g")')#" \
		-e "s#@DATATABLES@#('$$(paste -s datatables.tmp | sed -e "s/\t/','/g")')#" \
		alkis-functions.sql.in >alkis-functions.sql
	rm tables.tmp catalogs.tmp datatables.tmp

versioncheck:
	curl -s https://download.osgeo.org/osgeo4w/v2/x86_64/setup.ini | \
		sed -ne '/@ $(PKG)$$/,/^$$/ {0,/^version:/ { s/^version: \([^-]*\)-\(.*\)/\1\n\2/p} }' | \
			( read v; read b; [ $$( ( echo $(VERSION).$(P); echo $$v.$$b ) | sort -V | tail -1 ) == "$(VERSION).$(P)" ] || { echo $(VERSION)-$(P) not higher than $$v-$$b; false; } )

test:
	curl -O https://hvbg.hessen.de/sites/hvbg.hessen.de/files/2023-01/referenztestdaten_711_alkis_0536040.zip

.PHONY: upload package
