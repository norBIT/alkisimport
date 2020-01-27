SET search_path = :"alkis_schema", :"parent_schema", :"postgis_schema", public;

CREATE FUNCTION pg_temp.deletehist(hist BOOLEAN) RETURNS void AS $$
BEGIN
        IF NOT hist THEN
		PERFORM alkis_delete_all_endet();
        END IF;
END;
$$ LANGUAGE plpgsql;

SELECT pg_temp.deletehist(:alkis_hist);
