\unset ON_ERROR_STOP
SET application_name='ALKIS-Import - Liegenschaftsbuchübernahme';
\set ON_ERROR_STOP

--
-- ALKIS:
-- ax_gebaeudeausgestaltung | zeigtAuf               | ax_gebaeude                                        |  43882
-- ax_gebaeude              | zeigtAuf               | ax_lagebezeichnungmithausnummer                    |  19229
-- ax_flurstueck            | weistAuf               | ax_lagebezeichnungmithausnummer                    |  20481
-- ax_flurstueck            | zeigtAuf               | ax_lagebezeichnungohnehausnummer                   |  11596
-- ax_flurstueck            | istGebucht             | ax_buchungsstelle                                  |  27128
-- ax_buchungsstelle        | an                     | ax_buchungsstelle                                  |  13832
-- ax_buchungsstelle        | istBestandteilVon      | ax_buchungsblatt                                   |  33633
-- ax_namensnummer          | istBestandteilVon      | ax_buchungsblatt                                   |  43780
-- ax_namensnummer          | benennt                | ax_person                                          |  42681
-- ax_person                | hat                    | ax_anschrift                                       |  42616

-- ALKIS => ALB
-- ax_flurstueck				=> FLURST
-- ax_lagebezeichnungmithausnummer		=> STRASSEN
-- ax_lagebezeichnungohnehausnummer		=> STRASSEN
-- ax_lagebezeichnungkatalogeintrag		=> STR_SHL
-- ax_buchungsstelle				=> EIGNERART
-- ax_buchungsblatt				=> BESTAND
-- ax_namensnummer & ax_person & ax_anschrift	=> EIGNER

-- ax_flurstueck => flurst

SELECT alkis_dropobject('flurst');
CREATE TABLE flurst (
	flsnr character(20) NOT NULL,
	flsnrk character(9),
	gemashl character(6),
	flr character(3),
	entst character(13),
	fortf character(13),
	flsfl character(9),
	amtlflsfl double precision,
	gemflsfl double precision,
	af character(2),
	flurknr character(14),
	baublock character(12),
	flskoord character(18),
	fora character(4),
	fina character(4),
	h1shl character(2),
	h2shl character(2),
	hinwshl character(59),
	strshl character(32),
	gemshl character(32),
	hausnr character(8),
	lagebez character(54),
	k_anlverm character(1),
	anl_verm character(27),
	blbnr character(200),
	n_flst character(22),
	ff_entst integer NOT NULL,
	ff_stand integer,
	ff_datum character(8),
	primary key (flsnr)
) WITH OIDS;

INSERT INTO flurst(flsnr,flsnrk,gemashl,flr,entst,fortf,flsfl,amtlflsfl,gemflsfl,af,flurknr,baublock,flskoord,fora,fina,h1shl,h2shl,hinwshl,strshl,gemshl,hausnr,lagebez,k_anlverm,anl_verm,blbnr,n_flst,ff_entst,ff_stand,ff_datum)
   SELECT
     to_char(land,'fm00') || to_char(gemarkungsnummer,'fm0000') || '-' || to_char(coalesce(flurnummer,0),'fm000') || '-' || to_char(zaehler,'fm00000') || '/' || to_char(coalesce(mod(nenner,1000),0),'fm000') AS flsnr,
     to_char(zaehler,'fm00000') || '/' || to_char(coalesce(mod(nenner,1000),0),'fm000') AS flsnrk,
     to_char(land,'fm00') || to_char(gemarkungsnummer,'fm0000') AS gemashl,
     to_char(coalesce(flurnummer,0),'fm000') AS flr,
     substr(zeitpunktderentstehung,1,4)  || '/     -  ' AS entst,
     NULL AS fortf,
     amtlicheflaeche::int AS flsfl,
     amtlicheflaeche AS amtlflsfl,
     st_area(wkb_geometry) AS gemflsfl,
     '01' AS af,
     NULL AS flurknr,
     NULL AS baublock,
     to_char(st_x(st_centroid(wkb_geometry))*10,'fm00000000')||' '||to_char(st_y(st_centroid(wkb_geometry))*10,'fm00000000') AS flskoord,
     NULL AS fora,
     NULL AS fina,
     NULL AS h1shl,
     NULL AS h2shl,
     NULL AS hinwshl,
     NULL AS strshl,
     to_char(land,'fm00')||regierungsbezirk||to_char(kreis,'fm00')||to_char(gemeinde,'fm000') AS gemshl,
     NULL AS hausnr,
     NULL AS lagebez,
     NULL AS k_anlverm,
     NULL AS anl_verm,
     NULL AS blbnr,
     NULL AS n_flst,
     0 AS ff_entst,
     0 AS ff_stand,
     NULL AS ff_datum
   FROM ax_flurstueck a
   WHERE endet IS NULL
     -- Workaround für gleiche Bestände von mehrere Katasterämtern
     AND NOT EXISTS (
     	SELECT *
	FROM ax_flurstueck b
	WHERE b.endet IS NULL
	  AND a.land=b.land AND a.gemarkungsnummer=b.gemarkungsnummer AND coalesce(a.flurnummer,0)=coalesce(b.flurnummer,0) AND a.zaehler=b.zaehler AND coalesce(a.nenner,0)=coalesce(b.nenner,0)
	  AND b.beginnt<a.beginnt
	  AND a.ogc_fid<>b.ogc_fid
	)
     ;

