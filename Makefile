DESTDIR = //zeus/runtime/norBIT/norGIS-ALKIS-Import/

all: alkisImportDlg.py

diff:
	diff -wur --exclude "*.pyc" --exclude Makefile --exclude alkis-import-env.cmd --exclude .git $(DESTDIR) .

update: all
	rsync -avpP \
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
		gdal-dev \
		logo.png \
		logo.ico \
		nas2alb.sql \
		re \
		refilter.py \
		$(DESTDIR)

%.py: %.ui
	pyuic4 -o $@ $^

%.py: %.qrc
	pyrcc4 -o $@ $^
