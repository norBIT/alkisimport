CREATE TRIGGER delete_feature_trigger 
	BEFORE INSERT ON delete 
	FOR EACH ROW 
	EXECUTE PROCEDURE delete_feature_hist();

CREATE TRIGGER insert_beziehung_trigger
	AFTER INSERT ON alkis_beziehungen
	FOR EACH ROW
	EXECUTE PROCEDURE alkis_beziehung_inserted();
