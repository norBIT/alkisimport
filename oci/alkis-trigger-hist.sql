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
	gml_id varchar2(13);
	endete varchar2(20);
	n INTEGER;
BEGIN
	:NEW.typename := upper(substr(:NEW.typename, 1, 30));
	:NEW.context  := lower(:NEW.context);
	gml_id        := substr(:NEW.featureid, 1, 16);

	IF :NEW.context IS NULL THEN
		:NEW.context := 'delete';
	END IF;

	IF :NEW.context='delete' THEN
		SELECT to_char(sysdate, 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') INTO endete FROM dual;

	ELSIF :NEW.context='replace' THEN
		:NEW.safetoignore := lower(:NEW.safetoignore);

		IF :NEW.safetoignore IS NULL THEN
			raise_application_error(-20100, :NEW.featureid || ': safeToIgnore nicht gesetzt.');
		ELSIF :NEW.safetoignore<>'true' AND :NEW.safetoignore<>'false' THEN
			raise_application_error(-20100, :NEW.featureid || ': safeToIgnore ''' || :NEW.safetoignore || ''' ungültig (''true'' oder ''false'' erwartet).');
		END IF;

		IF :NEW.replacedBy IS NULL OR length(:NEW.replacedBy)<16 THEN
			IF :NEW.safetoignore = 'true' THEN
				dbms_output.put_line( :NEW.featureid || ': Nachfolger ''' || :NEW.replacedBy || ''' nicht richtig gesetzt - ignoriert' );
				:NEW.ignored := 'true';
				RETURN;
			ELSE
				raise_application_error(-20100, :NEW.featureid || ': Nachfolger ''' || :NEW.replacedBy || ''' nicht richtig gesetzt - Abbruch');
			END IF;
		END IF;

		IF length(:NEW.replacedBy)=16 THEN
			EXECUTE IMMEDIATE 'SELECT MAX(beginnt) FROM ' || :NEW.typename ||
			        ' WHERE gml_id=''' || :NEW.replacedBy || ''' AND endet IS NULL'
                           INTO endete;
		ELSE
			-- replaceBy mit Timestamp
			EXECUTE IMMEDIATE 'SELECT beginnt FROM ' || :NEW.typename ||
			        ' WHERE identifier=''urn:adv:oid:' || :NEW.replacedBy || ''''
			   INTO endete;
			IF endete IS NULL THEN
				EXECUTE IMMEDIATE 'SELECT MAX(beginnt) FROM ' || :NEW.typename ||
					' WHERE gml_id=''' || substr(:NEW.replacedBy,1,16) || ''' AND endet IS NULL'
				   INTO endete;
                       END IF;
		END IF;

		IF endete IS NULL THEN
			IF :NEW.safetoignore = 'true' THEN
				dbms_output.put_line(:NEW.featureid || ': Nachfolger ''' || :NEW.replacedBy || ''' nicht gefunden - ignoriert');
				:NEW.ignored := 'true';
				RETURN;
			ELSE
				raise_application_error(-20100, :NEW.featureid || ': Nachfolger ''' || :NEW.replacedBy || ''' nicht gefunden - Abbruch');
			END IF;
		END IF;
	ELSE
		raise_application_error(-20100, :NEW.featureid || ': Ungültiger Kontext ' || :NEW.context || '''delete'' oder ''replace'' erwartet).');
	END IF;

	s	:= 'UPDATE ' || :NEW.typename
		|| ' SET endet=''' || endete || ''''
		|| ' WHERE gml_id=''' || gml_id || ''''
		|| ' AND endet IS NULL'
		|| ' AND beginnt<''' || endete || '''';
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