CREATE INDEX flurst_idx0 ON flurst(oid);
CREATE INDEX flurst_idx1 ON flurst(h1shl);
CREATE INDEX flurst_idx2 ON flurst(gemashl);
CREATE INDEX flurst_idx3 ON flurst(strshl);
CREATE INDEX flurst_idx4 ON flurst(lagebez);
CREATE INDEX flurst_idx5 ON flurst(ff_stand);
CREATE INDEX flurst_idx6 ON flurst(ff_entst);
CREATE INDEX flurst_idx7 ON flurst(lagebez);
CREATE INDEX flurst_idx8 ON flurst(flsnr);

SELECT alkis_dropobject('str_shl');
CREATE TABLE str_shl (
	strshl character(32) NOT NULL PRIMARY KEY,
	strname varchar(200),
	gemshl character(32)
);

INSERT INTO str_shl(strshl,strname,gemshl)
	SELECT DISTINCT
		to_char(land,'fm00')||regierungsbezirk||to_char(kreis,'fm00')||to_char(gemeinde,'fm000')||'    '||trim(lage) AS strshl,
		bezeichnung,
		to_char(land,'fm00')||regierungsbezirk||to_char(kreis,'fm00')||to_char(gemeinde,'fm000') AS gemshl
	FROM ax_lagebezeichnungkatalogeintrag a
	WHERE endet IS NULL
	  -- Nur nötig, weil Kataloge nicht vernünfigt geführt werden und doppelte Einträge vorkommen
	  AND NOT EXISTS (SELECT * FROM ax_lagebezeichnungkatalogeintrag b WHERE b.endet IS NULL AND a.schluesselgesamt=b.schluesselgesamt AND b.beginnt<a.beginnt);

CREATE INDEX str_shl_idx0 ON str_shl(strshl);
CREATE INDEX str_shl_idx1 ON str_shl(gemshl);

SELECT alkis_dropobject('strassen');
CREATE TABLE strassen (
	flsnr character(20),
	pk character(8) NOT NULL,
	strshl character(32),
	hausnr character(8),
	ff_entst integer,
	ff_stand integer,
	primary key (pk)
);

