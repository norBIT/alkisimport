\set nas2alb true
\ir ../../config.sql

\if :nas2alb

SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

---
--- Eigentümerarten
---

CREATE FUNCTION pg_temp.addfrac(a numeric[], b numeric[]) RETURNS numeric[] AS
$$
BEGIN
        IF a[2] = b[2] THEN
                RETURN ARRAY[a[1]+b[1], a[2]];
        ELSE
                RETURN ARRAY[a[1]*b[2] + a[2]*b[1], a[2]*b[2]];
        END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION pg_temp.gcd(a0 numeric, b0 numeric) RETURNS numeric AS
$$
DECLARE
        res numeric;
BEGIN
        IF a0<>trunc(a0) OR b<>trunc(b0) THEN
                RETURN 1;
        END IF;

        WITH RECURSIVE t(a,b) AS (
                VALUES (abs(a0), abs(b0))
        UNION ALL
                SELECT b, mod(a,b) FROM t WHERE b > 0
        )
        SELECT a INTO res FROM t WHERE b = 0;
        RETURN res;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE FUNCTION pg_temp.reducefrac(a numeric[]) RETURNS varchar AS $$
DECLARE
  n bigint;
BEGIN
        SELECT pg_temp.gcd(a[1], a[2]) INTO n;
        RETURN a[1]/n || '/' || a[2]/n;
EXCEPTION WHEN OTHERS THEN
        RETURN a[1] || '/' || a[2];
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE AGGREGATE pg_temp.sumfrac(numeric[]) (
        sfunc = pg_temp.addfrac,
        stype = numeric[],
        initcond = '{0,1}',
        finalfunc = pg_temp.reducefrac
);

DELETE FROM eignerart;
INSERT INTO eignerart(flsnr,bestdnr,bvnr,b,anteil,auftlnr,sa,ff_entst,ff_stand,lkfs)
        SELECT
                flsnr,bestdnr,
                to_char(row_number() OVER (PARTITION BY bestdnr ORDER BY auftrlnr), 'fm0000') AS bvnr,
                b,anteil,auftrlnr,
                NULL AS sa,
                0 AS ff_entst,
                0 AS ff_stand,
                NULL AS lkfs
        FROM (
                WITH RECURSIVE
                        eignerart AS (
                                SELECT
                                        /* 0 AS level, ARRAY[bs.gml_id]::varchar[] AS bses, */
                                        bs.gml_id,
                                        alkis_flsnr(f) AS flsnr,
                                        to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
                                        bs.buchungsart AS b,
                                        coalesce(bs.zaehler,1) AS zaehler,
                                        coalesce(bs.nenner,1) AS nenner,
                                        laufendenummer AS auftrlnr
                                FROM ax_flurstueck f
                                JOIN ax_buchungsstelle bs ON bs.gml_id=f.istgebucht AND bs.endet IS NULL
                                JOIN ax_buchungsblatt bb ON bb.gml_id=bs.istbestandteilvon AND bb.endet IS NULL
                                WHERE f.endet IS NULL
                        UNION ALL
                                SELECT
                                        /* ea.level+1 AS level, ea.bses || ARRAY[bs.gml_id]::varchar[] AS bses, */
                                        bs.gml_id,
                                        ea.flsnr,
                                        to_char(alkis_toint(bb.land),'fm00') || to_char(alkis_toint(bb.bezirk),'fm0000') || '-' || trim(bb.buchungsblattnummermitbuchstabenerweiterung) AS bestdnr,
                                        bs.buchungsart AS b,
                                        coalesce(ea.zaehler,1)*coalesce(bs.zaehler,1) AS zaehler,
                                        coalesce(ea.nenner,1)*coalesce(bs.nenner,1) AS nenner,
                                        bs.laufendenummer AS auftrlnr
                                FROM eignerart ea
                                JOIN ax_buchungsstelle bs ON ARRAY[ea.gml_id] <@ bs.an
                                JOIN ax_buchungsblatt bb ON bb.gml_id=bs.istbestandteilvon AND bb.endet IS NULL
                        )
                SELECT
                        flsnr, bestdnr, b, auftrlnr,
                        alkis_truncate(pg_temp.sumfrac(ARRAY[zaehler::numeric, nenner::numeric]), 24) AS anteil
                FROM eignerart
                GROUP BY flsnr, bestdnr, b, auftrlnr
        ) AS foo
        ;

\endif
