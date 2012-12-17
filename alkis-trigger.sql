CREATE TRIGGER delete_feature_trigger 
	BEFORE INSERT ON delete 
	FOR EACH ROW 
	EXECUTE PROCEDURE delete_feature_hist();

CREATE RULE insert_beziehung_rule AS ON INSERT TO alkis_beziehungen
	DO ALSO
	DELETE FROM alkis_beziehungen
	WHERE ogc_fid<new.ogc_fid
	  AND beziehung_von=new.beziehung_von
	  AND beziehungsart=new.beziehungsart
          AND beziehung_zu=new.beziehung_zu;
