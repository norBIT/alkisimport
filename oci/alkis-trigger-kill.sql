CREATE OR REPLACE TRIGGER delete_feature_trigger
	BEFORE INSERT ON "DELETE"
	FOR EACH ROW
DECLARE
	query varchar2(2047);
	begsql varchar2(2047);
	aktbeg varchar2(2047);
	gml_id varchar2(2047);
BEGIN
	:NEW.typename := upper(substr(:NEW.typename,1,30));
	:NEW.context  := lower(:NEW.context);
	gml_id        := substr(:NEW.featureid, 1, 16);

	IF :NEW.context IS NULL THEN
		:NEW.context := 'delete';
	END IF;

	IF :NEW.context='delete' THEN
		-- ersatzloses Loeschen eines Objektes

		query := 'DELETE FROM ' || :NEW.typename
			|| ' WHERE gml_id = ''' || gml_id || '''';
		EXECUTE IMMEDIATE query;

		query := 'DELETE FROM alkis_beziehungen WHERE beziehung_von = ''' || gml_id
			|| ''' OR beziehung_zu = ''' || gml_id || '''';
		EXECUTE IMMEDIATE query;

		dbms_output.put_line( 'Lösche gml_id '|| gml_id || ' in ' || :NEW.typename || ' und Beziehungen');

	ELSE
		-- Ersetzen eines Objektes
		-- In der objekt-Tabelle sind bereits 2 Objekte vorhanden (alt und neu).
		-- Die 2 Datensätze unterscheiden sich nur in ogc_fid und beginnt

		-- beginnt-Wert des aktuellen Objektes ermitteln
		-- RAISE NOTICE 'Suche beginnt von neuem gml_id % ', substr(:NEW.replacedBy, 1, 16);
		begsql := 'SELECT max(beginnt) FROM ' || :NEW.typename || ' WHERE gml_id = ''' || substr(:NEW.replacedBy, 1, 16) || ''' AND endet IS NULL';
		EXECUTE IMMEDIATE begsql INTO aktbeg;

		-- Nur alte Objekte entfernen
		query := 'DELETE FROM ' || :NEW.typename || ' WHERE gml_id = ''' || gml_id || ''' AND beginnt < ''' || aktbeg || '''';
		EXECUTE IMMEDIATE query;

		-- Tabelle alkis_beziehungen
		IF gml_id <> substr(:NEW.replacedBy, 1, 16) THEN -- gml_id gleich
			-- replace mit ungleicher gml_id
			-- Falls dies vorkommt, die Function erweitern
			raise_application_error(-20100, gml_id || ': neue gml_id ' || :NEW.replacedBy || ' bei Replace in ' || :NEW.typename || '. alkis_beziehungen muss aktualisiert werden!');
		-- ELSE
			-- Beziehungen des Objektes wurden redundant noch einmal eingetragen
			-- ToDo:         HIER sofort die Redundanzen zum aktuellen Objekt beseitigen.
			-- Workaround: Nach der Konvertierung werden im Post-Processing
			--             ALLE Redundanzen mit einem SQL-Statemant beseitigt.
		--	RAISE NOTICE 'Ersetze gleiche gml_id % in %', gml_id, :NEW.typename;

		-- ENTWURF ungetestet:
		--query := 'DELETE FROM alkis_beziehungen AS bezalt
		--	WHERE (bezalt.beziehung_von = ' || gml_id || ' OR bezalt.beziehung_zu = ' || gml_id ||')
		--	AND EXISTS (SELECT ogc_fid FROM alkis_beziehungen AS bezneu
		--		WHERE bezalt.beziehung_von = bezneu.beziehung_von
		--		AND bezalt.beziehung_zu = bezneu.beziehung_zu
		--		AND bezalt.beziehungsart = bezneu.beziehungsart
		--		AND bezalt.ogc_fid < bezneu.ogc_fid);'
		--EXECUTE query;

		END IF;
	END IF;

	:NEW.ignored := 'false';
END delete_feature_trigger;
/

-- show errors trigger delete_feature_trigger;

QUIT;

