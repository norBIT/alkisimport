^\s*$
^PG: Primary key name \(FID\): ogc_fid\s*$
^PG: Using column 'ogc_fid' as FID for table '.*'\s*$
^PG: Layer '.*' geometry type: (LINESTRING:Line String|MULTILINESTRING:Multi Line String|POLYGON:Polygon|MULTIPOINT:Multi Point|POINT:Point|GEOMETRY:Unknown \(any\)), Dim=2\s*$
^PG: Layer 'po_.*' geometry type: MULTIPOLYGON:Multi Polygon, Dim=2\s*$
^PG: Layer 'ax_punktortau' geometry type: POINT:3D Point, Dim=3\s*$
^PG: DBName=".*"\s*$
^PG: PostgreSQL version string : '.*'\s*$
^PG: PostGIS version string : '.*'\s*$
^PG: SoftCommit\(\) with no transaction active\.\s*$
^PG: PQexecParams\(.* = (PGRES_TUPLES_OK|PGRES_COMMAND_OK)
^PG: PQexecParams\(.*[0-9A-F]{100,}\s*$
^VSI: ~VSIUnixStdioFilesystemHandler\(\) : nTotalBytesRead = 521
^OGR2OGR: \d+ features written in layer '.*'\s*$
^OGR: OGROpen\(.*\) succeeded as NAS\.\s*$
^OGR: OGROpen\(PG:.*\) succeeded as PostgreSQL\.\s*$
^GDAL: In GDALDestroy - unloading GDAL shared library\.\s*$
^psql:.*: (NOTICE|HINWEIS):  (function|Funktion) (alkis_drop\(\)|alkis_dropobject\(text\)|alkis_delete\(\)|alkis_mviews\(\)|alkis_update_schema\(\)) (does not exist, skipping|existiert nicht, wird \S+bersprungen)$
^psql:.*: (NOTICE|HINWEIS):  Dropping (table|view|sequence) 
^psql:.*: (NOTICE|HINWEIS):  CREATE TABLE
.*drop cascades to 
^psql:alkis-compat.sql:.*: ERROR:  function ".*" already exists with same argument types\s*$
^psql:alkis-compat.sql:.*: FEHLER:  Funktion .* existiert bereits mit den selben Argumenttypen\s*$
^psql:alkis-compat.sql:.*: ERROR:  function geom_accum\(geometry\[\], geometry\) does not exist\s*$
^psql:alkis-compat.sql:.*: FEHLER:  Funktion geom_accum\(geometry\[\], geometry\) existiert nicht\s*$
^psql:alkis-compat.sql:.*: FEHLER:  Berechtigung nur f\S+r Eigent\S+mer der Funktion st_dump\s*$
^.*(Tabelle|Sicht|Sequenz|Funktion|Constraint).*gel\S+scht\..*$
^\s+(addgeometrycolumn|alkis_drop|alkis_dropobject|version|postgis_version)\s*$
^-+\s*$
^\s+public\..*\.(wkb_geometry|dummy) SRID:25832 TYPE:(GEOMETRY|LINESTRING|POINT|MULTIPOINT) DIMS:2\s*$
^\s+public\.ax_punktortau\.wkb_geometry SRID:25832 TYPE:POINT DIMS:3\s*$
^\s+public\.po_points\.point SRID:25832 TYPE:MULTIPOINT DIMS:2\s*$
^\s+public\.po_lines\.line SRID:25832 TYPE:MULTILINESTRING DIMS:2\s*$
^\s+public\.po_polygons\.polygon SRID:25832 TYPE:MULTIPOLYGON DIMS:2\s*$
^\s+public\.po_labels\.(point|line) SRID:25832 TYPE:(POINT|LINESTRING) DIMS:2\s*$
^\s+public\.alkis_schriften\.position SRID:0 TYPE:POINT DIMS:2
^\s+public\.alkis_linie\.position SRID:0 TYPE:LINESTRING DIMS:2
^\(\d+ rows?\)\s*$
^removed.*\.(gfs|xml)'\s*$
^CONTEXT:  (SQL statement|SQL-Anweisung) \S+DROP TABLE .* CASCADE\S+
^\s*PL\/pgSQL function "alkis_dropobject" line \d+ at (execute|EXECUTE)( statement|-Anweisung)
ERROR:  relation "public\.alkis_(stricharten|stricharten_i|schriften|randlinie|linien|linie|konturen|strichart|flaechen|farben)" does not exist
ERROR:  table "alkis_(stricharten|stricharten_i|schriften|randlinie|linien|linie|konturen|strichart|flaechen|farben)" does not exist
ERROR:  sequence "alkis_(farben|konturen|linie|randlinie|strichart|stricharten|stricharten_i)_id_seq" does not exist
^\s+(alkis_createklassifizierung|alkis_createnutzung|alkis_checkflurstueck)\s+$
^ ax_klassifizierung und ax_klassifizierungsschluessel erzeugt\.\s*$
^ ax_tatsaechlichenutzung und ax_tatsaechlichenutzungsschluessel erzeugt\.\s*$
^ ax_klassifizierung und ax_klassifizierungsschluessel erzeugt\.\s*$
^ ax_flurstueck gepr\S+ft\.\s*$
^GML: Minimum arc step angle is \d+ degrees \(was \d+\.\d+°\)\.
^GML: Minimum arc step segment length is \d+\.\d+ was \d\.\d+ with \d+\.\d+°\)\.
^GML: Minimum arc step angle is \d+ degrees \(was \d+\.\d+°; segment length \d+\.\d+\)\.
^GML: Minimum arc step angle is \d+ degrees \(was \d+\.\d+°; segment length \d+\.\d+\)\.
^GML: Increasing arc step to \d+\.\d+° \(was \d+\.\d+° with segment length \d+\.\d+ at radius \d+\.\d+; min segment length is \d+\.\d+\)
^NAS: Overwriting existing property ((AX_SonstigerVermessungspunkt|AX_Aufnahmepunkt|AX_Buchungsstelle|AX_Flurstueck|AX_Gebaeude)\.(hat|hat|an|zu|weistAuf|zeigtAuf)|AX_Gebaeude\.name|AX_HistorischesFlurstueck\.nachfolgerFlurstueckskennzeichen|AX_GrablochDerBodenschaetzung\.bedeutung|AX_Bodenschaetzung\.sonstigeAngaben|AP_PTO\.dientZurDarstellungVon|(AX_Bodenschaetzung|AX_MusterLandesmusterUndVergleichsstueck)\.entstehungsartOderKlimastufeWasserverhaeltnisse|AX_(Grenzpunkt|SonstigerVermessungspunkt|BesondererBauwerkspunkt|BesondererGebaeudepunkt|Aufnahmepunkt|Sicherungspunkt|BesondererTopographischerPunkt)\.sonstigeEigenschaft|AX_Flurstueck\.sonstigeEigenschaften|AX_SonstigeEigenschaften_Flurstueck|flaecheDesAbschnitts|(AX_(Anschrift|Bundesland|Dienststelle|Regierungsbezirk|KreisRegion|Gemeinde|Gebaeude|Bauteil)|AP_(PTO|LPO|PPO|Darstellung))\.modellart\|AA_Modellart\|advStandardModell|AX_Punktort(TA|AG)\.qualitaetsangaben\|AX_DQPunktort\|herkunft\|LI_Lineage\|processStep\|LI_ProcessStep\|(description\|CharacterString|dateTime\|DateTime|(processor\|CI_ResponsibleParty\|(role\|CI_RoleCode|individualName\|CharacterString)))|AX_HistorischesFlurstueck(ALB)?\.(buchung\||nachfolgerFlurstueckskennzeichen|vorgaengerFlurstueckskennzeichen)|AX_Gemarkung\.istAmtsbezirkVon\|AX_Dienststelle_Schluessel\|land|AX_Gemarkung\.istAmtsbezirkVon\|AX_Dienststelle_Schluessel\|stelle) of value '.*' with '.*' \(gml_id: .*\)\.\s*$
^Command: INSERT INTO "(ax_bundesland|ax_dienststelle|ax_buchungsblattbezirk|ax_kreisregion|ax_regierungsbezirk|ax_gemarkung|ax_gemarkungsteilflur|ax_kommunalesgebiet)" \("
.*(FEHLER:  doppelter Schl\S+sselwert verletzt Unique-Constraint \S+|ERROR:  duplicate key value violates unique constraint ")(ax_bundesland|ax_dienststelle|ax_buchungsblattbezirk|ax_kreisregion|ax_regierungsbezirk|ax_gemarkung|ax_gemarkungsteilflur|ax_kommunalesgebiet)_gml\S+\s*$
^DETAIL:  (Schl\S+ssel \S+|Key )\(gml_id, beginnt\)=(.*) (already exists|existiert bereits)\.\s*$
^PG: PQexecParams\(INSERT INTO "(ax_bundesland|ax_dienststelle|ax_buchungsblattbezirk|ax_kreisregion|ax_regierungsbezirk)" \(
^PG: Truncated (alkis_beziehungen\.beziehung_(von|zu)|.*\.gml_id) field value '.*' to 16 characters\.
^More than 1000 errors or warnings have been reported\. No more will be reported from now\.\s*$
^ERROR 1: INSERT command for new feature failed\.\s*$
.*L.+schvorgang l.+scht ebenfalls .*$
