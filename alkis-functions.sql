-- Table/View/Sequence löschen, wenn vorhanden
CREATE OR REPLACE FUNCTION alkis_dropobject(t TEXT) RETURNS varchar AS $$
DECLARE
	c RECORD;
	s varchar;
	r varchar;
	d varchar;
	i integer;
	tn varchar;
BEGIN
	r := '';
	d := '';

	-- drop objects
	FOR c IN SELECT relkind,relname
		FROM pg_class
		JOIN pg_namespace ON pg_class.relnamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_class.relname=t
		ORDER BY relkind
	LOOP
		IF c.relkind = 'v' THEN
			r := r || d || 'Sicht ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP VIEW ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'r' THEN
			r := r || d || 'Tabelle ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP TABLE ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'S' THEN
			r := r || d || 'Sequenz ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP SEQUENCE ' || c.relname;
		ELSIF c.relkind <> 'i' THEN
			r := r || d || 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.';
		END IF;
		d := E'\n';
	END LOOP;

	FOR c IN SELECT indexname FROM pg_indexes WHERE schemaname='public' AND indexname=t
	LOOP
		r := r || d || 'Index ' || c.indexname || ' gelöscht.';
		EXECUTE 'DROP INDEX ' || c.indexname;
		d := E'\n';
	END LOOP;

	FOR c IN SELECT proname,proargtypes
		FROM pg_proc
		JOIN pg_namespace ON pg_proc.pronamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_proc.proname=t
	LOOP
		r := r || d || 'Funktion ' || c.proname || ' gelöscht.';

		s := 'DROP FUNCTION ' || c.proname || '(';
		d := '';

		FOR i IN array_lower(c.proargtypes,1)..array_upper(c.proargtypes,1) LOOP
			SELECT typname INTO tn FROM pg_type WHERE oid=c.proargtypes[i];
			s := s || d || tn;
			d := ',';
		END LOOP;

		s := s || ')';

		EXECUTE s;

		d := E'\n';
	END LOOP;

	FOR c IN SELECT relname,conname
		FROM pg_constraint
		JOIN pg_class ON pg_constraint.conrelid=pg_constraint.oid
		JOIN pg_namespace ON pg_constraint.connamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_constraint.conname=t
	LOOP
		r := r || d || 'Constraint ' || c.conname || ' von ' || c.relname || ' gelöscht.';
		EXECUTE 'ALTER TABLE ' || c.relname || ' DROP CONSTRAINT ' || c.conname;
		d := E'\n';
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen löschen
SELECT alkis_dropobject('alkis_drop');
CREATE FUNCTION alkis_drop() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR;
	d VARCHAR;
BEGIN
	r := '';
	d := '';
	-- drop tables & views
	FOR c IN SELECT table_type,table_name FROM information_schema.tables WHERE table_schema='public' AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_') OR table_name IN ('alkis_beziehungen','delete')) ORDER BY table_type DESC LOOP
		IF c.table_type = 'VIEW' THEN
			r := r || d || 'Sicht ' || c.table_name || ' gelöscht.';
			EXECUTE 'DROP VIEW ' || c.table_name || ' CASCADE';
		ELSIF c.table_type = 'BASE TABLE' THEN
			r := r || d || 'Tabelle ' || c.table_name || ' gelöscht.';
			EXECUTE 'DROP TABLE ' || c.table_name || ' CASCADE';
		ELSE
			r := r || d || 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.';
		END IF;
		d := E'\n';
	END LOOP;

	-- clean geometry_columns
	DELETE FROM geometry_columns
		WHERE f_table_schema='public'
		AND ( substr(f_table_name,1,2) IN ('ax_','ap_','ks_')
		 OR f_table_name IN ('alkis_beziehungen','delete') );

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen leeren
SELECT alkis_dropobject('alkis_delete');
CREATE FUNCTION alkis_delete() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r varchar;
	d varchar;
