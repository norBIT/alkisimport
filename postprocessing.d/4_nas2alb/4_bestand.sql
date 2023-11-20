\set nas2alb true
\ir ../../config.sql

\if :nas2alb

SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

---
--- Bestandsbemerkungen
---

SELECT alkis_dropobject('bem_best_pk_seq');
CREATE SEQUENCE bem_best_pk_seq;

DELETE FROM bem_best;
INSERT INTO bem_best(bestdnr,pk,lnr,text,ff_entst,ff_stand)
	SELECT
		to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		to_hex(nextval('bem_best_pk_seq'::regclass)) AS pk,
		laufendenummer AS lnr,
		beschreibungdessondereigentums AS text,
		0 AS ff_entst,
		0 AS ff_stand
	FROM ax_buchungsstelle bs
	JOIN ax_buchungsblatt bb ON bb.gml_id=bs.istbestandteilvon AND bb.endet IS NULL
	WHERE bs.beschreibungdessondereigentums IS NOT NULL AND bs.endet IS NULL;

---
--- Bestände
---

SELECT 'Übernehme Bestände...';

DELETE FROM bestand;
INSERT INTO bestand(bestdnr,gbbz,gbblnr,anteil,auftlnr,bestfl,ff_entst,ff_stand,pz)
	SELECT
		to_char(alkis_toint(land),'fm00') || to_char(alkis_toint(bezirk),'fm0000') || '-' || trim(buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		to_char(alkis_toint(bezirk),'fm0000') AS gbbz,
		buchungsblattnummermitbuchstabenerweiterung AS gbblnr,
		NULL AS anteil,
		NULL AS auftrlnr,
		NULL AS bestfl,
		0 AS ff_entst,
		0 AS ff_stand,
		NULL AS pz
	FROM ax_buchungsblatt bb
	WHERE bb.endet IS NULL
	  -- Workaround für gleiche Bestände von mehreren Katasterämtern
	  AND NOT EXISTS (
		SELECT *
		FROM ax_buchungsblatt bb2
		WHERE bb2.endet IS NULL
		  AND bb.land=bb2.land AND bb.bezirk=bb2.bezirk AND trim(bb.buchungsblattnummermitbuchstabenerweiterung)=trim(bb2.buchungsblattnummermitbuchstabenerweiterung)
	          AND bb2.beginnt<bb.beginnt
	          AND bb2.ogc_fid<>bb.ogc_fid
	  )
	;

---
--- Eigentümer
---

SELECT 'Übernehme Eigentümer...';

SELECT alkis_dropobject('eigner_pk_seq');
CREATE SEQUENCE eigner_pk_seq;

DELETE FROM eigner;
INSERT INTO eigner(bestdnr,pk,ab,namensnr,ea,antverh,name,name1,name2,name3,name4,name5,name6,name7,name8,anrede,vorname,nachname,namensteile,ak_grade,geb_name,geb_datum,str_hnr,plz_pf,postfach,plz,ort,land,ff_entst,ff_stand)
	SELECT
		to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		to_hex(nextval('eigner_pk_seq'::regclass)) AS pk,
		NULL AS ab,
		laufendenummernachdin1421 AS namensnr,
		NULL AS ea,
		zaehler||'/'||nenner AS antverh,
		substr(coalesce( p.nachnameoderfirma, '(' || (SELECT beschreibung FROM ax_artderrechtsgemeinschaft_namensnummer WHERE wert=artderrechtsgemeinschaft) || ')' ), 1, 4 ) AS name,
		alkis_truncate(
                  coalesce(
	            p.nachnameoderfirma || coalesce(', ' || p.vorname, ''),
		    coalesce((SELECT beschreibung FROM ax_artderrechtsgemeinschaft_namensnummer WHERE wert=artderrechtsgemeinschaft), 'Verschiedene') ||
	              coalesce(': ' || nn.beschriebDerRechtsgemeinschaft, '')
		  ),
	          200
	        ) AS name1,
		alkis_truncate(coalesce('geb. '||p.geburtsname||', ','') || '* ' || p.geburtsdatum, 200) AS name2,
		alkis_truncate(an.strasse || coalesce(' ' || an.hausnummer,''), 200) AS name3,
		alkis_truncate( coalesce(an.postleitzahlpostzustellung||' ','')||an.ort_post, 200) AS name4,
		alkis_truncate(bestimmungsland, 200) AS name5,
		NULL AS name6,
		NULL AS name7,
		NULL AS name8,
		(SELECT beschreibung FROM ax_anrede_person WHERE wert=p.anrede) AS anrede,
		alkis_truncate(p.vorname, 200) AS vorname,
		alkis_truncate(p.nachnameoderfirma, 200) AS nachname,
		alkis_truncate(p.namensbestandteil, 200) AS namensteile,
		alkis_truncate(p.akademischergrad, 200) AS ak_grade,
		alkis_truncate(p.geburtsname, 200) AS geb_name,
		p.geburtsdatum AS geb_datum,
		an.strasse || coalesce(' ' || an.hausnummer,'') AS str_hnr,
		NULL AS plz_pf,
		NULL AS postfach,
		alkis_truncate(an.postleitzahlpostzustellung, 20) AS plz,
		alkis_truncate(an.ort_post, 200) AS ort,
		alkis_truncate(bestimmungsland, 100) AS land,
		0 AS ff_entst,
		0 AS ff_fortf
	FROM ax_namensnummer nn
	JOIN ax_buchungsblatt bb ON bb.gml_id=nn.istbestandteilvon AND bb.endet IS NULL
	LEFT OUTER JOIN ax_person p ON p.gml_id=nn.benennt AND p.endet IS NULL
	LEFT OUTER JOIN ax_anschrift an ON an.gml_id = ANY (p.hat) AND an.endet IS NULL
	WHERE nn.endet IS NULL;

UPDATE eigner SET name1=regexp_replace(name1, E'\\s\\s+', ' ');

INSERT INTO eigner(bestdnr,pk,name1,ff_entst,ff_stand)
	SELECT
		to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
                to_hex(nextval('eigner_pk_seq'::regclass)) AS pk,
                '(fiktives Buchungsblatt)' AS name1,
                0 AS ff_entst,
                0 AS ff_fortf
	FROM ax_buchungsblatt bb
	WHERE endet IS NULL AND blattart=5000;

INSERT INTO eigner(bestdnr,pk,name1,ff_entst,ff_stand)
        SELECT
                bestdnr,
                to_hex(nextval('eigner_pk_seq'::regclass)) AS pk,
                '(mehrere)' AS name1,
                0 AS ff_entst,
                0 AS ff_fortf
        FROM bestand
        WHERE NOT EXISTS (SELECT * FROM eigner WHERE eigner.bestdnr=bestand.bestdnr);

\endif
