\set nas2alb true
\ir ../../config.sql

\if :nas2alb

SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

---
--- Flurstücke
---

SELECT 'Prüfe Flurstücksgeometrien...';
SELECT alkis_fixareas('ax_flurstueck');

SELECT 'Übertrage Flurstücke...';

DELETE FROM flurst;
INSERT INTO flurst(flsnr,flsnrk,gemashl,flr,entst,fortf,flsfl,amtlflsfl,gemflsfl,af,flurknr,baublock,flskoord,fora,fina,h1shl,h2shl,hinwshl,strshl,gemshl,hausnr,lagebez,k_anlverm,anl_verm,blbnr,n_flst,ff_entst,ff_stand,ff_datum)
   SELECT
     alkis_flsnr(a) AS flsnr,
     alkis_flsnrk(a) AS flsnrk,
     to_char(alkis_toint(a.land),'fm00') || to_char(alkis_toint(a.gemarkungsnummer),'fm0000') AS gemashl,
     to_char(coalesce(a.flurnummer,0),'fm000') AS flr,
     to_char(date_part('year', a.zeitpunktderentstehung), 'fm0000') || '/     -  ' AS entst,
     NULL AS fortf,
     amtlicheflaeche::int AS flsfl,
     amtlicheflaeche AS amtlflsfl,
     st_area(wkb_geometry) AS gemflsfl,
     '01' AS af,
     NULL AS flurknr,
     NULL AS baublock,
     alkis_flskoord(a) AS flskoord,
     NULL AS fora,
     NULL AS fina,
     NULL AS h1shl,
     NULL AS h2shl,
     NULL AS hinwshl,
     NULL AS strshl,
     to_char(alkis_toint(a.gemeindezugehoerigkeit_land),'fm00')||a.gemeindezugehoerigkeit_regierungsbezirk||to_char(alkis_toint(a.gemeindezugehoerigkeit_kreis),'fm00')||to_char(alkis_toint(a.gemeindezugehoerigkeit_gemeinde),'fm000') AS gemshl,
     NULL AS hausnr,
     (
      SELECT array_to_string(array_agg(DISTINCT unverschluesselt),E'\n')
      FROM ax_lagebezeichnungohnehausnummer l
      WHERE l.endet IS NULL AND l.gml_id=ANY(a.zeigtauf)
     ) AS lagebez,
     NULL AS k_anlverm,
     NULL AS anl_verm,
     NULL AS blbnr,
     NULL AS n_flst,
     0 AS ff_entst,
     0 AS ff_stand,
     NULL AS ff_datum
   FROM ax_flurstueck a
   WHERE a.endet IS NULL
     -- Workaround für gleiche Bestände von mehreren Katasterämtern
     AND NOT EXISTS (
	SELECT *
	FROM ax_flurstueck b
	WHERE b.endet IS NULL
	  AND alkis_flsnr(a)=alkis_flsnr(b)
	  AND b.beginnt<a.beginnt
	  AND a.ogc_fid<>b.ogc_fid
	)
     ;

SELECT 'Belege Baulastenblattnummer...';

SELECT alkis_dropobject('bblnr_temp');
CREATE TEMPORARY TABLE bblnr_temp AS
  SELECT
    alkis_flsnr(f) AS flsnr,
    b.bezeichnung
  FROM ax_flurstueck f
  JOIN ax_bauraumoderbodenordnungsrecht b
    ON b.endet IS NULL
    AND b.artderfestlegung=2610
    AND f.wkb_geometry && b.wkb_geometry
    AND alkis_relate(f.wkb_geometry,b.wkb_geometry,'2********','ax_flurstueck:'||f.gml_id||'<=>ax_bauraumoderbodenordnungsrecht:'||b.gml_id)
  WHERE f.endet IS NULL;

CREATE INDEX bblnr_temp_flsnr ON bblnr_temp(flsnr);

UPDATE flurst SET blbnr=(SELECT regexp_replace(array_to_string(array_agg(DISTINCT b.bezeichnung),','),E'\(.{196}\).+',E'\\1 ...') FROM bblnr_temp b WHERE flurst.flsnr=b.flsnr);

\endif