BEGIN
	r := '';
	d := '';

	-- drop views
	FOR c IN
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema='public' AND table_type='BASE TABLE'
		  AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_')
			OR table_name IN ('alkis_beziehungen','delete') )
	LOOP
		r := r || d || c.table_name || ' wurde geleert.';
		EXECUTE 'DELETE FROM '||c.table_name;
		d := E'\n';
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Übersicht erzeugen, die alle alkis_beziehungen mit den Typen der beteiligen ALKIS-Objekte versieht
SELECT alkis_dropobject('alkis_mviews');
CREATE FUNCTION alkis_mviews() RETURNS varchar AS $$
DECLARE
	sql TEXT;
	delim TEXT;
	c RECORD;
BEGIN
	SELECT alkis_dropobject('vbeziehungen') INTO sql;
	SELECT alkis_dropobject('vobjekte') INTO sql;

	delim := '';
	sql := 'CREATE VIEW vobjekte AS ';

	FOR c IN SELECT table_name FROM information_schema.columns WHERE column_name='gml_id' AND substr(table_name,1,3) IN ('ax_','ap_','ks_') LOOP
		sql := sql || delim || 'SELECT gml_id,beginnt,''' || c.table_name || ''' AS table_name FROM ' || c.table_name;
		delim := ' UNION ';
	END LOOP;

	EXECUTE sql;

--	CREATE UNIQUE INDEX vobjekte_gmlid ON vobjekte(gml_id,beginnt);
--	CREATE INDEX vobjekte_table ON vobjekte(table_name);

	CREATE VIEW vbeziehungen AS
		SELECT	beziehung_von,(SELECT table_name FROM vobjekte WHERE gml_id=beziehung_von) AS typ_von
			,beziehungsart
			,beziehung_zu,(SELECT table_name FROM vobjekte WHERE gml_id=beziehung_zu) AS typ_zu
		FROM alkis_beziehungen;

--	CREATE INDEX vbeziehungen_von    ON vbeziehungen(beziehung_von);
--	CREATE INDEX vbeziehungen_vontyp ON vbeziehungen(typ_von);
--	CREATE INDEX vbeziehungen_art    ON vbeziehungen(beziehungsart);
--	CREATE INDEX vbeziehungen_zu     ON vbeziehungen(beziehung_zu);
--	CREATE INDEX vbeziehungen_zutyp  ON vbeziehungen(typ_zu);

	RETURN 'ALKIS-Views erzeugt.';
END;
$$ LANGUAGE plpgsql;

-- Indizes erzeugen
SELECT alkis_dropobject('alkis_update_schema');
CREATE FUNCTION alkis_update_schema() RETURNS varchar AS $$
DECLARE
	sql TEXT;
	c RECORD;
	i RECORD;
	n INTEGER;
BEGIN
	-- Spalten in delete ergänzen
	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='ignored';
	IF n=0 THEN
		ALTER TABLE "delete" ADD ignored BOOLEAN;
	END IF;

	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='context';
	IF n=0 THEN
		ALTER TABLE "delete" ADD context VARCHAR;
	END IF;

	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='safetoignore';
	IF n=0 THEN
		ALTER TABLE "delete" ADD safetoignore VARCHAR;
	END IF;

	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='replacedby';
	IF n=0 THEN
		ALTER TABLE "delete" ADD replacedBy VARCHAR;
	END IF;

	-- Spalte identifier ergänzen, wo sie fehlt
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND     EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt'    AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
		AND NOT EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='identifier' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD identifier character(44)';
	END LOOP;

	-- Spalte endet ergänzen, wo sie fehlt
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND     EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
		AND NOT EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='endet'   AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD endet character(20) CHECK (endet>beginnt)';
	END LOOP;

	-- Lebensdauer-Constraint ergänzen
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='endet'   AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		SELECT alkis_dropobject(c.table_name||'_lebensdauer');
		EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD CONSTRAINT ' || c.table_name || '_lebensdauer CHECK (beginnt IS NOT NULL AND endet>beginnt)';
	END LOOP;

	-- Indizes aktualisieren
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		-- Vorhandene Indizes droppen (TODO: Löscht auch die Sonderfälle - entfernen)
		FOR i IN EXECUTE 'SELECT indexname FROM pg_indexes WHERE NOT indexname LIKE ''%_pk'' AND schemaname=''public'' AND tablename='''||c.table_name||'''' LOOP
			EXECUTE 'DROP INDEX ' || i.indexname;
		END LOOP;

		-- Indizes erzeugen
		EXECUTE 'CREATE UNIQUE INDEX ' || c.table_name || '_id ON ' || c.table_name || '(gml_id,beginnt)';
		EXECUTE 'CREATE UNIQUE INDEX ' || c.table_name || '_ident ON ' || c.table_name || '(identifier)';
		EXECUTE 'CREATE INDEX ' || c.table_name || '_gmlid ON ' || c.table_name || '(gml_id)';
		EXECUTE 'CREATE INDEX ' || c.table_name || '_beginnt ON ' || c.table_name || '(beginnt)';
		EXECUTE 'CREATE INDEX ' || c.table_name || '_endet ON ' || c.table_name || '(endet)';
	END LOOP;

	-- Geometrieindizes aktualisieren
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='wkb_geometry' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		EXECUTE 'CREATE INDEX ' || c.table_name || '_geom ON ' || c.table_name || ' USING GIST (wkb_geometry)';
	END LOOP;

	RETURN 'Schema aktualisiert.';
END;
$$ LANGUAGE plpgsql;


-- Löschsatz verarbeiten (MIT Historie)
-- context='delete'        => "endet" auf aktuelle Zeit setzen
-- context='replace'       => "endet" des ersetzten auf "beginnt" des neuen Objekts setzen
CREATE OR REPLACE FUNCTION delete_feature_hist() RETURNS TRIGGER AS $$
DECLARE
	sql TEXT;
	gml_id TEXT;
	endete TEXT;
	n INTEGER;
BEGIN
	NEW.context := lower(NEW.context);
	gml_id      := substr(NEW.featureid, 1, 16);

	IF NEW.context IS NULL THEN
		NEW.context := 'delete';
	END IF;

	IF NEW.context='delete' THEN
		endete := to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"');

	ELSIF NEW.context='replace' THEN
		NEW.safetoignore := lower(NEW.safetoignore);

		IF NEW.safetoignore IS NULL THEN
			RAISE EXCEPTION '%: safeToIgnore nicht gesetzt.', NEW.featureid;
		ELSIF NEW.safetoignore<>'true' AND NEW.safetoignore<>'false' THEN
			RAISE EXCEPTION '%: safeToIgnore ''%'' ungültig (''true'' oder ''false'' erwartet).', NEW.featureid, NEW.safetoignore;
		END IF;

		IF NEW.replacedBy IS NULL OR NEW.replacedBy = '' THEN
			IF NEW.safetoignore = 'true' THEN
				RAISE NOTICE '%: Nachfolger nicht gesetzt - ignoriert', NEW.featureid;
				NEW.ignored := true;
				RETURN NEW;
			ELSE
				RAISE EXCEPTION '%: Nachfolger nicht gesetzt', NEW.featureid;
			END IF;
		END IF;

		sql := 'SELECT beginnt FROM ' || NEW.typename || ' WHERE identifier=''urn:adv:oid:' || NEW.replacedBy || '''';
		-- RAISE NOTICE 'SQL: %', sql;

		-- FEHLER: identifier enthält nur gml_id, aber nicht den Timestamp dahinter
		--         Daher wird das zu ersetzende Obejkt nicht gefunden

		EXECUTE sql INTO endete;

