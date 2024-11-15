SHELL=bash
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
PKG=alkis-import$(shell git rev-parse --abbrev-ref HEAD | sed -e "s/^/-/; /^-master$$/d")
GID=6.0
SHORTCUT=$(shell echo " ($(BRANCH))" | grep -Fxv " (master)")
VERSION=3.0

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
	d=$$(mktemp -d); tar -C $$d -cjf $(O4WSRCPKG) .; rmdir $$d

package: $(O4WPKG) $(O4WSRCPKG)

$(O4WPKG): alkis-import.cmd postinstall.bat preremove.bat
	mkdir -p osgeo4w/{apps/$(PKG)/{preprocessing,postprocessing}.d,bin,etc/{postinstall,preremove}}

	git tag osgeo4w-$(VERSION)-$(P) -m osgeo4w-$(VERSION)-$(P)
	git archive --format=tar --prefix=osgeo4w/apps/$(PKG)/ HEAD | tar -xf -
	sed -e "s/@PKG@/$(PKG)/g; s/@VERSION/$(VERSION)/g; s/@SHORTCUT@/$(SHORTCUT)/g;" alkis-import.cmd >osgeo4w/bin/$(PKG).cmd
	sed -e "s/@PKG@/$(PKG)/g; s/@VERSION/$(VERSION)/g; s/@SHORTCUT@/$(SHORTCUT)/g;" postinstall.bat >osgeo4w/etc/postinstall/$(PKG).bat
	sed -e "s/@PKG@/$(PKG)/g; s/@VERSION/$(VERSION)/g; s/@SHORTCUT@/$(SHORTCUT)/g;" preremove.bat >osgeo4w/etc/preremove/$(PKG).bat
	perl -i -pe 's/#VERSION#/$(VERSION)-$(P)/' osgeo4w/apps/$(PKG)/{about.ui,alkisImportDlg.ui}
	tar -C osgeo4w --remove-files -cjf $(O4WPKG) apps bin etc

upload: versioncheck $(O4WPKG) $(O4WSRCPKG)
	sed -e "s/@GID@/$(GID)/" setup.hint >osgeo4w/setup.hint
	rsync --chmod=D775,F664 osgeo4w/setup.hint $(O4WPKG) $(O4WSRCPKG) upload.osgeo.org:osgeo4w/v2/x86_64/release/$(PKG)/
	wget -O - https://download.osgeo.org/cgi-bin/osgeo4w-regen-v2.sh
	echo $$(( $(P) + 1 )) >.pkg-$(PKG)-$(VERSION)

versioncheck:
	curl -s https://download.osgeo.org/osgeo4w/v2/x86_64/setup.ini | \
		sed -ne '/@ $(PKG)$$/,/^$$/ {0,/^version:/ { s/^version: \([^-]*\)-\(.*\)/\1\n\2/p} }' | \
			( read v; read b; [ $$( ( echo $(VERSION).$(P); echo $$v.$$b ) | sort -V | tail -1 ) == "$(VERSION).$(P)" ] || { echo $(VERSION)-$(P) not higher than $$v-$$b; false; } )

.PHONY: upload package
