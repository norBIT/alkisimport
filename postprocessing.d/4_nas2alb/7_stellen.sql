\set nas2alb true
\ir ../../config.sql

\if :nas2alb
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

--- Ausführende Stellen
---

SELECT alkis_dropobject('alkis_createausfuehrendestellen');
CREATE FUNCTION pg_temp.alkis_createausfuehrendestellen() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR[];
	v VARCHAR;
	d VARCHAR;
	f VARCHAR;
	p VARCHAR;
	i INTEGER;
	res VARCHAR;
	invalid INTEGER;
BEGIN
	PERFORM alkis_dropobject('ax_ausfuehrendestellen');

	res := alkis_string_append(res, alkis_fixareas('ax_schutzzone'));

	CREATE TEMP SEQUENCE a;

	PERFORM alkis_dropobject('v_schutzgebietnachwasserrecht');
	CREATE TABLE v_schutzgebietnachwasserrecht AS
		SELECT nextval('a') AS ogc_fid,z.gml_id,'ax_schutzzone'::varchar AS name,s.land,s.stelle,z.wkb_geometry,NULL::text AS endet, hatdirektunten
		FROM ax_schutzgebietnachwasserrecht s
		JOIN ax_schutzzone z ON ARRAY[s.gml_id] <@ z.istteilvon AND z.endet IS NULL
		WHERE s.endet IS NULL;
	CREATE INDEX v_schutzgebietnachwasserrecht_wkb_geometry_idx ON v_schutzgebietnachwasserrecht USING gist(wkb_geometry);

	DROP SEQUENCE a;
	CREATE TEMP SEQUENCE a;

	PERFORM alkis_dropobject('v_schutzgebietnachnaturumweltoderbodenschutzrecht');
	CREATE TABLE v_schutzgebietnachnaturumweltoderbodenschutzrecht AS
		SELECT nextval('a') AS ogc_fid,z.gml_id,'ax_schutzzone'::varchar AS name,s.land,s.stelle,z.wkb_geometry,NULL::text AS endet, hatdirektunten
		FROM ax_schutzgebietnachnaturumweltoderbodenschutzrecht s
		JOIN ax_schutzzone z ON ARRAY[s.gml_id] <@ z.istteilvon AND z.endet IS NULL
		WHERE s.endet IS NULL;
	CREATE INDEX v_schutzgebietnachnuobr_wkb_geometry_idx ON v_schutzgebietnachnaturumweltoderbodenschutzrecht USING gist(wkb_geometry);

	v := E'CREATE VIEW ax_ausfuehrendestellen AS\n  ';
	d := '';

	i := 1;
	FOR c IN SELECT table_name FROM information_schema.tables WHERE table_schema=current_schema() AND table_name IN (
			'v_schutzgebietnachwasserrecht',
			'v_schutzgebietnachnaturumweltoderbodenschutzrecht',
			'ax_naturumweltoderbodenschutzrecht',
			'ax_forstrecht',
			'ax_bauraumoderbodenordnungsrecht',
			'ax_klassifizierungnachstrassenrecht',
			'ax_denkmalschutzrecht',
			'ax_anderefestlegungnachwasserrecht',
			'ax_anderefestlegungnachstrassenrecht',
			'ax_sonstigesrecht',
			'ax_klassifizierungnachwasserrecht'
		)
	LOOP
		IF c.table_name LIKE 'ax_%' THEN
			res := alkis_string_append(res, alkis_fixareas(c.table_name));
		END IF;

		v := v
		  || d
		  || 'SELECT '
		  || 'ogc_fid*16+' || i || ' AS ogc_fid,'
		  || '''' || c.table_name || '''::text AS name,'
		  || 'gml_id,'
		  || 'to_char(alkis_toint(land),''fm00'') || stelle AS ausfuehrendestelle,'
		  || 'wkb_geometry'
		  || ' FROM ' || c.table_name
		  || ' WHERE endet IS NULL AND hatdirektunten IS NULL'
		  ;

		d := E' UNION ALL\n  ';
		i := i + 1;
	END LOOP;

	EXECUTE v;

	RETURN alkis_string_append(res, 'ax_ausfuehrendestellen erzeugt.');
END;
$$ LANGUAGE plpgsql;

SELECT 'Erzeuge Sicht für ausführende Stellen...';
SELECT pg_temp.alkis_createausfuehrendestellen();

SELECT 'Bestimme ausführende Stellen für Flurstücke...';

SELECT alkis_dropobject('ausfst_pk_seq');
CREATE SEQUENCE ausfst_pk_seq;

DELETE FROM ausfst;
INSERT INTO ausfst(flsnr,pk,ausf_st,verfnr,verfshl,ff_entst,ff_stand)
  SELECT
    alkis_flsnr(f) AS flsnr,
    to_hex(nextval('ausfst_pk_seq'::regclass)) AS pk,
    s.ausfuehrendestelle AS ausf_st,
    NULL AS verfnr,
    NULL AS verfshl,
    0 AS ff_entst,
    0 AS ff_stand
  FROM ax_flurstueck f
  JOIN ax_ausfuehrendestellen s
    ON f.wkb_geometry && s.wkb_geometry
    AND alkis_relate(f.wkb_geometry,s.wkb_geometry,'2********','ax_flurstueck:'||f.gml_id||'<=>'||s.name||':'||s.gml_id)
  WHERE f.endet IS NULL
  GROUP BY alkis_flsnr(f), s.ausfuehrendestelle;

DELETE FROM afst_shl;
INSERT INTO afst_shl(ausf_st,afst_txt)
  SELECT
    schluesselgesamt,
    MIN(bezeichnung)
  FROM ax_dienststelle d
  JOIN ausfst ON ausf_st=schluesselgesamt
  GROUP BY schluesselgesamt;

\endif