/*
		IF endete IS NULL AND length(NEW.replacedBy)>16 THEN
			RAISE NOTICE '%: Nachfolger % nicht gefunden - versuche ''%''', NEW.featureid, substr(NEW.replacedBy, 1, 16);
			sql := 'SELECT beginnt FROM ' || NEW.typename
			    || ' WHERE gml_id=''' || substr(NEW.replacedBy, 1, 16) || ''''
			    || ' AND endete IS NULL'
			    || ' AND identifier<>''urn:adv:oid:'|| NEW.featureid || '''';
			EXECUTE sql INTO endete;
		END IF;
 */

		IF endete IS NULL THEN
			IF NEW.safetoignore = 'true' THEN
				RAISE NOTICE '%: Nachfolger % nicht gefunden - ignoriert', NEW.featureid, NEW.replacedBy;
				NEW.ignored := true;
				RETURN NEW;
			ELSE
				RAISE EXCEPTION '%: Nachfolger % nicht gefunden', NEW.featureid, NEW.replacedBy;
			END IF;
		END IF;

		-- RAISE NOTICE '%: Nachfolgeobjekt beginnt um %.', NEW.featureid, endete;
	ELSE
		RAISE EXCEPTION '%: Ungültiger Kontext % (''delete'' oder ''replace'' erwartet).', NEW.featureid, NEW.context;
	END IF;

	sql	:= 'UPDATE ' || NEW.typename
		|| ' SET endet=''' || endete || ''''
		|| ' WHERE (identifier=''urn:adv:oid:' || NEW.featureid || ''' OR identifier=''urn:adv:oid:' || gml_id || ''')'
		|| ' AND endet IS NULL';
	-- RAISE NOTICE 'SQL: %', sql;
	EXECUTE sql;
	GET DIAGNOSTICS n = ROW_COUNT;
	IF n<>1 THEN
		RAISE NOTICE 'SQL: %', sql;
		IF NEW.context = 'delete' OR NEW.safetoignore = 'true' THEN
			RAISE NOTICE '%: Untergangsdatum von % Objekte statt nur einem auf % gesetzt - ignoriert', NEW.featureid, n, endete;
			NEW.ignored := true;
			RETURN NEW;
		ELSE
			RAISE EXCEPTION '%: Untergangsdatum von % Objekte statt nur einem auf % gesetzt - ignoriert', NEW.featureid, n, endete;
		END IF;
	END IF;

	NEW.ignored := false;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Löschsatz verarbeiten (OHNE Historie)
