CREATE TRIGGER delete_feature_trigger 
	BEFORE INSERT ON delete 
	FOR EACH ROW 
	EXECUTE PROCEDURE delete_feature_hist();
