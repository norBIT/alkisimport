SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

---
--- Nutzungen
--- 

SELECT alkis_dropobject('alkis_nutzungen');
CREATE TABLE alkis_nutzungen(
	element VARCHAR PRIMARY KEY,
	funktionsfeld VARCHAR,
	relationstext VARCHAR,
	elementtext VARCHAR,
	enumeration VARCHAR
);

INSERT INTO alkis_nutzungen(element, funktionsfeld, relationstext, elementtext, enumeration) VALUES
	('ax_bahnverkehr',				'funktion',		', ',				'Bahnverkehr',					'ax_funktion_bahnverkehr'),
	('ax_bergbaubetrieb',				'abbaugut',		' von ',			'Bergbaubetrieb',				'ax_abbaugut_bergbaubetrieb'),
	('ax_flaechebesondererfunktionalerpraegung',	'funktion',		', ',				'Fläche besonderer funktionaler Prägung',	'ax_funktion_flaechebesondererfunktionalerpraegung'),
	('ax_flaechegemischternutzung',			'funktion',		', ',				'Fläche gemischter Nutzung',			'ax_funktion_flaechegemischternutzung'),
	('ax_fliessgewaesser',				'funktion',		', ',				'Fließgewässer',				'ax_funktion_fliessgewaesser'),
	('ax_flugverkehr',				'funktion',		', ',				'Flugverkehr',					'ax_funktion_flugverkehr'),
	('ax_friedhof',					'funktion',		', ',				'Friedhof',					'ax_funktion_friedhof'),
	('ax_gehoelz',					'funktion',		', ',				'Gehölz',					'ax_funktion_gehoelz'),
	('ax_hafenbecken',				'funktion',		', ',				'Hafenbecken',					'ax_funktion_hafenbecken'),
	('ax_halde',					'lagergut',		', ',				'Halde',					'ax_lagergut_halde'),
	('ax_heide',					'NULL',			'',				'Heide',					NULL),
	('ax_industrieundgewerbeflaeche',		'funktion',		', ',				'Industrie- und Gewerbefläche',			'ax_funktion_industrieundgewerbeflaeche'),
	('ax_landwirtschaft',				'vegetationsmerkmal',	', ',				'Landwirtschaft',				'ax_vegetationsmerkmal_landwirtschaft'),
	('ax_meer',					'funktion',		', ',				'Meer',						'ax_funktion_meer'),
	('ax_moor',					'NULL',			'',				'Moor',						NULL),
	('ax_platz',					'funktion',		', ',				'Platz',					'ax_funktion_platz'),
	('ax_schiffsverkehr',				'funktion',		', ',				'Schiffsverkehr',				'ax_funktion_schiffsverkehr'),
	('ax_sportfreizeitunderholungsflaeche',		'funktion',		', ',				'Sport-, Freizeit- und Erholungsfläche',	'ax_funktion_sportfreizeitunderholungsflaeche'),
	('ax_stehendesgewaesser',			'funktion',		', ',				'Stehendes Gewässer',				'ax_funktion_stehendesgewaesser'),
	('ax_strassenverkehr',				'funktion',		', ',				'Straßenverkehr',				'ax_funktion_strasse'),
	('ax_sumpf',					'NULL',			'',				'Sumpf',					NULL),
	('ax_tagebaugrubesteinbruch',			'abbaugut',		' von ',			'Tagebau, Grube, Steinbruch',			'ax_abbaugut_tagebaugrubesteinbruch'),
	('ax_unlandvegetationsloseflaeche',		'funktion',		', ',				'Unland, vegetationslose Fläche',		'ax_funktion_unlandvegetationsloseflaeche'),
	('ax_wald',					'vegetationsmerkmal',	', ',				'Wald',						'ax_vegetationsmerkmal_wald'),
	('ax_weg',					'funktion',		', ',				'Weg',						'ax_funktion_weg'),
	('ax_wohnbauflaeche',				'artderbebauung',	' mit Art der Bebauung ',	'Wohnbaufläche',				'ax_artderbebauung_wohnbauflaeche');

SELECT alkis_dropobject('alkis_createnutzung');
CREATE OR REPLACE FUNCTION pg_temp.alkis_createnutzung() RETURNS varchar AS $$
DECLARE
	r  RECORD;
	nv VARCHAR;
	kv VARCHAR;
	d  VARCHAR;
	i  INTEGER;
	res VARCHAR;
	invalid INTEGER;