-- historische Objekte werden sofort gelöscht.
-- Siehe Mail W. Jacobs vom 23.03.2012 in PostNAS-Mailingliste
CREATE OR REPLACE FUNCTION delete_feature_kill() RETURNS TRIGGER AS $$
DECLARE
	query TEXT;
	gml_id TEXT;
BEGIN
	NEW.typename := lower(NEW.typename);
	NEW.context := lower(NEW.context);
	gml_id      := substr(NEW.featureid, 1, 16);

	IF NEW.context IS NULL THEN
		NEW.context := 'delete';
	END IF;

	IF NEW.context='delete' THEN
		query := 'DELETE FROM ' || NEW.typename || ' WHERE gml_id = ''' || gml_id || '''';
		EXECUTE query;

		query := 'DELETE FROM alkis_beziehungen WHERE beziehung_von = ''' || gml_id || ''' OR beziehung_zu = ''' || gml_id || '''';
		EXECUTE query;
	ELSE
		-- replace
		query := 'DELETE FROM ' || NEW.typename || ' WHERE gml_id = ''' || gml_id || '''';
		EXECUTE query;
		-- alkis_beziehungen bleibt so
	END IF;

	NEW.ignored := false;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Im Trigger 'delete_feature_trigger' muss eine dieser beiden Funktion
-- (delete_feature_hist oder delete_feature_kill) verlinkt werden, je nachdem ob nur
-- aktuelle oder auch historische Objekte in der Datenbank geführt werden sollen.

-- Wenn die Datenbank MIT Historie angelegt wurde, kann nach dem Laden hiermit aufgeräumt werden.
CREATE OR REPLACE FUNCTION alkis_delete_all_endet() RETURNS void AS $$
DECLARE
	c RECORD;
BEGIN
	-- In allen Tabellen die Objekte Löschen, die ein Ende-Datum haben
	FOR c IN
		SELECT table_name
		FROM information_schema.columns a
		WHERE a.column_name='endet'
		ORDER BY table_name
	LOOP
		EXECUTE 'DELETE FROM ' || c.table_name || ' WHERE NOT endet IS NULL';
		RAISE NOTICE 'Lösche ''endet'' in: %', c.table_name;
	END LOOP;
END;
$$ LANGUAGE plpgsql;
