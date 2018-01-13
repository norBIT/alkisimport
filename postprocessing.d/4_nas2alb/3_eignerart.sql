SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

---
--- Eigentümerarten
---

DELETE FROM eignerart;
INSERT INTO eignerart(flsnr,bestdnr,bvnr,b,anteil,auftlnr,sa,ff_entst,ff_stand,lkfs)
	SELECT
		alkis_flsnr(f) AS flsnr,
		to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		lpad(substr(laufendenummer,length(laufendenummer)-3),4,'0') AS bvnr,
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
	WHERE f.endet IS NULL
	UNION
	SELECT
		alkis_flsnr(f) AS flsnr,
		to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
		lpad(substr(bs.laufendenummer,length(bs.laufendenummer)-3),4,'0') AS bvnr,
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
