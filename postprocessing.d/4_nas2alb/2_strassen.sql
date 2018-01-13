SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

---
--- Straßenzuordnungen
---

SELECT 'Erzeuge Straßenzuordnungen...';

DELETE FROM str_shl;
INSERT INTO str_shl(strshl,strname,gemshl)
	SELECT DISTINCT
		to_char(alkis_toint(land),'fm00')||regierungsbezirk||to_char(alkis_toint(kreis),'fm00')||to_char(alkis_toint(gemeinde),'fm000')||'    '||trim(lage) AS strshl,
		regexp_replace(bezeichnung,' H$','') AS strname,	-- RP: Historische Straßennamen mit H am Ende
		to_char(alkis_toint(land),'fm00')||regierungsbezirk||to_char(alkis_toint(kreis),'fm00')||to_char(alkis_toint(gemeinde),'fm000') AS gemshl
	FROM ax_lagebezeichnungkatalogeintrag a
	WHERE endet IS NULL
	  -- Nur nötig, weil im Katalog doppelte Einträge vorkommen
	  AND NOT EXISTS (SELECT * FROM ax_lagebezeichnungkatalogeintrag b WHERE b.endet IS NULL AND a.schluesselgesamt=b.schluesselgesamt AND b.beginnt<a.beginnt);

SELECT alkis_dropobject('strassen_pk_seq');
CREATE SEQUENCE strassen_pk_seq;

DELETE FROM strassen;
INSERT INTO strassen(flsnr,pk,strshl,hausnr,ff_entst,ff_stand)
	SELECT
		alkis_flsnr(f) AS flsnr,
		to_hex(nextval('strassen_pk_seq'::regclass)) AS pk,
		to_char(alkis_toint(l.land),'fm00')||l.regierungsbezirk||to_char(alkis_toint(l.kreis),'fm00')||to_char(alkis_toint(l.gemeinde),'fm000')||'    '||trim(lage) AS strshl,
		hausnummer AS hausnr,
		0 AS ff_entst,
		0 AS ff_stand
	FROM ax_lagebezeichnungmithausnummer l
	JOIN ax_flurstueck f ON ARRAY[l.gml_id] <@ f.weistauf AND f.endet IS NULL
	WHERE NOT l.lage IS NULL AND l.endet IS NULL;

INSERT INTO strassen(flsnr,pk,strshl,hausnr,ff_entst,ff_stand)
	SELECT
		alkis_flsnr(f) AS flsnr,
		to_hex(nextval('strassen_pk_seq'::regclass)) AS pk,
		to_char(alkis_toint(l.land),'fm00')||l.regierungsbezirk||to_char(alkis_toint(l.kreis),'fm00')||to_char(alkis_toint(l.gemeinde),'fm000')||'    '||trim(lage) AS strshl,
		'' AS hausnr,
		0 AS ff_entst,
		0 AS ff_stand
	FROM ax_lagebezeichnungohnehausnummer l
	JOIN ax_flurstueck f ON ARRAY[l.gml_id] <@ f.zeigtauf AND f.endet IS NULL
	WHERE NOT l.lage IS NULL AND l.endet IS NULL;
