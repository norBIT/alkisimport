\set nas2alb true
\ir ../config.sql

\if :nas2alb

SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

---
--- Gemeinden
---

DELETE FROM gem_shl;
INSERT INTO gem_shl(gemshl,gemname)
	SELECT
		to_char(alkis_toint(schluesselgesamt),'fm00000000') AS gemshl,
		min(bezeichnung) AS gemname
	FROM ax_gemeinde a
	WHERE endet IS NULL
	GROUP BY to_char(alkis_toint(schluesselgesamt),'fm00000000');

---
--- Gemarkungen
---

DELETE FROM gema_shl;
INSERT INTO gema_shl(gemashl,gemarkung)
	SELECT
		to_char(alkis_toint(land),'fm00')||to_char(alkis_toint(gemarkungsnummer),'fm0000') AS gemashl,
		MIN(bezeichnung) AS gemarkung
	FROM ax_gemarkung
	WHERE endet IS NULL
	GROUP BY to_char(alkis_toint(land),'fm00')||to_char(alkis_toint(gemarkungsnummer),'fm0000');

---
--- Ungenutzte Straßen-, Gemarkungs- und Gemeindeschlüssel entfernen
---

DELETE FROM str_shl WHERE NOT EXISTS (SELECT * FROM strassen WHERE str_shl.strshl=strassen.strshl);
DELETE FROM gema_shl
	WHERE NOT EXISTS (SELECT * FROM flurst WHERE flurst.gemashl=gema_shl.gemashl)
	  AND NOT EXISTS (SELECT * FROM bestand WHERE substr(bestdnr,1,6)=gema_shl.gemashl);

INSERT INTO gema_shl(gemashl,gemarkung)
	SELECT gemashl, '(Gemarkung '||gemashl||')' AS gemarkung
	FROM (
		SELECT substr(flurstueckskennzeichen,1,6) AS gemashl FROM ax_flurstueck
	  UNION SELECT to_char(alkis_toint(land),'fm00') || to_char(alkis_toint(bezirk),'fm0000') FROM ax_buchungsblatt
	) AS a
	WHERE NOT EXISTS (SELECT * FROM gema_shl b WHERE a.gemashl=b.gemashl)
	GROUP BY gemashl;

INSERT INTO gem_shl(gemshl,gemname)
	SELECT gemshl, '(Gemeinde '||gemshl||')' AS gemname
	FROM (
		SELECT to_char(alkis_toint(land),'fm00')||gemeindezugehoerigkeit_regierungsbezirk||to_char(alkis_toint(gemeindezugehoerigkeit_kreis),'fm00')||to_char(alkis_toint(gemeindezugehoerigkeit_gemeinde),'fm000') AS gemshl FROM ax_flurstueck
	) AS a
	WHERE gemshl IS NOT NULL AND NOT EXISTS (SELECT * FROM gem_shl b WHERE a.gemshl=b.gemshl)
	GROUP BY gemshl;

UPDATE gema_shl SET gemshl=(SELECT gemshl FROM flurst WHERE flurst.gemashl=gema_shl.gemashl LIMIT 1);

DELETE FROM gem_shl
  WHERE NOT EXISTS (SELECT * FROM gema_shl WHERE gema_shl.gemshl=gem_shl.gemshl)
    AND NOT EXISTS (SELECT * FROM str_shl WHERE str_shl.gemshl=gem_shl.gemshl)
    AND NOT EXISTS (SELECT * FROM flurst WHERE flurst.gemshl=gem_shl.gemshl);

UPDATE str_shl SET strname=trim(regexp_replace(strname,' H$','')) WHERE strshl LIKE '07%'; -- RP: H-Suffix für historische Straßen entfernen

--
-- Eigentümerschlüssel
--

DELETE FROM eign_shl;
INSERT INTO eign_shl(b,eignerart)
	SELECT
		wert AS b,
		substr(beschreibung,1,60) AS eignerart
	FROM ax_buchungsart_buchungsstelle;

---
--- Fortführungsdatum
---

DELETE FROM fortf;
INSERT INTO fortf(ffnr,beschreibung) VALUES (1, 'Aus ALKIS übernommen: '||to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'));

--- Flurstückszuordnungen
DELETE FROM fs;
INSERT INTO fs(fs_key,fs_obj,alb_key)
  SELECT ogc_fid,gml_id,alkis_flsnr(ax_flurstueck) FROM ax_flurstueck WHERE endet IS NULL;

CREATE TEMPORARY TABLE amtlbestfl AS
	SELECT
		bestdnr,
		SUM(
			amtlflsfl*
			CASE
			WHEN anteil IS NULL OR split_part(anteil,'/',2)::float8=0 THEN 1.0
			ELSE split_part(anteil,'/',1)::float8 / split_part(anteil,'/',2)::float8
			END
		) AS amtlbestfl
	FROM flurst
	JOIN eignerart ON flurst.flsnr=eignerart.flsnr
	WHERE anteil NOT LIKE '%...'
	GROUP BY bestdnr;

CREATE UNIQUE INDEX amtlbestfl_idx ON amtlbestfl(bestdnr);

UPDATE bestand SET amtlbestfl=(SELECT amtlbestfl FROM amtlbestfl WHERE amtlbestfl.bestdnr=bestand.bestdnr);

UPDATE bestand SET bestfl=amtlbestfl::int WHERE amtlbestfl<=2147483647; -- maxint

SELECT "Buchdaten","Anzahl" FROM (
  SELECT 1 AS o, 'Bestände' AS "Buchdaten", count(*) AS "Anzahl" FROM bestand UNION
  SELECT 2, 'Bestände ohne Eigentümerart', count(*) FROM bestand WHERE NOT EXISTS (SELECT * FROM eignerart WHERE eignerart.bestdnr=bestand.bestdnr) UNION
  SELECT 3, 'Bestände ohne Eigentümer', count(*) FROM bestand WHERE NOT EXISTS (SELECT * FROM eigner WHERE eigner.bestdnr=bestand.bestdnr) UNION
  SELECT 4, 'Flurstücke', count(*) FROM flurst UNION
  SELECT 5, 'Flurstücke ohne Eigentümerart', count(*) FROM flurst WHERE NOT EXISTS (SELECT * FROM eignerart WHERE eignerart.flsnr=flurst.flsnr)
) AS stat ORDER BY o;

\endif
