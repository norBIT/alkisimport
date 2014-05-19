DESTDIR = //zeus/runtime/norBIT/norGIS-ALKIS-Import/unstable

all: alkisImportDlg.py

update: all
	rsync -avpP \
		$(O) \
		--exclude "*.pyc" \
		alkis-ableitungsregeln.sql \
		alkis-compat.sql \
		alkis-functions.sql \
		alkis-import.cmd \
		alkisImport.py \
		alkis-import.sh \
		alkisImportDlg.py \
		alkis-nutzung-und-klassifizierung.sql \
		alkis-schema.sql \
		alkis-signaturen.sql \
		alkis-trigger.sql \
		alkis-wertearten.sql \
		alkisImportDlg.ui \
		cleanGeometry.sql \
		gdal-dev \
		logo.png \
		logo.ico \
		postprocessing.d \
		custom \
		re \
		refilter.py \
		$(DESTDIR)

diff:
	-diff -ur \
		--exclude=".git" \
		--exclude=".gitignore" \
		--exclude="*.pyc" \
		--exclude="*.gfs" \
		--exclude="*.xml*" \
		--exclude="*.log" \
		--exclude="*.lst" \
		--exclude="*.zip" \
		--exclude="share" \
		$(DESTDIR) \
		.

%.py: %.ui
	pyuic4 -o $@ $^

%.py: %.qrc
	pyrcc4 -o $@ $^
