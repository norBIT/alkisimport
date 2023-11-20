\set nas2alb true
\ir ../../config.sql

\if :nas2alb
SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

SELECT alkis_dropobject('vor_flst_pk_seq');
CREATE SEQUENCE vor_flst_pk_seq;

DELETE FROM vor_flst;
INSERT INTO vor_flst(flsnr,pk,v_flsnr,ff_entst,ff_stand)
	SELECT
		substr(  flsnr, 1, 6) || '-' || substr(  flsnr, 7, 3) || '-' || substr(  flsnr, 10, 5) || '/' || coalesce(nullif(substr(  flsnr, 15, 3), '___'), '000') AS flsnr,
		to_hex(nextval('vor_flst_pk_seq'::regclass)) AS pk,
		substr(v_flsnr, 1, 6) || '-' || substr(v_flsnr, 7, 3) || '-' || substr(v_flsnr, 10, 5) || '/' || coalesce(nullif(substr(v_flsnr, 15, 3), '___'), '000') AS v_flsnr,
		0 AS ff_entst,
		0 AS ff_stand
	FROM (
		SELECT
			unnest(nachfolgerflurstueckskennzeichen) AS flsnr,
			flurstueckskennzeichen AS v_flsnr
		FROM ax_historischesflurstueck
		WHERE endet IS NULL
	) AS foo;

\endif