SELECT alkis_dropobject('strassen_pk_seq');
CREATE SEQUENCE strassen_pk_seq;
INSERT INTO strassen(flsnr,pk,strshl,hausnr,ff_entst,ff_stand)
	SELECT
		flsnr,
		to_hex(nextval('strassen_pk_seq'::regclass)) AS pk,
		strshl,
		hausnr,
		0,
		0
	FROM (
		SELECT
			to_char(f.land,'fm00') || to_char(f.gemarkungsnummer,'fm0000') || '-' || to_char(coalesce(f.flurnummer,0),'fm000') || '-' || to_char(f.zaehler,'fm00000') || '/' || to_char(coalesce(f.nenner,0),'fm000') AS flsnr,
			to_char(l.land,'fm00')||l.regierungsbezirk||to_char(l.kreis,'fm00')||to_char(l.gemeinde,'fm000')||'    '||trim(lage) AS strshl,
			hausnummer AS hausnr
		FROM ax_lagebezeichnungmithausnummer l
		JOIN ax_flurstueck f ON ARRAY[l.gml_id] <@ f.weistauf AND f.endet IS NULL
		WHERE NOT l.lage IS NULL AND l.endet IS NULL
	UNION
		SELECT
			to_char(f.land,'fm00') || to_char(f.gemarkungsnummer,'fm0000') || '-' || to_char(coalesce(f.flurnummer,0),'fm000') || '-' || to_char(f.zaehler,'fm00000') || '/' || to_char(coalesce(f.nenner,0),'fm000') AS flsnr,
			to_char(l.land,'fm00')||l.regierungsbezirk||to_char(l.kreis,'fm00')||to_char(l.gemeinde,'fm000')||'    '||trim(lage) AS strshl,
			'' AS hausnr
		FROM ax_lagebezeichnungohnehausnummer l
		JOIN ax_flurstueck f ON ARRAY[l.gml_id] <@ f.zeigtauf AND f.endet IS NULL
		WHERE NOT l.lage IS NULL AND l.endet IS NULL
	) AS foo;

CREATE INDEX strassen_idx1 ON strassen(flsnr);
CREATE INDEX strassen_idx2 ON strassen(strshl);
CREATE INDEX strassen_ff_entst ON strassen(ff_entst);
CREATE INDEX strassen_ff_stand ON strassen(ff_stand);

SELECT alkis_dropobject('gem_shl');
CREATE TABLE gem_shl (
	gemshl character(32) NOT NULL,
	gemname character(100),
	primary key (gemshl)
);

INSERT INTO gem_shl(gemshl,gemname)
	SELECT
		to_char(schluesselgesamt,'fm00000000') AS gemshl,
		min(bezeichnung) AS gemname
	FROM ax_gemeinde a
	WHERE endet IS NULL
	GROUP BY to_char(schluesselgesamt,'fm00000000');

CREATE INDEX gem_shl_idx0 ON gem_shl(gemshl);

SELECT alkis_dropobject('gema_shl');
CREATE TABLE gema_shl (
	gemashl character(6) NOT NULL,
	gemarkung character(50),
	gemshl character(30),
	ag_shl character(4),
	primary key (gemashl)
);

INSERT INTO gema_shl(gemashl,gemarkung)
	SELECT
		to_char(land,'fm00')||to_char(gemarkungsnummer,'fm0000') AS gemashl,
		MIN(bezeichnung) AS gemarkung
	FROM ax_gemarkung
	WHERE endet IS NULL
	GROUP BY to_char(land,'fm00')||to_char(gemarkungsnummer,'fm0000');

CREATE INDEX gema_shl_gemshl ON gema_shl(gemshl);
CREATE INDEX gema_shl_ag_shl ON gema_shl(ag_shl);

SELECT alkis_dropobject('eignerart');
CREATE TABLE eignerart (
	flsnr character(20) NOT NULL,
	bestdnr character(16) NOT NULL,
	bvnr character(4) NOT NULL,
	b character(4),
	anteil character(24),
	auftlnr character(12),
	sa character(2),
	ff_entst integer NOT NULL,
	ff_stand integer,
	lkfs character(4),
	primary key (flsnr, bestdnr, bvnr)
);

