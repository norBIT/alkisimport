BEGIN EXECUTE IMMEDIATE 'DROP TABLE alkis_beziehungen_insert CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE alkis_beziehungen_insert(
        ogr_fid                 integer NOT NULL,
        beziehung_von           character(16),
        beziehungsart           varchar2(2047),
        beziehung_zu            character(16),
        CONSTRAINT ALKIS_BZI PRIMARY KEY (ogr_fid)
);

-- Beziehungssätze aufräumen
CREATE OR REPLACE TRIGGER alkis_beziehung_ins
	AFTER INSERT ON "ALKIS_BEZIEHUNGEN"
	REFERENCING NEW AS NEW
	FOR EACH ROW
BEGIN
	-- avoid table mutation
	INSERT
	INTO alkis_beziehungen_insert(ogr_fid,beziehung_von,beziehungsart,beziehung_zu)
	VALUES (
		:NEW.ogr_fid,
		:NEW.beziehung_von,
		:NEW.beziehungsart,
		:NEW.beziehung_zu
	);
END alkis_beziehung_inserted;
/

-- show errors trigger alkis_beziehung_ins;

CREATE OR REPLACE TRIGGER alkis_beziehungen_a_ins
	AFTER INSERT ON alkis_beziehungen
BEGIN
	FOR a IN (SELECT * FROM alkis_beziehungen_insert) LOOP
		DELETE FROM alkis_beziehungen b WHERE a.ogr_fid<b.ogr_fid AND a.beziehung_von=b.beziehung_von AND a.beziehungsart=b.beziehungsart AND a.beziehung_zu=b.beziehung_zu;
	END LOOP;
	DELETE FROM alkis_beziehungen_insert;
END alkis_beziehungen_a_ins;
/

-- show errors trigger alkis_beziehungen_a_ins

CREATE OR REPLACE TRIGGER delete_feature_trigger
	BEFORE INSERT ON "DELETE"
	FOR EACH ROW
DECLARE
	s varchar2(2047);
	alt_id varchar2(16);
	neu_id varchar2(16);
	beginnt varchar2(20);
	endete varchar2(20);
	n INTEGER;
