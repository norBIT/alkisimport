/******************************************************************************
 *
 * Projekt:  norGIS ALKIS Import
 * Zweck:    Trigger des ALKIS-Schema
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ******************************************************************************/

SET client_encoding = 'UTF8';
SET default_with_oids = false;
SET search_path = :"alkis_schema", public;

--- Tabelle "delete" für Lösch- und Fortführungsdatensätze
CREATE TABLE "delete" (
       ogc_fid         serial NOT NULL,
       typename        varchar,
       featureid       varchar,
       context         varchar,                -- delete/replace/update
       safetoignore    varchar,                -- replace.safetoignore 'true'/'false'
       replacedBy      varchar,                -- gmlid
       anlass          varchar[],              -- update.anlass
       endet           character(20),          -- update.endet
       ignored         boolean DEFAULT false,  -- Satz wurde nicht verarbeitet
       PRIMARY KEY (ogc_fid)
);

CREATE INDEX delete_fid ON "delete"(featureid);

COMMENT ON TABLE delete IS 'BASE: Lösch- und Fortführungsdatensätze';
COMMENT ON COLUMN delete.context      IS 'Operation ''delete'', ''replace'' oder ''update''.';
COMMENT ON COLUMN delete.safetoignore IS 'Attribut safeToIgnore von wfsext:Replace';
COMMENT ON COLUMN delete.replacedBy   IS 'gml_id des Objekts, das featureid ersetzt';
COMMENT ON COLUMN delete.anlass       IS 'Anlaß des Endes';
COMMENT ON COLUMN delete.endet        IS 'Zeitpunkt des Endes';
COMMENT ON COLUMN delete.ignored      IS 'Löschsatz wurde ignoriert';

CREATE FUNCTION pg_temp.create_trigger(hist BOOLEAN) RETURNS void AS $$
BEGIN
	IF hist THEN
		CREATE TRIGGER delete_feature_trigger
			BEFORE INSERT ON delete
			FOR EACH ROW
			EXECUTE PROCEDURE delete_feature_hist();
		RAISE NOTICE 'Historische Objekte werden geführt.';
	ELSE
		CREATE TRIGGER delete_feature_trigger
			BEFORE INSERT ON delete
			FOR EACH ROW
			EXECUTE PROCEDURE delete_feature_kill();
		RAISE NOTICE 'Historische Objekte werden gelöscht.';
	END IF;
END;
$$ LANGUAGE plpgsql;

SELECT pg_temp.create_trigger(:alkis_hist);
