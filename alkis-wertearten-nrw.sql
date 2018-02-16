/***************************************************************************
 *                                                                         *
 * Project:  norGIS ALKIS Import                                           *
 * Purpose:  Aus der GeoInfoDok geparste Kataloge                          *
 * Author:   Jürgen E. Fischer <jef@norbit.de>                             *
 *                                                                         *
 ***************************************************************************
 * Copyright (c) 2012-2018, Jürgen E. Fischer <jef@norbit.de>              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

BEGIN;
INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_einrichtunginoeffentlichenbereichen','59102','REO','''Einrichtung in öffentlichen Bereichen'' sind Gegenstände und Einrichtungen verschiedenster Art in öffentlichen oder öffentlich zugänglichen Bereichen (z.B. Straßen, Parkanlagen) aus kommunaler Sicht.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('1','KS_Art_EinrichtungInOeffentlichenBereichen','ART','''Art'' beschreibt die Art der baulichen Anlage aus kommunaler Sicht.','ks_einrichtunginoeffentlichenbereichen','NWDKOM','art');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','Bank','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1200','Spielgerät','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1300','Fahrradständer','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1400','Abfalleimer','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1500','Postdepot','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1600','Blumenkübel','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1700','Tisch','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('5000','Weg (nicht in Verkehrsanlagen)','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('5100','sonstige Flächen','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('5200','Sport-/Spielflächen','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('5300','Grab','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('5500','Randbefestigung, Einfassung','art','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','KS_Oberflaechenmaterial_KommunaleBauwerkeEinrichtungen','OFM','''Oberflächenmaterial'' beschreibt die Beschaffenheit der Oberfläche einer öffentlichen Einrichtung aus kommunaler Sicht.','ks_einrichtunginoeffentlichenbereichen','NWDKOM','oberflaechenmaterial');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1010','Asphalt','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1020','Bituminöser Belag','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1030','Beton','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1040','Wassergebundener Belag','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1050','Pflaster','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1060','Gehwegplatten','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2010','Kunststoff','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3010','Sand','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3020','Rindenmulch','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('4010','Schotterrasen','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('9999','Sonstiges','oberflaechenmaterial','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','KS_Material_EinrichtungInOeffentlichenBereichen','MTL','''Material'' beschreibt die Materialbeschaffenheit eines Objektes aus kommunaler Sicht.','ks_einrichtunginoeffentlichenbereichen','NWDKOM','material');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1000','Stein','material','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2000','Metall','material','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3000','Holz','material','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('4000','Kunststoff','material','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('9999','Sonstiges','material','ks_einrichtunginoeffentlichenbereichen');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','BEZ','''Bezeichnung'' ist die von einer Fachstelle vergebene Kennziffer von ''Einrichtung in öffentlichen Bereichen'' aus kommunaler Sicht.','ks_einrichtunginoeffentlichenbereichen','NWDKOM','bezeichnung');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','KS_Zustand_KommunaleBauwerkeEinrichtungen','ZUS','''Zustand'' beschreibt, ob die Oberfläche einer öffentlichen Einrichtung aus kommunaler Sicht unbefestigt ist.','ks_einrichtunginoeffentlichenbereichen','NWDKOM','zustand');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','unbefestigt','zustand','ks_einrichtunginoeffentlichenbereichen');

INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_bauwerkanlagenfuerverundentsorgung','59103','REO','''Bauwerk oder Anlagen für Ver- und Entsorgung'' ist ein Bauwerk, eine Anlage oder Einrichtung an Ver- und Entsorgungsleitungen aus kommunaler Sicht.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('1','KS_Art_BauwerkAnlagenFuerVerUndEntsorgung','ART','''Art'' beschreibt die Art von ''Bauwerk oder Anlage für Ver- und Entsorgung''.','ks_bauwerkanlagenfuerverundentsorgung','NWDKOM','art');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','städtischer Entwässerungsgraben','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1200','Peilrohr','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1300','Wasserhahn','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1400','Wasserschieber','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1500','Kanaldeckel','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2100','Schieberkappe Gas','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2200','Schieberkappe Wasser','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3100','Stahlgittermast ohne Sockel','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3200','Sockel für Gittermast','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3300','Hochspannungsmast','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3400','Stahlgittermast mit Sockel','art','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','BEZ','''Bezeichnung'' ist die von einer Fachstelle vergebene Kennziffer von ''Bauwerk oder Anlage für Ver- und Entsorgung'' aus kommunaler Sicht.','ks_bauwerkanlagenfuerverundentsorgung','NWDKOM','bezeichnung');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','KS_Zustand_BauwerkOderAnlageFuerVerUndEntsorgung','ZUS','''Zustand'' ist der Zustand von ''Bauwerk oder Anlage für Ver- und Entsorgung'' aus kommunaler Sicht.','ks_bauwerkanlagenfuerverundentsorgung','NWDKOM','zustand');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2100','Außer Betrieb, stillgelegt, verlassen','zustand','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2200','Verfallen, zerstört','zustand','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('4100','Offen','zustand','ks_bauwerkanlagenfuerverundentsorgung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('4200','Verschlossen','zustand','ks_bauwerkanlagenfuerverundentsorgung');

INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_sonstigesbauwerk','59109','REO','''Sonstiges Bauwerk'' ist ein Bauwerk oder eine Einrichtung, das/die nicht zu den anderen Objektarten der Objektartengruppe Bauwerke und Einrichtungen gehört aus kommunaler Sicht.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('1','KS_Bauwerksfunktion_SonstigesBauwerk','BWF','''Bauwerksfunktion'' beschreibt die Art oder Funktion von ''Sonstiges Bauwerk'' aus kommunaler Sicht.','ks_sonstigesbauwerk','NWDKOM','bauwerksfunktion');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','Balkon','bauwerksfunktion','ks_sonstigesbauwerk');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3000','einzelner Zaun','bauwerksfunktion','ks_sonstigesbauwerk');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('4000','Schwengelpumpe','bauwerksfunktion','ks_sonstigesbauwerk');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('5000','Wetterschutzüberdachung','bauwerksfunktion','ks_sonstigesbauwerk');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','BEZ','''Bezeichnung'' ist die von einer Fachstelle vergebene Kennziffer von ''Sonstiges Bauwerk'' aus kommunaler Sicht.','ks_sonstigesbauwerk','NWDKOM','bezeichnung');

INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_einrichtungimstrassenverkehr','59201','REO','''Einrichtung im Strassenverkehr'' ist ein Bauwerk oder Einrichtung, die dem Verkehr dient, aus kommunaler Sicht.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('1','KS_Art_EinrichtungImStrassenverkehr','ART','''Art'' beschreibt die Art der ''Einrichtung im Straßenverkehr'' aus kommunaler Sicht.','ks_einrichtungimstrassenverkehr','NWDKOM','art');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','ruhender Verkehr','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2100','Bordstein','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2200','Rinne','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3000','Fahrbahn','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3100','Radweg','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3120','Fußweg','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3140','Rad- und Fußweg','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3150','Wirtschaftsweg','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3200','Parkplatz','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3300','Öffentlicher Platz','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3500','Fahrbahnteiler, Mittelinsel','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3600','Furt','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('4100','Radarkontrolle','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('9999','Sonstiges','art','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('1','KS_Oberflaechenmaterial_KommunaleBauwerkeEinrichtungen','OFM','''Oberflächenmaterial'' beschreibt die Beschaffenheit der Oberfläche aus kommunaler Sicht.','ks_einrichtungimstrassenverkehr','NWDKOM','oberflaechenmaterial');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1010','Asphalt','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1020','Bituminöser Belag','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1030','Beton','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1040','Wassergebundener Belag','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1050','Pflaster','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1060','Gehwegplatten','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2010','Kunststoff','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3010','Sand','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3020','Rindenmulch','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('4010','Schotterrasen','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('9999','Sonstiges','oberflaechenmaterial','ks_einrichtungimstrassenverkehr');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','BEZ','''Bezeichnung'' ist die von einer Fachstelle vergebene Kennziffer von ''Sonstiges Bauwerk'' aus kommunaler Sicht.','ks_einrichtungimstrassenverkehr','NWDKOM','bezeichnung');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','ks_einrichtungimstrassenverkehr','ZUS','''Zustand'' beschreibt, ob die Oberfläche einer öffentlichen Einrichtung aus kommunaler Sicht unbefestigt ist.','ks_einrichtungimstrassenverkehr','NWDKOM','zustand');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','unbefestigt','zustand','ks_einrichtungimstrassenverkehr');

INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_verkehrszeichen','59202','REO','Verkehrszeichen sind örtliche Anordnungen nach der StVO, die nur dort getroffen werden, wo dies aufgrund der besonderen Umstände zwingend geboten ist.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..*','KS_Gefahrzeichen_Verkehrszeichen','GFZ','Gefahrzeichen mahnen zu erhöhter Aufmerksamkeit, insbesondere zur Verringerung der Geschwindigkeit im Hinblick auf eine Gefahrsituation','ks_verkehrszeichen','NWDKOM','gefahrzeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','Kinder','gefahrzeichen','ks_verkehrszeichen');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..*','KS_Vorschriftzeichen_Verkehrszeichen','VSZ','Vorschriftzeichen. Schilder oder weiße Markierungen auf der Straßenoberfläche enthalten Gebote und Verbote','ks_verkehrszeichen','NWDKOM','vorschriftzeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','Andreaskreuz','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1210','Tempo 30 Zone','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1221','Pfeil rechts','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1222','Pfeil geradeaus/rechts','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1223','Pfeil links','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1224','Pfeil geradeaus/links','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1225','Pfeil geradeaus','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1230','Haltelinie','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1240','Sperrfläche','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1300','Ver-/Gebotsschild','vorschriftzeichen','ks_verkehrszeichen');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..*','KS_Richtzeichen_Verkehrszeichen','RIZ','''Richtzeichen'' geben besondere Hinweise zur Erleichterung des Verkehrs. Sie können auch Anordnungen enthalten.','ks_verkehrszeichen','NWDKOM','richtzeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1110','Leitmarkierung unterbrochen','richtzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1111','Leitmarkierung durchgezogen','richtzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1200','Leitpfosten','richtzeichen','ks_verkehrszeichen');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..*','KS_Verkehrseinrichtung_Verkehrszeichen','VEI','''Verkehrseinrichtungen'' sind Schranken, Sperrpfosten, Parkuhren, Parkscheinautomaten, Geländer, Absperrgeräte, Leiteinrichtungen, sowie Blinklicht- und Lichtzeichenanlagen.','ks_verkehrszeichen','NWDKOM','verkehrseinrichtung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','Sperrpfahl, Poller','verkehrseinrichtung','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1110','Barriere','verkehrseinrichtung','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1199','sonstige Absperrung','verkehrseinrichtung','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1210','Parkscheinautomat','verkehrseinrichtung','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1220','Parkuhr','verkehrseinrichtung','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1400','Warnleuchte','verkehrseinrichtung','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1600','Leitplanke','verkehrseinrichtung','ks_verkehrszeichen');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..*','KS_Zusatzzeichen_Verkehrszeichen','ZSZ','''Zusatzzeichen'' sind Verkehrszeichen. Die Zusatzzeichen zeigen auf weißem Grund mit schwarzem Rand schwarze Zeichnungen oder Aufschriften. Sie sind dicht unter den Verkehrszeichen angebracht.','ks_verkehrszeichen','NWDKOM','zusatzzeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1110','Schwerbehinderte','zusatzzeichen','ks_verkehrszeichen');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1120','Kraftomnibus','zusatzzeichen','ks_verkehrszeichen');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','BEZ','''Bezeichnung'' ist die von einer Fachstelle vergebene Kennziffer von ''Verkehrszeichen''.','ks_verkehrszeichen','NWDKOM','bezeichnung');

INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_einrichtungimbahnverkehr','59206','REO','''Einrichtungen im Bahnverkehr'' ist ein Bauwerk, das dem Bahnverkehr dient, aus kommunaler Sicht.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('1','KS_Art_EinrichtungImBahnverkehr','ART','''Art'' beschreibt die bauliche Art von ''Einrichtungen im Bahnverkehr''.','ks_einrichtungimbahnverkehr','NWDKOM','art');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','Gleisende, Prellbock','art','ks_einrichtungimbahnverkehr');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1200','Bahn-Kilometerstein','art','ks_einrichtungimbahnverkehr');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','BEZ','''Bezeichnung'' ist die von einer Fachstelle vergebene Kennziffer von ''Einrichtungen im Bahnverkehr'' aus kommunaler Sicht.','ks_einrichtungimbahnverkehr','NWDKOM','bezeichnung');

INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_einrichtungimgewaesserbereich','59207','REO','''Bauwerk im Gewässerbereich'' ist ein Bauwerk, mit dem ein Wasserlauf unter einem Verkehrsweg oder einem anderen Wasserlauf hindurch geführt wird. Ein ''Bauwerk im Gewässerbereich'' dient dem Abfluss oder der Rückhaltung von Gewässern oder als Messeinrichtung zur Feststellung des Wasserstandes oder als Uferbefestigung aus kommunaler Sicht.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('1','KS_Bauwerksfunktion_BauwerkImGewaesserbereich','BWF','''Bauwerksfunktion'' beschreibt die bauliche Art von ''Bauwerk im Gewässerbereich'' aus kommunaler Sicht.','ks_einrichtungimgewaesserbereich','NWDKOM','bauwerksfunktion');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','Rohrdurchlass','bauwerksfunktion','ks_einrichtungimgewaesserbereich');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1200','Einlass/Auslass','bauwerksfunktion','ks_einrichtungimgewaesserbereich');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','BEZ','''Bezeichnung'' ist die von einer Fachstelle vergebene Kennziffer von ''Einrichtungen im Bahnverkehr'' aus kommunaler Sicht.','ks_einrichtungimgewaesserbereich','NWDKOM','bezeichnung');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','KS_Zustand_BauwerkImGewaesserbereich','ZUS','''Zustand'' beschreibt die Beschaffenheit von ''Bauwerk im Gewässerbereich'' aus kommunaler Sicht.','ks_einrichtungimgewaesserbereich','NWDKOM','zustand');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2100','Außer Betrieb, stillgelegt, verlassen','zustand','ks_einrichtungimgewaesserbereich');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('4000','Im Bau','zustand','ks_einrichtungimgewaesserbereich');

INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_vegetationsmerkmal','59301','REO','''Vegetationsmerkmal'' beschreibt den zusätzlichen Bewuchs oder besonderen Zustand einer Grundfläche aus kommunaler Sicht.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','KS_Bewuchs_Vegetationsmerkmal','BWS','''Bewuchs'' ist die Art des Vegetationsmerkmals aus kommunaler Sicht.','ks_vegetationsmerkmal','NWDKOM','bewuchs');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1013','Solitärstrauch','bewuchs','ks_vegetationsmerkmal');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','Rasen','bewuchs','ks_vegetationsmerkmal');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2100','erhw. Laubbaum','bewuchs','ks_vegetationsmerkmal');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('2200','erhw. Nadelbaum','bewuchs','ks_vegetationsmerkmal');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('3100','Beet','bewuchs','ks_vegetationsmerkmal');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','KS_Zustand_Vegetationsmerkmal','ZUS','''Zustand'' ist der Zustand von ''Vegetationsmerkmal'' aus kommunaler Sicht.','ks_vegetationsmerkmal','NWDKOM','zustand');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1100','Nass','zustand','ks_vegetationsmerkmal');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','Length','BRO','''Breite des Objekts'' ist die Breite in [m] von ''Vegetationsmerkmal'' aus kommunaler Sicht.','ks_vegetationsmerkmal','NWDKOM','breitedesobjekts');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','NAM','''Name'' ist der Eigenname von ''Vegetationsmerkmal'' aus kommunaler Sicht.','ks_vegetationsmerkmal','NWDKOM','name');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','BEZ','''Bezeichnung'' ist die von einer Fachstelle vergebene Kennziffer von ''Vegetationsmerkmal'' aus kommunaler Sicht.','ks_vegetationsmerkmal','NWDKOM','bezeichnung');

INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_bauraumoderbodenordnungsrecht','59401','REO','[E] ''Bau-, Raum- oder Bodenordnungsrecht'' ist ein fachlich übergeordnetes Gebiet von Flächen mit bodenbezogenen Beschränkungen, Belastungen oder anderen Eigenschaften nach öffentlichen Vorschriften.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','KS_ArtDerFestlegung_BauRaumOderBauordnungsrecht','ADF','''Art der Festlegung'' ist die auf den Grund und Boden bezogene Art der Beschränkung, Belastung oder anderen öffentlich-rechtlichen Eigenschaft.','ks_bauraumoderbodenordnungsrecht','NWDKOM','artderfestlegung');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1715','Bebauungsplan, einleitender Beschluss','artderfestlegung','ks_bauraumoderbodenordnungsrecht');
INSERT INTO alkis_wertearten(k,v,bezeichnung,element) VALUES ('1821','Gestaltungssatzung','artderfestlegung','ks_bauraumoderbodenordnungsrecht');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','BEZ','''Bezeichnung'' ist die amtlich Festlegung von ''Bau-, Raum- oder Bodenordnungsrecht''.','ks_bauraumoderbodenordnungsrecht','NWDKOM','bezeichnung');

INSERT INTO alkis_elemente(name,kennung,objekttyp,definition,abgeleitet_aus,modellart,type) VALUES ('ks_kommunalerbesitz','59402','REO','[E] ''Kommunaler Besitz'' beschreibt Zuständigkeit an und Nutzung von kommunalem Besitz.','{"au_objekt"}','NWDKOM','Objektart');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','ZUS','Zuständigkeit','ks_kommunalerbesitz','NWDKOM','zustaendigkeit');
INSERT INTO alkis_attributart(kardinalitaet,datentyp,kennung,definition,element,modellart,bezeichnung) VALUES ('0..1','CharacterString','NTZ','Nutzung','ks_kommunalerbesitz','NWDKOM','nutzung');

COMMIT;