BEGIN
	nv := E'CREATE VIEW ax_tatsaechlichenutzung AS\n  ';
	kv := E'CREATE VIEW ax_tatsaechlichenutzungsschluessel AS\n  ';
	d := '';

	i := 0;
	FOR r IN
		SELECT
			name,
			kennung,
			funktionsfeld,
			relationstext,
			elementtext,
			enumeration
		FROM alkis_elemente e
		JOIN alkis_nutzungen n ON e.name=n.element
		WHERE 'ax_tatsaechlichenutzung' = ANY (abgeleitet_aus)
	LOOP
		res := alkis_string_append(res, alkis_fixareas(r.name));

		nv := nv
		   || d
		   || 'SELECT '
		   || 'ogc_fid*32+' || i ||' AS ogc_fid,'
		   || '''' || r.name || '''::text AS name,'
		   || 'gml_id,'
		   || alkis_toint(r.kennung) || ' AS kennung,'
		   || r.funktionsfeld  || '::text AS funktion,'
		   || '''' || r.kennung || '''||coalesce('':''||' || r.funktionsfeld || ','''')::text AS nutzung,'
		   || 'wkb_geometry'
		   || ' FROM ' || r.name
		   || ' WHERE endet IS NULL AND hatdirektunten IS NULL'
		   ;

		kv := kv
		   || d
		   || 'SELECT ''' || r.kennung || ''' AS nutzung,''' || r.elementtext ||''' AS name'
		   ;

		IF r.funktionsfeld<>'NULL' THEN
			kv := kv
			   || ' UNION SELECT ''' || r.kennung || ':''|| wert AS nutzung,'''
			   || coalesce(r.elementtext,'') || coalesce(r.relationstext,'') || '''|| beschreibung AS name'
			   || ' FROM ' || r.enumeration
			   ;
		END IF;

		d := E' UNION ALL\n  ';
		i := i + 1;
	END LOOP;

	PERFORM alkis_dropobject('ax_tatsaechlichenutzung');
	EXECUTE nv;

	PERFORM alkis_dropobject('ax_tatsaechlichenutzungsschluessel');
	EXECUTE kv;

	RETURN alkis_string_append(res, 'ax_tatsaechlichenutzung und ax_tatsaechlichenutzungsschluessel erzeugt.');
END;
$$ LANGUAGE plpgsql;

SELECT 'Erzeuge Sicht für Nutzungen...';
SELECT pg_temp.alkis_createnutzung();

DELETE FROM nutz_shl;
INSERT INTO nutz_shl(nutzshl,nutzung)
  SELECT nutzung,name FROM ax_tatsaechlichenutzungsschluessel;

SELECT 'Bestimme Flurstücksnutzungen...';

SELECT alkis_dropobject('nutz_shl_pk_seq');
CREATE SEQUENCE nutz_shl_pk_seq;

DELETE FROM nutz_21;
INSERT INTO nutz_21(flsnr,pk,nutzsl,gemfl,fl,ff_entst,ff_stand)
  SELECT
    *
  FROM (
    SELECT
      alkis_flsnr(f) AS flsnr,
      to_hex(nextval('nutz_shl_pk_seq'::regclass)) AS pk,
      n.nutzung AS nutzsl,
      sum(st_area(alkis_intersection(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id))) AS gemfl,
      (sum(st_area(alkis_intersection(f.wkb_geometry,n.wkb_geometry,'ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id))*amtlicheflaeche/NULLIF(st_area(f.wkb_geometry),0)))::int AS fl,
      0 AS ff_entst,
      0 AS ff_stand
    FROM ax_flurstueck f
    JOIN ax_tatsaechlichenutzung n
        ON f.wkb_geometry && n.wkb_geometry
        AND alkis_relate(f.wkb_geometry,n.wkb_geometry,'2********','ax_flurstueck:'||f.gml_id||'<=>'||n.name||':'||n.gml_id)
    WHERE f.endet IS NULL
    GROUP BY alkis_flsnr(f), f.wkb_geometry, n.nutzung
  ) AS nutz_21
  WHERE fl>0;
