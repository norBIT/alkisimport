/******************************************************************************
 *
 * Project:  norGIS ALKIS Import
 * Purpose:  Trigger für Fortführung mit Historie
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ******************************************************************************
 * Copyright (c) 2012-2014, Jürgen E. Fischer <jef@norbit.de>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 ****************************************************************************/

CREATE TRIGGER delete_feature_trigger 
	BEFORE INSERT ON delete 
	FOR EACH ROW 
	EXECUTE PROCEDURE delete_feature_hist();

CREATE TRIGGER insert_beziehung_trigger
	AFTER INSERT ON alkis_beziehungen
	FOR EACH ROW
	EXECUTE PROCEDURE alkis_beziehung_inserted();