INSERT INTO eignerart(flsnr,bestdnr,bvnr,b,anteil,auftlnr,sa,ff_entst,ff_stand,lkfs)
	SELECT
		to_char(f.land,'fm00') || to_char(f.gemarkungsnummer,'fm0000') || '-' || to_char(coalesce(f.flurnummer,0),'fm000') || '-' || to_char(f.zaehler,'fm00000') || '/' || to_char(coalesce(f.nenner,0),'fm000') AS flsnr,
		to_char(bb.land,'fm00') || to_char(bb.bezirk,'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		lpad(laufendenummer,4,'0') AS bvnr,
		buchungsart AS b,
		coalesce(bs.zaehler || '/' || bs.nenner,bs.zaehler::text) AS anteil,
		laufendenummer AS auftrlnr,
		NULL AS sa,
		0 AS ff_entst,
		0 AS ff_stand,
		NULL AS lkfs
	FROM ax_flurstueck f
	JOIN ax_buchungsstelle bs ON bs.gml_id=f.istgebucht AND bs.endet IS NULL
	JOIN ax_buchungsblatt bb ON bb.gml_id=bs.istbestandteilvon AND bb.endet IS NULL
	WHERE
		f.endet IS NULL
	UNION
	SELECT
		to_char(f.land,'fm00') || to_char(f.gemarkungsnummer,'fm0000') || '-' || to_char(coalesce(f.flurnummer,0),'fm000') || '-' || to_char(f.zaehler,'fm00000') || '/' || to_char(coalesce(f.nenner,0),'fm000') AS flsnr,
		to_char(bb.land,'fm00') || to_char(bb.bezirk,'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		lpad(bs.laufendenummer,4,'0') AS bvnr,
		bs.buchungsart AS b,
		coalesce(bs.zaehler || '/' || bs.nenner, bs.zaehler::text) AS anteil,
		-- bs.nummerimaufteilungsplan AS auftrlnr,
		bs.laufendenummer AS auftrlnr,
		NULL AS sa,
		0 AS ff_entst,
		0 AS ff_stand,
		NULL AS lkfs
	FROM ax_flurstueck f
	JOIN ax_buchungsstelle bs0 ON bs0.gml_id=f.istgebucht AND bs0.endet IS NULL
	JOIN ax_buchungsstelle bs  ON ARRAY[bs0.gml_id] <@ bs.an AND bs.endet IS NULL
	JOIN ax_buchungsblatt bb ON bb.gml_id=bs.istbestandteilvon AND bb.endet IS NULL
	WHERE f.endet IS NULL
	;

CREATE INDEX eignerart_idx1 ON eignerart(b);
CREATE INDEX eignerart_idx2 ON eignerart(flsnr);
CREATE INDEX eignerart_idx3 ON eignerart(bestdnr);
CREATE INDEX eignerart_idx4 ON eignerart(sa);
CREATE INDEX eignerart_ff_entst ON eignerart(ff_entst);
CREATE INDEX eignerart_ff_stand ON eignerart(ff_stand);

SELECT alkis_dropobject('bem_best');
CREATE TABLE bem_best (
	bestdnr character(16),
	pk character(8) NOT NULL,
	sa character(1),
	lnr character(4),
	text varchar,
	ff_entst integer,
	ff_stand integer,
	primary key (pk)
);

CREATE INDEX bem_best_idx1 ON bem_best(bestdnr);

SELECT alkis_dropobject('bem_best_pk_seq');
CREATE SEQUENCE bem_best_pk_seq;

INSERT INTO bem_best(bestdnr,pk,lnr,text,ff_entst,ff_stand)
	SELECT
		to_char(bb.land,'fm00') || to_char(bb.bezirk,'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		to_hex(nextval('bem_best_pk_seq'::regclass)) AS pk,
		laufendenummer AS lnr,
		beschreibungdessondereigentums AS text,
		0 AS ff_entst,
		0 AS ff_stand
	FROM ax_buchungsstelle bs
	JOIN ax_buchungsblatt bb ON bb.gml_id=bs.istbestandteilvon AND bb.endet IS NULL
	WHERE bs.beschreibungdessondereigentums IS NOT NULL AND bs.endet IS NULL;

SELECT alkis_dropobject('bestand');
CREATE TABLE bestand (
	bestdnr character(16) NOT NULL,
	gbbz character(4),
	gbblnr character(6),
	anteil character(24),
	auftlnr character(12),
	bestfl character(9),
	amtlbestfl double precision,
	ff_entst integer NOT NULL,
	ff_stand integer,
	pz character(1),
	PRIMARY KEY (bestdnr)
);
CREATE INDEX bestand_bestdnr ON bestand(bestdnr);
CREATE INDEX bestand_ff_entst ON bestand(ff_entst);
CREATE INDEX bestand_ff_stand ON bestand(ff_stand);

INSERT INTO bestand(bestdnr,gbbz,gbblnr,anteil,auftlnr,bestfl,ff_entst,ff_stand,pz)
	SELECT
		to_char(land,'fm00') || to_char(bezirk,'fm0000') || '-' || trim(buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		to_char(bezirk,'fm0000') AS gbbz,
		to_char(to_number(buchungsblattnummermitbuchstabenerweiterung,'000000'),'fm000000') AS gbblnr,
		NULL AS anteil,
		NULL AS auftrlnr,
		NULL AS bestfl,
		0 AS ff_entst,
		0 AS ff_stand,
		NULL AS pz
	FROM
		ax_buchungsblatt bb
	WHERE
		bb.endet IS NULL
	  -- Workaround für gleiche Bestände von mehrere Katasterämtern
	  AND NOT EXISTS (
	  	SELECT *
		FROM ax_buchungsblatt bb2
		WHERE bb2.endet IS NULL
		  AND bb.land=bb2.land AND bb.bezirk=bb2.bezirk AND trim(bb.buchungsblattnummermitbuchstabenerweiterung)=trim(bb2.buchungsblattnummermitbuchstabenerweiterung)
	          AND bb2.beginnt<bb.beginnt
	          AND bb2.ogc_fid<>bb.ogc_fid
	  )
	;

SELECT alkis_dropobject('eigner');
CREATE TABLE eigner (
	bestdnr character(16),
	pk character(8) NOT NULL,
	ab character(4),
	namensnr character(16),
	ea character(2),
	antverh character(16),

	name character(4),
	name1 varchar(200),
	name2 varchar(200),
	name3 varchar(200),
	name4 varchar(200),
	name5 varchar(200),
	name6 varchar(200),
	name7 varchar(200),
	name8 varchar(200),

	anrede character(20),
	vorname varchar(200),
	nachname varchar(200),
	namensteile character(200),
	ak_grade character(200),
	geb_name varchar(200),
	geb_datum character(10),
	str_hnr varchar(200),
	plz_pf character(20),
	postfach character(20),
	plz character(20),
	ort character(200),
	land character(100),
	ff_entst integer,
	ff_stand integer,

	primary key (pk)
);
SELECT alkis_dropobject('eigner_pk_seq');
CREATE SEQUENCE eigner_pk_seq;

INSERT INTO eigner(bestdnr,pk,ab,namensnr,ea,antverh,name,name1,name2,name3,name4,name5,name6,name7,name8,anrede,vorname,nachname,namensteile,ak_grade,geb_name,geb_datum,str_hnr,plz_pf,postfach,plz,ort,land,ff_entst,ff_stand)
	SELECT
		to_char(bb.land,'fm00') || to_char(bb.bezirk,'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		to_hex(nextval('eigner_pk_seq'::regclass)) AS pk,
		NULL AS ab,
		laufendenummernachdin1421 AS namensnr,
		NULL AS ea,
		zaehler||'/'||nenner AS antverh,
		substr(p.nachnameoderfirma,1,4) AS name,
		p.nachnameoderfirma || coalesce(', ' || p.vorname,'') AS name1,
		coalesce('geb. '||p.geburtsname||', ','') || '* ' || p.geburtsdatum AS name2,
		an.strasse || coalesce(' ' || an.hausnummer,'') AS name3,
		an.postleitzahlpostzustellung||' '||an.ort_post AS name4,
		bestimmungsland AS name5,
		NULL AS name6,
		NULL AS name7,
		NULL AS name8,
		(SELECT v FROM alkis_wertearten WHERE element='ax_person' AND bezeichnung='anrede' AND k=p.anrede::text) AS anrede,
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
	LEFT OUTER JOIN ax_anschrift an ON ARRAY[an.gml_id] <@ p.hat AND an.endet IS NULL
	WHERE nn.endet IS NULL;

CREATE INDEX eigner_idx1 ON eigner(bestdnr);
CREATE INDEX eigner_idx2 ON eigner(name);
CREATE INDEX eigner_ff_entst ON eigner(ff_entst);
CREATE INDEX eigner_ff_stand ON eigner(ff_stand);

UPDATE eigner SET name1=regexp_replace(name1, E'\\s\\s+', ' ');

DELETE FROM str_shl WHERE NOT EXISTS (SELECT * FROM strassen WHERE str_shl.strshl=strassen.strshl);
DELETE FROM gema_shl
	WHERE NOT EXISTS (SELECT * FROM flurst WHERE flurst.gemashl=gema_shl.gemashl)
	  AND NOT EXISTS (SELECT * FROM bestand WHERE substr(bestdnr,1,6)=gema_shl.gemashl);

UPDATE gema_shl SET gemshl=(SELECT gemshl FROM flurst WHERE flurst.gemashl=gema_shl.gemashl LIMIT 1);

DELETE FROM gem_shl
  WHERE NOT EXISTS (SELECT * FROM gema_shl WHERE gema_shl.gemshl=gem_shl.gemshl)
    AND NOT EXISTS (SELECT * FROM str_shl WHERE str_shl.gemshl=gem_shl.gemshl)
    AND NOT EXISTS (SELECT * FROM flurst WHERE flurst.gemshl=gem_shl.gemshl);

--
--
--

SELECT alkis_dropobject('eign_shl');
CREATE TABLE eign_shl (
    b character(4) NOT NULL,
    eignerart character(60),
    primary key (b)
);
CREATE INDEX eign_shl_idx0 ON eign_shl(b);

INSERT INTO eign_shl(b,eignerart)
	SELECT
		k AS b,
		v AS eignerart
	FROM alkis_wertearten
	WHERE element='ax_buchungsstelle'
	  AND bezeichnung='buchungsart';

SELECT alkis_dropobject('hinw_shl');
CREATE TABLE hinw_shl (
	shl character(2) NOT NULL,
	hinw_txt character(50),
	primary key (shl)
);

SELECT alkis_dropobject('sonderbaurecht');
CREATE TABLE sonderbaurecht
(
	bestdnr char(16),
	pk char(8) NOT NULL,
	lnr char(2),
	text varchar,
	ff_entst integer,
	ff_stand integer,
	PRIMARY KEY (pk)
);

CREATE INDEX sonderbaurecht_idx1 ON sonderbaurecht(bestdnr);

SELECT alkis_dropobject('klas_3x');
CREATE TABLE klas_3x (
	flsnr character(20),
	pk character(8) NOT NULL,
	klf character(32),
	fl character(16),
	gemfl double precision,
	klz character(10),
	wertz1 character(10),
	wertz2 character(10),
	bem character(5),
	unf_anm character(20),
	ff_entst integer,
	ff_stand integer,
	primary key (pk)
);
CREATE INDEX klas_3x_idx1 ON klas_3x(flsnr);
CREATE INDEX klas_3x_idx2 ON klas_3x(klf);


SELECT alkis_dropobject('kls_shl');
CREATE TABLE kls_shl
(
	klf CHAR(32) NOT NULL,
	klf_text CHAR(200),
	primary key (klf)
);

SELECT alkis_dropobject('bem_fls');
CREATE TABLE bem_fls
(
	flsnr CHAR(20) NOT NULL,
	lnr CHAR(2) NOT NULL,
	text CHAR(52),
	ff_entst INTEGER NOT NULL ,
	ff_stand INTEGER,
	primary key (flsnr, lnr)
);
CREATE INDEX bem_fls_idx1 ON bem_fls(flsnr);

SELECT alkis_dropobject('erbbaurecht');
CREATE TABLE erbbaurecht(
	bestdnr char(16),
	pk char(8) NOT NULL,
	lnr char(2),
	text char(59),
	ff_entst integer,
	ff_stand integer,
	PRIMARY KEY (pk)
);
CREATE INDEX erbbaurecht_idx1 ON erbbaurecht(bestdnr);

SELECT alkis_dropobject('nutz_21');
CREATE TABLE nutz_21
(
	flsnr CHAR(20),
	pk CHAR(8) NOT NULL,
	nutzsl CHAR(32),
	fl CHAR(16),
	gemfl double precision,
	ff_entst INTEGER,
	ff_stand INTEGER,
	primary key (pk)
);
CREATE INDEX nutz_21_idx1 ON nutz_21(flsnr);
CREATE INDEX nutz_21_idx2 ON nutz_21(nutzsl);

SELECT alkis_dropobject('nutz_shl');
CREATE TABLE nutz_shl
(
	nutzshl char(32) NOT NULL,
	nutzung CHAR(200),
	primary key (nutzshl)
);
CREATE INDEX nutz_shl_idx0 ON nutz_shl(nutzshl);

SELECT alkis_dropobject('verf_shl');
CREATE TABLE verf_shl
(
	verfshl char(2) NOT NULL,
	verf_txt char(50),
	PRIMARY KEY (verfshl)
);
CREATE INDEX verf_shl_idx0 ON verf_shl(verfshl);

SELECT alkis_dropobject('vor_flst');
CREATE TABLE vor_flst(
	flsnr char(20),
	pk char(8) NOT NULL,
	v_flsnr char(20),
	ff_entst integer,
	ff_stand integer,
	PRIMARY KEY (pk)
);
CREATE INDEX vor_flst_idx1 ON vor_flst(flsnr);
CREATE INDEX vor_flst_idx2 ON vor_flst(v_flsnr);

SELECT alkis_dropobject('best_lkfs');
CREATE TABLE best_lkfs
(
	bestdnr char(16) NOT NULL,
	lkfs char(4) NOT NULL,
	PRIMARY KEY (bestdnr,lkfs)
);
CREATE INDEX best_lkfs_idx0 ON best_lkfs(bestdnr);

SELECT alkis_dropobject('flurst_lkfs');
CREATE TABLE flurst_lkfs
(
	flsnr char(20) NOT NULL,
	lkfs char(4) NOT NULL,
	PRIMARY KEY (flsnr,lkfs)
);
CREATE INDEX flurst_lkfs_idx0 ON flurst_lkfs(flsnr);

SELECT alkis_dropobject('fortf');
CREATE TABLE fortf
(
	ffnr integer NOT NULL,
	auftragsnr char(9),
	lkfs char(4),
	antragsnr char(10),
	daa char(2),
	datum char(10),
	beschreibung char(250),
	anford char(250),
	datei char(250),
	PRIMARY KEY (ffnr)
);
INSERT INTO fortf(ffnr,beschreibung) VALUES (1, 'Aus ALKIS übernommen: '||to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'));

SELECT alkis_dropobject('fina');
CREATE TABLE fina(
	fina_nr char(6) NOT NULL,
	fina_name char(200),
	PRIMARY KEY (fina_nr)
);
CREATE INDEX fina_idx0 ON fina(fina_nr);

SELECT alkis_dropobject('fs');
CREATE TABLE fs(
	fs_key integer,
	fs_obj varchar,
	alb_key varchar
);
INSERT INTO fs(fs_key,fs_obj,alb_key)
  SELECT
    ogc_fid
    ,gml_id
    ,to_char(land,'fm00') || to_char(gemarkungsnummer,'fm0000') || '-' || to_char(coalesce(flurnummer,0),'fm000') || '-' || to_char(zaehler,'fm00000') || '/' || to_char(coalesce(mod(nenner,1000),0),'fm000')
  FROM ax_flurstueck;

CREATE INDEX fs_obj ON fs(fs_obj);
CREATE INDEX fs_alb ON fs(alb_key);

SELECT alkis_dropobject('ausfst');
CREATE TABLE ausfst
(
	flsnr char(20),
	pk char(8) NOT NULL,
	ausf_st varchar,
	verfnr char(6),
	verfshl char(2),
	ff_entst integer,
	ff_stand integer,
	primary key (pk)
);
CREATE INDEX ausfst_idx1 ON ausfst(flsnr);
CREATE INDEX ausfst_idx2 ON ausfst(ausf_st);

SELECT alkis_dropobject('afst_shl');
CREATE TABLE afst_shl
(
	ausf_st varchar NOT NULL,
	afst_txt char(200),
	PRIMARY KEY (ausf_st)
);

CREATE INDEX afst_shl_idx0 ON afst_shl(ausf_st);

UPDATE bestand
   SET amtlbestfl=(
        SELECT SUM(amtlflsfl*CASE WHEN anteil IS NULL OR anteil='0/0' THEN 1.0 ELSE split_part(anteil,'/',1)::float8 / split_part(anteil,'/',2)::float8 END)
        FROM flurst
        JOIN eignerart ON flurst.flsnr=eignerart.flsnr
        WHERE eignerart.bestdnr=bestand.bestdnr
        );

UPDATE bestand SET bestfl=amtlbestfl::int WHERE amtlbestfl<=2147483647; -- maxint

\i alkis-nutzung-und-klassifizierung.sql
