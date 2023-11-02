^\s*$
^\/\*+\s*$
^\s+\*(\s+.*\s+|\*+)\*\/?\s*$
^.* ERROR:  recognized configuration parameter "application_name"\\r\s*$
^.*SET application_name='.*';\s*$
^psql:.*\s+STATEMENT:\s+\/\*+\s*$
^PG: Primary key name \(FID\): ogc_fid(, type : int4)?\s*$
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
^OGR: OGROpen\(.*\) succeeded as NAS\.\s*$
^OGR: OGROpen\(PG:.*\) succeeded as PostgreSQL\.\s*$
^GDAL: In GDALDestroy - unloading GDAL shared library\.\s*$
^psql:.*: (NOTICE|HINWEIS):\s+(function|aggregate|Funktion|Aggregatfunktion) ([^.]+\.)?alkis_accum\(anyarray\) (does not exist, skipping|existiert nicht, wird \S+bersprungen)
^psql:.*: (NOTICE|HINWEIS):\s+(function|Funktion) ([^.]+\.)?alkis_(drop\(\)|dropobject\(text\)|delete\(\)|mviews\(\)|update_schema\(\)|set_schema\(text\)) (does not exist, skipping|existiert nicht, wird \S+bersprungen)$
^psql:.*: (NOTICE|HINWEIS):\s+(trigger|Trigger)\s+\S+_insert.*(does not exist, skipping|existiert nicht, wird \S+bersprungen)
^psql:.*: (NOTICE|HINWEIS):\s+Dropping (table|view|sequence) 
^psql:.*: (NOTICE|HINWEIS):\s+gserialized_gist_joinsel: jointype 4 not supported\s*$
^psql:.*: (NOTICE|HINWEIS):\s+(geometry|LWGEOM)_gist_joinsel called with incorrect join type\s*$
^psql:.*: (NOTICE|HINWEIS):\s+no non-null\/empty features, unable to compute statistics\s*$
^psql:.*: (NOTICE|HINWEIS):\s+PostGIS: Unable to compute statistics for .*: No non-null\/empty features\s*$
^psql:.*: (NOTICE|HINWEIS):\s+no notnull values, invalid stats\*$
^psql:.*: (WARNUNG|WARNING):\s+.*(only (superuser|table or database owner) can vacuum it|nur Superuser kann sie vacuumen)\s*$
^TIP:  No function matches the given name and argument types\. You might need to add explicit type casts\.
^\s+(DROP TRIGGER IF EXISTS|CREATE TRIGGER) \S+_insert
^CONTEXT:  PL\/pgSQL-Funktion (pg_temp_\d+\.)?(alkis|alb)_.* Zeile \d+ bei RAISE
^CONTEXT:  SQL statement in PL\/PgSQL function "alkis_(update_schema|set_comments)" near line \d+\s*$
^CONTEXT:  SQL statement "ALTER TABLE alkis_(flaechen|linien|schriften) ADD PRIMARY KEY \(katalog,signaturnummer\)"
^CONTEXT:  COPY (ax_[a-z]+|ap_pto|ap_lpo|ap_ppo|ap_darstellung), line 1\s*$
^\s+\^\s*$
^.*: (NOTICE|HINWEIS):  CREATE TABLE
^NOTICE:  CREATE TABLE
.*drop cascades to 
^ERROR:  relation "alkis_importlog" already exist\s*s
^psql:alkis-compat.sql:.*: ERROR:  function ".*" already exists with same argument types\s*$
^psql:alkis-compat.sql:.*: FEHLER:  Funktion .* existiert bereits mit den selben Argumenttypen\s*$
^psql:alkis-compat.sql:.*: ERROR:  function .* does not exist\s*$
^psql:alkis-compat.sql:.*: FEHLER:  Funktion .* existiert nicht\s*$
^psql:alkis-compat.sql:.*: FEHLER:  Berechtigung nur f\S+r Eigent\S+mer der Funktion st_dump\s*$
^psql:alkis-compat.sql:.*: ERROR:  aggregate ([^.]+\.)?array_agg\(any(element|array)\) does not exist
^psql:alkis-compat.sql:.*: ERROR:  must be owner of function array_agg
^psql:alkis-compat.sql:.*: FEHLER:  Berechtigung nur f\S+r Eigent\S+mer der Funktion array_agg\s*$
^psql:alkis-compat.sql:.*: FEHLER:  Aggregatfunktion ([^.]\.)?array_agg\(any(element|array)\) existiert nicht
^psql:alkis-compat.sql:.*: ERROR:  cannot drop function array_agg\(anyelement\) because it is required by the database system
^psql:alkis-compat.sql:.*: FEHLER:  kann .* nicht löschen, wird vom Datenbanksystem benötigt
^(LINE|ZEILE) 2:   SELECT buffer\(\$1,\$2\);\s*$
^(LINE|ZEILE) 2:   SELECT line_interpolate_point\(\$1,\$2\);\s*$
^(LINE|ZEILE) 2:   SELECT force_2d\(\$1\);\s*$
^(LINE|ZEILE) 2:   SELECT st_force_2d\(\$1\);\s*$
^(LINE|ZEILE) 2:   SELECT st_force_collection\(\$1\);\s*$
^(LINE|ZEILE) 2:   SELECT force_collection\(\$1\);\s*$
^(LINE|ZEILE) 2:   SELECT intersection\(\$1,\$2\);\s*$
^\s+\^\\r\s*$
^HINT:  Keine Funktion stimmt mit dem angegebenen Namen und den Argumenttypen .*berein. Sie m.*ssen m.*glicherweise ausdr.*ckliche Typumwandlungen hinzuf.*gen\.\s*$
^HINT:  No function matches the given name and argument types. You might need to add explicit type casts\.\s*$
^psql:alkis-update.sql:.*: NOTICE:  ALTER TABLE \/ ADD PRIMARY KEY will create implicit index "alkis_(flaechen|linien|schriften)_pkey" for table "alkis_(flaechen|linien|schriften)"
^.*(Tabelle|Sicht|Sequenz|Funktion|Constraint|Index).*(gel\S+scht|geleert)\..*$
^\s+(addgeometrycolumn|alkis_clean|alkis_drop|alkis_dropobject|alkis_create_bsrs|alkis_set_comments|alkis_update_schema|alkis_besondereflurstuecksgrenze|alkis_fixareas|alkis_inherit|version|postgis_version|\?column\?|alkis_set_schema|create_trigger)\s*$
^-+\s*$
^\s+[^.]+\..*\.(wkb_geometry|dummy|objektkoordinaten|line) SRID:\d+ TYPE:(GEOMETRY|LINESTRING|POINT|MULTIPOINT|POLYGON) DIMS:2\+?\s*$
^\s+[^.]+\.ax_punktortau\.wkb_geometry SRID:\d+ TYPE:(POINT|GEOMETRY) DIMS:3\+?\s*$
^\s+[^.]+\.po_points\.point SRID:\d+ TYPE:MULTIPOINT DIMS:2\+?\s*$
^\s+[^.]+\.po_lines\.line SRID:\d+ TYPE:MULTILINESTRING DIMS:2\+?\s*$
^\s+[^.]+\.po_polygons\.polygon SRID:\d+ TYPE:MULTIPOLYGON DIMS:2\+?\s*$
^\s+[^.]+\.po_labels\.(point|line) SRID:\d+ TYPE:(POINT|LINESTRING) DIMS:2\+?\s*$
^\s+[^.]+\.alkis_schriften\.position SRID:0 TYPE:POINT DIMS:2\+?\s*$
^\s+[^.]+\.alkis_joinlines\.line SRID:\d+ TYPE:LINESTRING DIMS:2\+?\s*$
^\s+[^.]+\.alkis_linie\.position SRID:0 TYPE:LINESTRING DIMS:2\+?\s*$
^\(\d+ (Zeilen?|rows?)\)\s*$
^removed.*\.(gfs|xml)'\s*$
^[CK]ONTEXT:  (SQL statement|SQL-Anweisung) \S+(DROP TABLE .* CASCADE|CREATE TABLE)
PL\/pgSQL( function|-Funktion) "(alkis_dropobject|alkis_clean|alkis_drop|alkis_joinlines|alkis_besondereflurstuecksgrenze|alkis_update_schema)" (line|Zeile) \d+ (at|bei) ((EXECUTE|SQL|execute)( statement|-Anweisung)|PERFORM|RAISE)
PL\/pgSQL( function|-Funktion) alkis_drop\(\) (line|Zeile) \d+ (at|bei) EXECUTE
PL\/pgSQL( function|-Funktion) alkis_dropobject\(text\) (line|Zeile) \d+ (at|bei) EXECUTE
PL\/pgSQL( function|-Funktion) (alkis_update_schema\(\)|alb_update_schema\(\)) (line|Zeile) \d+ (at|bei) PERFORM
ERROR:  relation "[^.]+\.alkis_(stricharten|stricharten_i|schriften|randlinie|linien|linie|konturen|strichart|flaechen|farben)" does not exist
ERROR:  table "alkis_(stricharten|stricharten_i|schriften|randlinie|linien|linie|konturen|strichart|flaechen|farben)" does not exist
ERROR:  sequence "alkis_(farben|konturen|linie|randlinie|strichart|stricharten|stricharten_i)_id_seq" does not exist
SQL( statement|-Anweisung) \S+SELECT\s+alkis_dropobject\('alkis_konturen'\)
^.*(ERROR|FEHLER):.*application_name
^\s+(alkis_createklassifizierung|alkis_createnutzung|alkis_checkflurstueck|alkis_createausfuehrendestellen|ax_besondereflurstuecksgrenze|alkis_create_bcrs|alkis_boeschung|alb_update_schema|deletehist|format|create_accum)\s*$
^ ax_klassifizierung und ax_klassifizierungsschluessel erzeugt\.\s*$
^ ax_tatsaechlichenutzung und ax_tatsaechlichenutzungsschluessel erzeugt\.\s*$
^ ax_ausfuehrendestellen erzeugt\.\s*$
^ ax_flurstueck gepr\S+ft\.\s*$
^\s*setval\s*$
^\s+\d+\s*$
^GML: Minimum arc step angle is \d+ degrees \(was \d+\.\d+°\)\.
^GML: Minimum arc step segment length is \d+\.\d+ was \d\.\d+ with \d+\.\d+°\)\.
^GML: Minimum arc step angle is \d+ degrees \(was \d+\.\d+°; segment length \d+\.\d+\)\.
^GML: Increasing arc step to \d+\.\d+° \(was \d+\.\d+° with segment length \d+\.\d+ at radius \d+\.\d+; min segment length is \d+\.\d+\)
^NAS: Overwriting existing property ((AX_[^.]+)\.(hat|hat|an|zu|weistAuf|zeigtAuf|gehoertAnteiligZu|weitereAdressen)|AX_Gebaeude\.name|AX_HistorischesFlurstueck(OhneRaumbezug)?\.(nachfolger|vorgaenger)Flurstueckskennzeichen|AX_(GrablochDer)?Bodenschaetzung\.(bedeutung|sonstigeAngaben)|AP_PTO\.dientZurDarstellungVon|(AX_Bodenschaetzung|AX_MusterLandesmusterUndVergleichsstueck)\.entstehungsartOderKlimastufeWasserverhaeltnisse|AX_(Grenzpunkt|SonstigerVermessungspunkt|BesondererBauwerkspunkt|BesondererGebaeudepunkt|Aufnahmepunkt|Sicherungspunkt|BesondererTopographischerPunkt)\.sonstigeEigenschaft|AX_Flurstueck\.sonstigeEigenschaften\|AX_SonstigeEigenschaften_Flurstueck\|(kennungSchluessel|flaecheDesAbschnitts|angabenZumAbschnittFlurstueck|angabenZumAbschnittNummerAktenzeichen|angabenZumAbschnittFlurstueck|kennungSchluessel|flaecheDesAbschnitts)|(AX_[^.]+|AP_(PTO|LTO|LPO|PPO|Darstellung))\.modellart\|AA_Modellart\|(advStandardModell|sonstigesModell)|AX_Punktort(TA|AG)\.qualitaetsangaben\|AX_DQPunktort\|herkunft\|LI_Lineage\|processStep\|LI_ProcessStep\|(description\|CharacterString|dateTime\|DateTime|(processor\|CI_ResponsibleParty\|(role\|individualName\|CharacterString)))|AX_HistorischesFlurstueck(ALB)?\.(buchung\||nachfolgerFlurstueckskennzeichen|vorgaengerFlurstueckskennzeichen)|AX_Gemarkung\.istAmtsbezirkVon|AX_Flurstueck\.zustaendigeStelle\|AX_Dienststelle_Schluessel\|(land|stelle)) of value '.*' with '.*' \(gml_id: .*\)\.\s*$
^NAS: Overwriting existing property AX_HistorischesFlurstueck.buchung\|AX_Buchung_HistorischesFlurstueck|(buchungsblattkennzeichen|buchungsblattnummerMitBuchstabenerweiterung) of value '.*' with '.*' \(gml_id: .*\)\.
^NAS: Overwriting existing property AX_HistorischesFlurstueckALB.buchung\|AX_Buchung_HistorischesFlurstueck\|(laufendeNummerDerBuchungsstelle|buchungsblattkennzeichen|buchungsblattnummerMitBuchstabenerweiterung|buchungsart) of value '.*' with '.*' \(gml_id: .*\)\.
^NAS: Overwriting existing property AX_Punktort(AG|TA|AU)\.qualitaetsangaben\|AX_DQPunktort\|herkunft\|LI_Lineage\|processStep\|LI_ProcessStep\|description\|AX_LI_ProcessStep_Punktort_Description of value '(Erhebung|Berechnung)' with '(Erhebung|Berechnung)' \(gml_id: .*\)\.
^NAS: Overwriting existing property AX_PunktortAU\.qualitaetsangaben\|AX_DQPunktort\|herkunft\|LI_Lineage\|processStep\|LI_ProcessStep\|dateTime\|DateTime of value '.*' with '.*' \(gml_id: .*\)\.
^NAS: Overwriting existing property .* of value '(?P<overwrittenvalue>[^']+)' with '(?P=overwrittenvalue)' \(gml_id: .*\)\.$
^NAS: Failed to translate srsName='urn:adv:crs:ETRS89_UTM33'
#^DETAIL:  (Schl\S+ssel \S+|Key )\(gml_id, beginnt\)=(.*) (already exists|existiert bereits)\.\s*$
^PG: PQexecParams\(INSERT INTO "(ax_bundesland|ax_dienststelle|ax_buchungsblattbezirk|ax_kreisregion|ax_regierungsbezirk|ax_lagebezeichnungohnehausnummer)" \(
^PG: Truncated (alkis_beziehungen\.beziehung_(von|zu)|.*\.gml_id) field value '.*' to 16 characters\.
^More than 1000 errors or warnings have been reported\. No more will be reported from now\.\s*$
^ERROR 1: INSERT command for new feature failed\.\s*$
.*ERROR:  current transaction is aborted, commands ignored until end of transaction block\s*$
.*L.+schvorgang l.+scht ebenfalls .*$
^Command: INSERT INTO "(ax_[a-z]+|ap_pto|ap_lpo|ap_ppo|ap_darstellung)" \("
#.*(FEHLER:  doppelter Schl\S+sselwert verletzt Unique-Constraint \S+|ERROR:  duplicate key value violates unique constraint ")(ax_[a-z]+|ap_pto|ap_lpo|ap_ppo|ap_darstellung)_gml\S+\s*$
^ERROR 1: COPY statement failed\.\s*$
^(OGR2OGR|GDALVectorTranslate): \d+ features written in layer '.*'\s*$
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field '(LI_Source|datumDerLetztenUeberpruefung|CI_RoleCode|AX_LI_ProcessStep_Punktort_Description|AX_Datenerhebung_Punktort|CI_RoleCode|AX_LI_ProcessStep_OhneDatenerhebung_Description|AX_LI_ProcessStep_MitDatenerhebung_Description|AX_Datenerhebung)' not found in destination layer 'ax_.*'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'CharacterString' not found in destination layer 'ax_(anschrift|bahnverkehr|bauraumoderbodenordnungsrecht|bauwerkimgewaesserbereich|bauwerkimverkehrsbereich|bauwerkoderanlagefuerindustrieundgewerbe|bauwerkoderanlagefuersportfreizeitunderholung|bewertung|bodenschaetzung|denkmalschutzrecht|flaechebesondererfunktionalerpraegung|flaechegemischternutzung|fliessgewaesser|friedhof|gebaeude|gehoelz|grablochderbodenschaetzung|halde|heide|industrieundgewerbeflaeche|klassifizierungnachstrassenrecht|klassifizierungnachwasserrecht|landwirtschaft|leitung|musterlandesmusterundvergleichsstueck|naturumweltoderbodenschutzrecht|person|platz|punktortag|punktortau|punktortta|schutzgebietnachwasserrecht|sonstigesbauwerkodersonstigeeinrichtung|sportfreizeitunderholungsflaeche|stehendesgewaesser|strassenverkehr|sumpf|tagebaugrubesteinbruch|transportanlage|turm|unlandvegetationsloseflaeche|wald|weg|wohnbauflaeche|anderefestlegungnachwasserrecht|moor|vorratsbehaelterspeicherbauwerk|schiffsverkehr|flugverkehr|hafenbecken|untergeordnetesgewaesser|strassenverkehrsanlage|boeschungkliff)'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'DateTime' not found in destination layer 'ax_(anschrift|bahnverkehr|bauraumoderbodenordnungsrecht|bauwerkimgewaesserbereich|bauwerkimverkehrsbereich|bauwerkoderanlagefuerindustrieundgewerbe|bauwerkoderanlagefuersportfreizeitunderholung|bewertung|bodenschaetzung|denkmalschutzrecht|flaechebesondererfunktionalerpraegung|flaechegemischternutzung|fliessgewaesser|friedhof|gebaeude|gehoelz|grablochderbodenschaetzung|halde|heide|industrieundgewerbeflaeche|klassifizierungnachstrassenrecht|klassifizierungnachwasserrecht|landwirtschaft|leitung|musterlandesmusterundvergleichsstueck|naturumweltoderbodenschutzrecht|person|platz|punktortag|punktortau|punktortta|schutzgebietnachwasserrecht|sonstigesbauwerkodersonstigeeinrichtung|sonstigesrecht|sportfreizeitunderholungsflaeche|stehendesgewaesser|strassenverkehr|sumpf|tagebaugrubesteinbruch|transportanlage|turm|unlandvegetationsloseflaeche|wald|weg|wohnbauflaeche)'\.$
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'administrativeFunktion' not found in destination layer 'ax_gemeinde'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'bezeichnung' not found in destination layer 'ax_(denkmalschutzrecht|naturumweltoderbodenschutzrecht)'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'buchung\|AX_Buchung_HistorischesFlurstueck\|buchungsblattbezirk\|AX_Buchungsblattbezirk_Schluessel\|land' not found in destination layer 'ax_(historischesflurstueck|historischesflurstueckalb)'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'gemeindezugehoerigkeit\|AX_Gemeindekennzeichen\|land' not found in destination layer 'ax_(flurstueck|historischesflurstueck)'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'qualitaetsangaben\|AX_DQMitDatenerhebung\|herkunft\|LI_Lineage\|source\|LI_Source\|description\|CharacterString' not found in destination layer 'ax_.*'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'qualitaetsangaben\|AX_DQPunktort\|herkunft\|LI_Lineage\|processStep\|LI_ProcessStep\|description\|CharacterString' not found in destination layer 'ax_punktort(ag|au|ta)'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'qualitaetsangaben\|AX_DQPunktort\|herkunft\|LI_Lineage\|source\|LI_Source\|description\|CharacterString' not found in destination layer 'ax_punktort(ag|au|ta)'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'zustaendigeStelle|AX_Dienststelle_Schluessel|land' not found in destination layer 'ax_flurstueck'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Skipping field 'identifier' not found in destination layer '(ax|ap|ks|aa)_.*'\.
(OGR2OGR|Warning 1|GDALVectorTranslate): Value '(?P<intvalue>\d+).0+' of field ax_gebaeude\.grundflaeche parsed incompletely to integer (?P=intvalue)\.
Warning 1: Unable to find driver SEGY to unload from GDAL SKIP environment variable\.
GDALVectorTranslate: Unable to write feature \d+ into layer
^Warning 6: Progress turned off as fast feature count is not available\.
