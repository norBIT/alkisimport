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
		to_char(to_number(buchungsblattnummermitbuchstabenerweiterung,'0000000')::int,'fm0000000') AS gbblnr,
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
		substr( coalesce( p.nachnameoderfirma, '(' || (SELECT beschreibung FROM ax_artderrechtsgemeinschaft_namensnummer WHERE wert=artderrechtsgemeinschaft) || ')' ), 1, 4 ) AS name,
		coalesce( p.nachnameoderfirma || coalesce(', ' || p.vorname, ''), '(' || (SELECT beschreibung FROM ax_artderrechtsgemeinschaft_namensnummer WHERE wert=artderrechtsgemeinschaft) || ')', '(Verschiedene)' ) AS name1,
		coalesce('geb. '||p.geburtsname||', ','') || '* ' || p.geburtsdatum AS name2,
		an.strasse || coalesce(' ' || an.hausnummer,'') AS name3,
		coalesce(an.postleitzahlpostzustellung||' ','')||an.ort_post AS name4,
		bestimmungsland AS name5,
		NULL AS name6,
		NULL AS name7,
		NULL AS name8,
		(SELECT beschreibung FROM ax_anrede_person WHERE wert=p.anrede) AS anrede,
		p.vorname AS vorname,
		p.nachnameoderfirma AS nachname,
		p.namensbestandteil AS namensteile,
		p.akademischergrad AS ak_grade,
		p.geburtsname AS geb_name,
		p.geburtsdatum AS geb_datum,
		an.strasse || coalesce(' ' || an.hausnummer,'') AS str_hnr,
		NULL AS plz_pf,
		NULL AS postfach,
		an.postleitzahlpostzustellung AS plz,
		an.ort_post AS ort,
		bestimmungsland AS land,
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
                bestdnr,
                to_hex(nextval('eigner_pk_seq'::regclass)) AS pk,
                '(mehrere)' AS name1,
                0 AS ff_entst,
                0 AS ff_fortf
        FROM bestand
        WHERE NOT EXISTS (SELECT * FROM eigner WHERE eigner.bestdnr=bestand.bestdnr);