BEGIN
	:NEW.typename := upper(substr(:NEW.typename, 1, 30));
	:NEW.context  := lower(:NEW.context);
	IF :NEW.context IS NULL THEN
		:NEW.context := 'delete';
	END IF;

	-- TIMESTAMP weder in gml_id noch identifier verläßlich.
	-- also ggf. aus Datenbank holen

	IF length(:NEW.featureid)=32 THEN
		alt_id  := substr(:NEW.featureid, 1, 16);

		IF :NEW.featureid<>:NEW.replacedBy THEN
			-- Beginnt-Datum aus Timestamp
			beginnt := substr(:NEW.featureid, 17, 4) || '-'
				|| substr(:NEW.featureid, 21, 2) || '-'
				|| substr(:NEW.featureid, 23, 2) || 'T'
				|| substr(:NEW.featureid, 26, 2) || ':'
				|| substr(:NEW.featureid, 28, 2) || ':'
				|| substr(:NEW.featureid, 30, 2) || 'Z'
				;
		END IF;
	ELSIF length(:NEW.featureid)=16 THEN
		alt_id := :NEW.featureid;
	ELSE
		raise_application_error(-20100, :NEW.featureid || ': Länge 16 oder 32 statt ' || length(:NEW.featureid) || ' erwartet.');
	END IF;

	IF beginnt IS NULL THEN
		-- Beginnt-Datum des ältesten Eintrag, der nicht untergegangen ist
		-- => der Satz dessen 'endet' gesetzt werden muß
		EXECUTE IMMEDIATE 'SELECT min(beginnt) FROM ' || :NEW.typename
			|| ' WHERE gml_id=''' || alt_id || ''''
			|| ' AND endet IS NULL'
			INTO beginnt;
	END IF;

	IF :NEW.context='delete' THEN
		SELECT to_char(sysdate, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') INTO endete FROM dual;

	ELSIF :NEW.context='replace' THEN
		:NEW.safetoignore := lower(:NEW.safetoignore);

		IF :NEW.safetoignore IS NULL THEN
			raise_application_error(-20100, :NEW.featureid || ': safeToIgnore nicht gesetzt.');
		ELSIF :NEW.safetoignore<>'true' AND :NEW.safetoignore<>'false' THEN
			raise_application_error(-20100, :NEW.featureid || ': safeToIgnore ''' || :NEW.safetoignore || ''' ungültig (''true'' oder ''false'' erwartet).');
		END IF;

		IF length(:NEW.replacedBy)=32 THEN
			-- Beginnt-Datum aus Timestamp
			neu_id := substr(:NEW.replacedBy, 1, 16);

			IF :NEW.featureid<>:NEW.replacedBy THEN
				endete  := substr(:NEW.replacedBy, 17, 4) || '-'
					|| substr(:NEW.replacedBy, 21, 2) || '-'
					|| substr(:NEW.replacedBy, 23, 2) || 'T'
					|| substr(:NEW.replacedBy, 26, 2) || ':'
					|| substr(:NEW.replacedBy, 28, 2) || ':'
					|| substr(:NEW.replacedBy, 30, 2) || 'Z'
					;
			END IF;
		ELSIF length(:NEW.replacedBy)=16 THEN
			neu_id  := :NEW.replacedBy;
		ELSIF length(:NEW.replacedBy)<>16 THEN
			raise_application_error(-20100, :NEW.replacedBy || ': Länge 16 oder 32 statt ' || length(:NEW.replacedBy) || ' erwartet.');
		END IF;

		IF endete IS NULL THEN
			-- Beginnt-Datum des neuesten Eintrag, der nicht untergegangen ist
			-- => Enddatum für vorherigen Satz
			EXECUTE IMMEDIATE 'SELECT max(beginnt) FROM ' || :NEW.typename
				|| ' WHERE gml_id=''' || neu_id || ''''
				|| ' AND beginnt>''' || beginnt || ''''
				|| ' AND endet IS NULL'
				INTO endete;
		END IF;
	ELSE
		raise_application_error(-20100, :NEW.featureid || ': Ungültiger Kontext ' || :NEW.context || '''delete'' oder ''replace'' erwartet).');
	END IF;

	IF alt_id<>neu_id THEN
		dbms_output.put_line('Objekt ' || alt_id || ' wird durch Objekt ' || neu_id || ' ersetzt.');
	END IF;

	IF beginnt IS NULL THEN
		dbms_output.put_line('Kein Beginndatum fuer Objekt ' || alt_id || '.');
	END IF;

	IF endete IS NULL THEN
		dbms_output.put_line('Kein Beginndatum fuer Objekt ' || neu_id || '.');
	END IF;

	IF beginnt IS NULL OR endete IS NULL OR beginnt=endete THEN
		raise_application_error(-20100, 'Objekt ' || alt_id || ' wird durch Objekt ' || neu_id || ' ersetzt (leere Lebensdauer?).');
	END IF;

	s   := 'UPDATE ' || :NEW.typename
	    || ' SET endet=''' || endete || ''''
	    || ' WHERE gml_id=''' || alt_id || ''''
	    || ' AND beginnt=''' || beginnt || ''''
	    || ' AND endet IS NULL';
	EXECUTE IMMEDIATE s;
	n := SQL%ROWCOUNT;
	IF n<>1 THEN
		dbms_output.put_line( 'SQL: ' || s);
		IF :NEW.context = 'delete' OR :NEW.safetoignore = 'true' THEN
			dbms_output.put_line( :NEW.featureid || ': Untergangsdatum von  ' || n || ' Objekten statt nur einem auf ' || endete || ' gesetzt - ignoriert' );
			:NEW.ignored := 'true';
			RETURN;
		ELSE
			raise_application_error(-20100, :NEW.featureid || ': Untergangsdatum von ' || n || ' Objekten statt nur einem auf ' || endete || ' gesetzt - Abbruch' );
		END IF;
	END IF;

	:NEW.ignored := 'false';
	RETURN;
END delete_feature_trigger;
/

-- show errors trigger delete_feature_trigger;
