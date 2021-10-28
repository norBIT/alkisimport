PKG=alkis-import
VERSION = 3.0
P=$(shell cat .pkg-$(VERSION) || echo 1)

M=osgeo4w/main
T=osgeo4w/v2

all:

package:
	mkdir -p {$(M),$(T)}/{apps/$(PKG)/{preprocessing,postprocessing}.d,bin,etc/{postinstall,preremove}}

	git archive --format=tar --prefix=$(M)/apps/$(PKG)/ HEAD | tar -xf -
	cp alkis-import.cmd $(M)/bin/$(PKG).cmd
	cp postinstall.bat $(M)/etc/postinstall/$(PKG).bat
	cp preremove.bat $(M)/etc/preremove/$(PKG).bat
	perl -i -pe 's/#VERSION#/$(VERSION)-$(P)/' $(M)/apps/$(PKG)/{about.ui,alkisImportDlg.ui}
	! [ -f $(M)/$(PKG)-$(VERSION)-$(P).tar.bz2 ]
	tar -C $(M) --remove-files -cjf $(M)/$(PKG)-$(VERSION)-$(P).tar.bz2 apps bin etc
	cp setup.hint $(M)/setup.hint

	git archive --format=tar --prefix=$(T)/apps/$(PKG)/ HEAD | tar -xf -
	cp alkis-import-osgeo4w-v2.cmd $(T)/bin/$(PKG).cmd
	cp postinstall-osgeo4w-v2.bat $(T)/etc/postinstall/$(PKG).bat
	cp preremove.bat $(T)/etc/preremove/$(PKG).bat
	perl -i -pe 's/#VERSION#/$(VERSION)-$(P)/' $(T)/apps/$(PKG)/{about.ui,alkisImportDlg.ui}
	! [ -f $(T)/$(PKG)-$(VERSION)-$(P).tar.bz2 ]
	tar -C $(T) --remove-files -cjf $(T)/$(PKG)-$(VERSION)-$(P).tar.bz2 apps bin etc
	tar -cjf $(T)/$(PKG)-$(VERSION)-$(P)-src.tar.bz2 -T /dev/null
	cp setup-osgeo4w-v2.hint $(T)/setup.hint

osgeo4w: package
	for i in x86 x86_64; do rsync --chmod=D775,F664 $(M)/setup.hint $(M)/$(PKG)-$(VERSION)-$(P).tar.bz2 upload.osgeo.org:osgeo4w/$$i/release/$(PKG)/; done
	wget -O - https://download.osgeo.org/cgi-bin/osgeo4w-regen.sh
	wget -O - https://download.osgeo.org/cgi-bin/osgeo4w-promote.sh

	rsync --chmod=D775,F664 $(T)/setup.hint $(T)/$(PKG)-$(VERSION)-$(P){,-src}.tar.bz2 upload.osgeo.org:osgeo4w/v2/x86_64/release/$(PKG)/
	wget -O - https://download.osgeo.org/cgi-bin/osgeo4w-regen-v2.sh

	echo $$(( $(P) + 1 )) >.pkg-$(VERSION)

archive:
	mkdir -p archive
	! [ -f archive/$(PKG)-$(VERSION)-$(P).tar.bz2 ]
	git archive --format=tar --prefix=$(PKG)/ HEAD | bzip2 >archive/$(PKG)-$(VERSION)-$(P).tar.bz2

.PHONY: osgeo4w archive package
