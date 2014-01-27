-- PRAGMA encoding="UTF-8";

DROP TABLE IF EXISTS metadata;
CREATE TABLE IF NOT EXISTS metadata (
	`key` VARCHAR(8) PRIMARY KEY,
	`value` TEXT 
);


DROP TABLE IF EXISTS gares;
CREATE TABLE IF NOT EXISTS gares (
	`code` VARCHAR(3) NOT NULL,
	`name` VARCHAR(60) NOT NULL,
	`uic`  INTEGER NOT NULL PRIMARY KEY,
	`is_transilien` INTEGER DEFAULT 1
);

DROP TABLE IF EXISTS gares_lines;
CREATE TABLE IF NOT EXISTS gares_lines (
	`uic`	INTEGER NOT NULL REFERENCES gares(uic),
	`line`	VARCHAR(3) NOT NULL,
	PRIMARY KEY (`uic`, `line`)
);

DELETE FROM gares;

-- source codes UIC : 
-- http://aurelienb.pagesperso-orange.fr/HTML/transports/obli_UIC.htm

INSERT INTO gares (code, uic, name) VALUES
	('AB',  8727141, 'Aulnay sous Bois'),
	('ABL', 8754526, 'Ablon'),
	('ACW', 8738165, 'Achères-Ville'),
	('AEE', 8738113, 'Asnières sur Seine'),
	('AEH', 8738673, 'Aubergenville Elisabethville'),
	('AHM', 8738104, 'Avenue Henri Martin'),
	('ALC', 8727130, 'Aubervilliers La Courneuve'),
	('ANY', 8738149, 'Andrésy'),
	('APK', 8754320, 'Avenue du Président Kennedy'),
	('ARK', 8775867, 'Arcueil Cachan'),
	('ARP', 8754546, 'Arpajon'),
	('ARW', 8738184, 'Argenteuil'),
	('ATH', 8754525, 'Athis Mons'),
	('ATW', 8775875, 'Antony'),
	('AUU', 8775859, 'Auber'),
	('AUW', 8727654, 'Auvers-sur-Oise'),
	('AVF', 8738103, 'Avenue Foch'),
	('BAM', 8727147, 'Blanc Mesnil'),
	('BBN', 8727628, 'La Borne Blanche'),
	('BCO', 8738107, 'Bois Colombes'),
	('BDE', 8727144, 'Sevran Beaudottes'),
	('BDY', 8711340, 'Bondy' ),
	('BEC', 8738200, 'Bécon les Bruyères'),
	('BEL', 8736692, 'Saint-Germain-en-Laye Bel Air Fourqueux'),
	('BFM', 8732832, 'Bibliothèque François Mitterrand'),
	('BFX', 8768139, 'Le Bras de Fer'),
	('BGK', 8775868, 'Bagneux'),
	('BGV', 8738244, 'Bougival'),
	('BIH', 8754548, 'Breuillet Bruyères le Chatel'),
	('BIS', 8739354, 'Bièvres'),
	('BJN', 8768147, 'Boutigny'),
	('BJR', 8768220, 'Bois Le Roi'),
	('BKR', 8768251, 'Boissise-le-Roi'),
	('BLA', 8738115, 'Boissy-l''Aillerie'),
	('BLU', 8739311, 'Bellevue'),
	('BNY', 8768212, 'Brunoy'),
	('BOF', 8727648, 'Bouffemont Moisselles'),
	('BOM', 8768411, 'Bourron Marlotte Grez'),
	('BQA', 8775832, 'Bry sur Marne'),
	('BQC', 8775877, 'Les Baconnets'),
	('BQQ', 8775869, 'Bourg la Reine'),
	('BQV', 8768151, 'Buno-Gironville'),
	('BRK', 8727645, 'Bruyères-sur-Oise'),
	('BRN', 8727644, 'Boran-sur-Oise'),
	('BRW', 8754549, 'Breuillet Village'),
	('BSO', 8754517, 'Bouray'),
	('BSR', 8727664, 'Bessancourt'),
	('BSW', 8727655, 'Belloy - Saint-Martin'),
	('BUR', 8768143, 'Ballancourt'),
	('BVI', 8739332, 'Boulevard Victor - Pont du Garigliano'),
	('BVJ', 8775885, 'Bures sur Yvette'),
	('BWI', 8768440, 'Boigneville'),
	('BWR', 8754318, 'Boulainvilliers'),
	('BXG', 8775498, 'Bussy Saint-Georges'),
	('BXI', 8768213, 'Boussy Saint-Antoine'),
	('BXN', 8768419, 'Bagneaux sur Loing'),
	('BXP', 8711377, 'Les Boullereaux Champigny'),
	('BXR', 8775820, 'Boissy Saint-Léger'),
 	('BVA', 8738162, 'Bréval'),
	('BY' , 8754519, 'Brétigny'),
	('BYS', 8739336, 'Beynes'),
	('CAZ', 8739363, 'Chilly Mazarin'),
	('CBK', 8738108, 'Colombes'),
	('CBV', 8768214, 'Combs la Ville Quincy'),
	('CEG', 8727603, 'Champ de Courses d''Enghien'),
	('CEJ', 8727606, 'Cernay'),
	('CES', 8768216, 'Cesson'),
	('CEV', 8738122, 'Chaumont-en-Vexin'),
	('CEX', 8768163, 'Le Coudray-Monceaux'),
	('CFD', 8738145, 'Conflans-Fin-d''Oise'),
	('CGG', 8711352, 'Chenay Gagny' ),
	('CGJ', 8775817, 'Champigny'),
	('CGP', 8775800, 'Charles de Gaulle-Étoile'),
	('CGW', 8739327, 'Coignières'),
	('CH',  8739400, 'Chartres'),
	('CHK', 8754515, 'Chamarande'),
	('CHQ', 8754631, 'Chemin d''Antony'),
	('CHR', 8738119, 'Chars'),
	('CHV', 8739317, 'Chaville Vélizy'),
	('CJN', 8711650, 'Changis Saint-Jean'),
	('CJR', 8768241, 'Chartrettes'),
	('CJV', 8738265, 'Cergy le Haut'),
	('CL' , 8727600, 'Creil'),
	('CLC', 8711677, 'Crécy-la-Chapelle'),
	('CLL', 8738112, 'Clichy Levallois'),
	('CLR', 8754528, 'Choisy le Roi'),
	('CLX', 8775860, 'Châtelet les Halles'),
	('CLY', 8727611, 'Chantilly Gouvieux'),
	('CMA', 8739156, 'Clamart'),
	('CME', 8768245, 'Champagne sur Seine'),
	('CO',  8711630, 'Coulommiers'),
	('COE', 8768100, 'Corbeil Essonnes'),
	('COJ', 8727204, 'Compans'),
	('CPA', 8738186, 'Cormeilles en Parisis'),
	('CPK', 8711587, 'Champbenoist - Poigny'),
	('CPM', 8739305, 'Champ de Mars Tour Eiffel'),
	('CPO', 8727651, 'Champagne sur Oise'),
	('CPW', 8727616, 'Chaponval'),
	('CQQ', 8711664, 'Crouy-sur-Ourcq'),
	('CSG', 8711611, 'Chelles Gournay'),
	('CSH', 8738189, 'Conflans Sainte Honorine'),
	('CTH', 8711658, 'Château Thierry'),
	('CUF', 8775864, 'Cité Universitaire'),
	('CVF', 8738147, 'Chanteloup les Vignes'),
	('CVI', 8739320, 'Chaville Rive Gauche'),
	('CVW', 8775888, 'Courcelles sur Yvette'),
	('CWJ', 8738233, 'Chaville Rive Droite'),
--	('CXA', 8775860, 'Châtelet les Halles RER A'),
	('CYC', 8738249, 'Cergy Saint-Christophe'),
	('CYP', 8738190, 'Cergy Préfecture'),
	('CYQ', 8711673, 'Couilly Saint-Germain Quincy'),
	('CYV', 8727159, 'Crépy-en-Valois'),
	('CYZ', 8711657, 'Chézy sur Marne'),
	('D',   8754552, 'Dourdan'),
	('DA',  8754017, 'Dourdan la Forêt'),
	('DAM', 8727153, 'Dammartin Juilly-Saint-Mard'),
	('DDI', 8768423, 'Dordives'),
	('DEU', 8727634, 'Deuil Montmagny'),
	('DFR', 8775863, 'Denfert Rochereau'),
	('DMO', 8727643, 'Domont'),
	('DRN', 8727140, 'Drancy'),
	('DX',  8739348, 'Dreux'),
	('ECZ', 8727639, 'Écouen Ézanville'),
	('ELW', 8738247, 'L''Étang-la-Ville'),
	('ELY', 8754547, 'Égly'),
	('EM',  8711604, 'Emerainville Pontault Combault'),
	('EN',  8727602, 'Enghien les Bains'),
	('EPL', 8727614, 'Épluches'),
	('EPN', 8739411, 'Épernon'),
	('EPO', 8738676, 'Épone Mézières'),
	('EPV', 8727112, 'Épinay Villetaneuse'),
	('ERA', 8738141, 'Éragny Neuville'),
	('ERM', 8727658, 'Ermont Halte'),
	('ERT', 8727605, 'Ermont Eaubonne'),
	('ESO', 8768160, 'Essonnes-Robinson'),
	('ETP', 8754513, 'Étampes'),
	('ETY', 8754514, 'Étrechy'),
	('EVC', 8768138, 'Évry Courcouronnes'),
	('EVR', 8768136, 'Évry'),
	('EY',  8711632, 'Esbly'),
	('EYO', 8754522, 'Épinay sur Orge'),
	('EYS', 8727114, 'Épinay sur Seine'),
	('FAF', 8739340, 'Fontenay le Fleury'),
	('FFY', 8768424, 'Ferrières Fontenay'),
	('FMN', 8775876, 'Fontaine Michalon'),
	('FMP', 8711627, 'Faremoutiers Pommeuse'),
	('FMY', 8738187, 'La Frette Montigny'),
	('FNR', 8775871, 'Fontenay aux Roses'),
	('FON', 8768221, 'Fontainebleau Avon'),
	('FPB', 8727607, 'Franconville Le Plessis Bouchard'),
	('FPN', 8727665, 'Frépillon'),
	('FPO', 8768242, 'Fontaine le Port'),
	('FSB', 8775812, 'Fontenay-sous-Bois'),
	('GAJ', 8727619, 'Garges Sarcelles'),
	('GAQ', 8739343, 'Garancières la Queue'),
	('GAW', 8775801, 'La Défense Grande Arche'),
	('GBG', 8768135, 'Grand Bourg'),
	('GBI', 8739364, 'Gravigny Balizy'),
	('GCM', 8711626, 'Guérard la Celle sur Morin'),
	('GCR', 8738605, 'Achères Grand Cormier'),
	('GDS', 8727102, 'Paris Nord'),
	('GEN', 8727120, 'Gennevilliers'),
	('GGG', 8768137, 'Grigny Centre'),
	('GGV', 8738156, 'Gargenville'),
	('GIF', 8775887, 'Gif sur Yvette'),
	('GIS', 8738124, 'Gisors'),
	('GMC', 8738225, 'Garches Marnes-la-Coquette'),
	('GN',  8711351, 'Gagny' ),
	('GNX', 8727659, 'Gros Noyer Saint-Prix'),
	('GOU', 8727624, 'Goussainville'),
	('GPA', 8768247, 'La Grande Paroisse'),
	('GRL', 8727636, 'Groslay'),
	('GTL', 8775865, 'Gentilly'),
	('GUW', 8775883, 'Le Guichet'),
	('GYN', 8775858, 'Gare de Lyon RER A'),
	('GZ',  8711601, 'Gretz Armainvilliers' ),
	('GZA', 8739334, 'Gazeran'),
	('HAQ', 8775886, 'La Hacquinière'),
	('HAR', 8738640, 'Houilles Carrières sur Seine'),
	('HER', 8768243, 'Héricy'),
	('HOA', 8739346, 'Houdan'),
	('HRY', 8738188, 'Herblay'),
	('HSL', 8728189, 'Haussman Saint-Lazare' ),
	('IAC', 8711661, 'Isles-Armentières-Congis'),
	('IAP', 8727652, 'L''Isle Adam Parmain'),
	('IBM', 8768162, 'Le Plessis-Chenet'),
	('IGY', 8739356, 'Igny'),
	('INV', 8739303, 'Invalides'),
	('IPO', 8738157, 'Issou Porcheville'),
	('ISP', 8739330, 'Issy Val de Seine'),
	('ISY', 8739307, 'Issy'),
	('IV',  8754530, 'Ivry sur Seine'),
	('JAS', 8739351, 'Jouy en Josas'),
	('JOY', 8739415, 'Jouy'),
	('JUZ', 8738155, 'Juziers'),
	('JVL', 8739306, 'Javel'),
	('JVR', 8775814, 'Joinville-le-Pont'),
	('JY' , 8754524, 'Juvisy'),
	('KOU', 8738220, 'Courbevoie'),
	('KRW', 8768210, 'Montgeron Crosne'),
	('KVE', 8738666, 'Les Clairières de Verneuil'),
	('LAD', 8749210, 'Les Ardoines'),
	('LBJ', 8727117, 'La Barre Ormesson'),
	('LBT', 8727139, 'Le Bourget'),
	('LCB', 8738243, 'La Celle-Saint-Cloud'),
	('LDU', 8738221, 'La Défense'),
	('LEG', 8727214, 'Les Grésillons'),
	('LFA', 8768145, 'La Ferté Alais'),
	('LFC', 8738245, 'Louveciennes'),
	('LFJ', 8711651, 'La Ferté sous Jouarre'),
	('LFM', 8711667, 'La Ferté Milon'),
	('LGK', 8738600, 'La Garenne Colombes'),
	('LGY', 8711631, 'Lagny Thorigny'),
	('LIE', 8733798, 'Saint-Ouen l''Aumône Liesse'),
	('LIM', 8738158, 'Limay'),
	('LIU', 8768215, 'Lieusaint Moissy'),
	('LJA', 8775866, 'Laplace'),
	('LJU', 8739361, 'Longjumeau'),
	('LMU', 8738668, 'Les Mureaux'),
	('LNX', 8727623, 'Les Noues'),
	('LON', 8711613, 'Longueville'), 
	('LOV', 8727625, 'Louvres'),
	('LPE', 8739329, 'Le Perray'),
	('LPN', 8716479, 'La Plaine Stade de France'),
	('LQK', 8738121, 'Liancourt-Saint-Pierre'),
	('LQN', 8775836, 'Lognes'),
	('LSD', 8738109, 'Le Stade'),
	('LSI', 8739328, 'Les Essarts le Roi'),
	('LSW', 8754622, 'Les Saules'),
	('LUZ', 8727657, 'Luzarches'),
	('LVZ', 8775818, 'La Varenne Chennevières'),
	('LWA', 8738630, 'Les Vallées'),
	('LXJ', 8775861, 'Luxembourg'),
	('LYO', 8754516, 'Lardy'),
	('LYQ', 8768240, 'Livry sur Seine'),
	('LYV', 8711380, 'Les Yvris Noisy Le Grand' ),
	('LZO', 8711663, 'Lizy-sur-Ourcq'),
	('LZV', 8775882, 'Lozère'),
	('MAE', 8738172, 'Maule'),
	('MGT', 8728187, 'Magenta'), -- c'était MAG avant, wtf
	('MAL', 8768441, 'Malesherbes'),
	('MAQ', 8711666, 'Mareuil-sur-Ourcq'),
	('MBP', 8727608, 'Montigny Beauchamp'),
	('MBR', 8739347, 'Marchezais Broué'),
	('MDN', 8739310, 'Meudon'),
	('MDS', 8754730, 'Musée d''Orsay'),
	('MEA', 8711610, 'Meaux'),
	('MEL', 8768200, 'Melun'),
	('MFA', 8768115, 'Maisons Alfort Alfortville'),
	('MFL', 8738287, 'Montreuil'),
	('MFY', 8739308, 'Meudon Val Fleury'),
	('MHD', 8738183, 'Meulan Hardricourt'),
	('MJM', 8738171, 'Mareil sur Mauldre'),
	('MJW', 8768140, 'Moulin-Galant'),
	('MKN', 8768410, 'Montigny sur Loing'),
	('MKU', 8738116, 'Montgeroult - Courcelles'),
	('MLB', 8711622, 'Marles en Brie'),
	('MLF', 8738642, 'Maisons Laffitte'),
	('MLM', 8739389, 'Montfort l''Amaury Méré'),
	('MLR', 8738246, 'Marly-le-Roi'),
	('MLV', 8727667, 'Meriel'),
	('MNY', 8768141, 'Mennecy'),
	('MOF', 8711624, 'Mortcerf'),
	('MOR', 8768227, 'Morêt Veneux les Sablons'),
	('MP' , 8775879, 'Massy Palaiseau RER B'),
	('MPJ', 8738281, 'Mareil-Marly'),
	('MPU', 8739357, 'Massy Palaiseau RER C'),
	('MRK', 8738148, 'Maurecourt'),
	('MRT', 8711608, 'Mormant'),
	('MS' , 8768400, 'Montargis'),
	('MSN', 8768148, 'Maisse'),
	('MSO', 8727649, 'Montsoult Maffliers'),
	('MSX', 8754518, 'Marolles en Hurepoix'),
	('MTE', 8738150, 'Mantes la Jolie'),
	('MTN', 8739413, 'Maintenon'),
	('MTQ', 8738159, 'Mantes Station'),
	('MTU', 8768230, 'Montereau'),
	('MVC', 8775499, 'Marne la Vallée Chessy'), -- ou 8711184 ?
	('MVH', 8738237, 'Suresnes Mont Valérien'),
	('MVP', 8775878, 'Massy Verrières RER B'),
	('MVW', 8738328, 'Massy Verrières RER C'),
	('MWO', 8727666, 'Méry sur Oise'), 
	('MXK', 8711628, 'Mouroux'),
	('MY',  8727152, 'Mitry Claye'),
	('MYD', 8711640, 'Montry Condé'),
	('NAA', 8711656, 'Nogent l''Artaud Charly'),
	('NAF', 8775802, 'Nanterre Préfecture'),
	('NAN', 8711609, 'Nangis'),
	('NAU', 8711655, 'Nanteuil Saacy'),
	('NC1', 8775809, 'Saint-Germain-en-Laye'),
	('NC2', 8775808, 'Le Vésinet Le Pecq'),
	('NC3', 8775804, 'Nanterre Ville'),
	('NC4', 8775807, 'Le Vésinet-Centre'),
	('NC5', 8775806, 'Chatou-Croissy'),
	('NC6', 8775805, 'Rueil-Malmaison'),
	('NG',  8754545, 'La Norville Saint-Germain lès Arpajon'),
	('NGM', 8775813, 'Nogent-sur-Marne'),
	('NH',  8727157, 'Nanteuil-le-Haudoin'),
	('NIO', 8739387, 'Noisy-le-Roi'),
	('NLP', 8711374, 'Nogent Le Perreux' ),
	('NO',  8727675, 'Nointel - Mours'),
	('NPT', 8738102, 'Neuilly Porte Maillot'),
	('NSL', 8775835, 'Noisiel'),
	('NSP', 8768412, 'Nemours Saint-Pierre'),
	('NSY', 8711321, 'Noisy Le Sec' ),
	('NTN', 8775810, 'Nation'),
	('NUE', 8733448, 'Neuville Université'),
	('NUN', 8738631, 'Nanterre Université'),
	('NYC', 8775834, 'Noisy Champs'),
	('NYG', 8775833, 'Noisy le Grand Mont d''Est'),
	('NYP', 8775831, 'Neuilly Plaisance'),
	('NZL', 8738173, 'Nezel Aulnay'),
	('OBP', 8768134, 'Orangis Bois de l''Épine'),
	('OGB', 8739344, 'Orgerus Behoust'),
	('ORM', 8727158, 'Ormoy-Villers'),
	('ORS', 8775884, 'Orsay Ville'),
	('ORY', 8727627, 'Orry la Ville Coye'),
	('OSN', 8738114, 'Osny'),
	('OY',  8754620, 'Orly Ville'),
	('OZF', 8711602, 'Ozoir la Ferrière' ),
	('PLY', 8768600, 'Paris Gare de Lyon'), 
	('PAA', 8768603, 'Paris Gare de Lyon'), -- et pas 8768600
	('PAN', 8711320, 'Pantin' ),
	('PAW', 8775881, 'Palaiseau Villebon'),
	('PAX', 8775880, 'Palaiseau'),
	('PCX', 8775873, 'Parc de Sceaux'),
	('PDM', 8739304, 'Pont de l''Alma'),
	('PE',  8711300, 'Paris Est'),
	('PEB', 8727646, 'Persan Beaumont'),
	('PEX', 8727148, 'Parc des Expositions'),
	('PG',  8739342, 'Plaisir Grignon'),
	('PIE', 8739362, 'Plaisir les Clayes'),
	('PJ',  8739350, 'Petit Jouy les Loges'),
	('PKY', 8711127, 'Porte de Clichy'),
	('PLB', 8727155, 'Plessis-Belleville'),
	('PMP', 8739100, 'Paris Montparnasse'),
	('POA', 8739316, 'Porchefontaine'),
	('POP', 8768252, 'Ponthierry-Pringy'),
	('PPD', 8760880, 'Créteil Pompadour'), 
	('PPT', 8727615, 'Pont-Petit'),
	('PRF', 8727116, 'Pierrefitte Stains'),
	('PRO', 8711616, 'Provins'),
	('PRQ', 8727650, 'Presles - Courcelles'),
	('PRR', 8738101, 'Pereire Levallois'),
	('PRU', 8754619, 'Pont de Rungis Aéroport d''Orly'),
	('PRY', 8727609, 'Pierrelaye'),
	('PSE', 8727613, 'Pontoise'),
	('PSL', 8738400, 'Paris Saint-Lazare'),
	('PSY', 8738657, 'Poissy'),
	('PTC', 8738111, 'Pont Cardinet'),
	('PTX', 8738238, 'Puteaux'),
	('PV',  8739365, 'Petit Vaux'),
	('PWR', 8775862, 'Port Royal'),
	('PXO', 8775816, 'Le Parc de Saint-Maur'),
	('PYO', 8727641, 'Précy-sur-Oise'),
	('PZB', 8754702, 'Paris Austerlitz'), -- pas 8754700
	('RBI', 8711369, 'Rosny Bois Perrier' ),
	('RBT', 8739331, 'Rambouillet'),
	('RF',  8754629, 'Rungis la Fraternelle'),
	('RIS', 8768133, 'Ris Orangis'),
	('RNS', 8775872, 'Robinson'),
	('ROB', 8711603, 'Roissy en Brie' ),
	('RSB', 8711370, 'Rosny sous Bois' ),
	('RSY', 8727146, 'Aéroport Charles de Gaulle 1'),
	('RVM', 8711347, 'Le Raincy Villemomble' ),
	('RYR', 8700147, 'Aéroport Charles de Gaulle 2 TGV'),
	('SAO', 8754523, 'Savigny sur Orge'),
	('SCD', 8738235, 'Saint-Cloud'),
	('SCR', 8739322, 'Saint-Cyr'),
	('SCW', 8754550, 'Saint-Chéron'),
	('SDE', 8727101, 'Saint-Denis'),
	('SEV', 8727142, 'Sevran Livry'),
	('SF' , 8768229, 'Saint-Mammès'),
	('SFD', 8716478, 'Stade de France Saint-Denis'),
	('SGM', 8738280, 'Saint-Germain-en-Laye Grande Ceinture'),
	('SGT', 8727617, 'Saint-Gratien'),
	('SHL', 8754731, 'Saint-Michel Notre Dame RER C'), 
	('SHO', 8754520, 'Saint-Michel sur Orge'),
	('SKX', 8775870, 'Sceaux'),
	('SLF', 8727660, 'Saint-Leu la Forêt'),
	('SLL', 8727638, 'Sarcelles Saint-Brice'),
	('SLT', 8727640, 'Saint-Leu d''Esserent'),
	('SME', 8754535, 'Saint-Martin d''Étampes'),
	('SNB', 8738248, 'Saint-Nom-la-Bretèche - Forêt de Marly'),
	('SNM', 8775889, 'Saint-Rémy lès Chevreuse'),
	('SNN', 8727618, 'Sannois'),
	('SOA', 8727610, 'Saint-Ouen l''Aumône'),
	('SOS', 8727124, 'Saint-Ouen'),
	('SPI', 8739414, 'Saint-Piat'),
	('SPP', 8768421, 'Souppes Château Landon'),
	('SQY', 8739384, 'Saint-Quentin en Yvelines'),
	('SUR', 8727626, 'Survilliers Fosses'),
	('SVL', 8738641, 'Sartrouville'),
	('SVR', 8739312, 'Sèvres Rive Gauche'),
	('SWY', 8727203, 'Seugy'),
	('SXE', 8754551, 'Sermaise'),
	('SXG', 8754521, 'Sainte Geneviève des Bois'),
	('TAE', 8739345, 'Tacoignières Richebourg'),
	('TLP', 8711649, 'Trilport'),
	('TMR', 8768225, 'Thomery'),
	('TNT', 8727205, 'Thieux - Nantouillet'),
	('TOC', 8775837, 'Torcy'),
	('TOU', 8711621, 'Tournan'),
	('TPA', 8738182, 'Thun le Paradis'),
	('TRH', 8738123, 'Trie-Château'),
	('TSS', 8738180, 'Triel sur Seine'),
	('TVO', 8739383, 'Trappes'),
	('TVY', 8727663, 'Taverny'),
	('US',  8738117, 'Us'),
	('VAI', 8711629, 'Vaires Torcy'),
	('VBB', 8711674, 'Villiers-Montbarbin'),
	('VBO', 8739353, 'Vauboyen'),
	('VBV', 8768161, 'Villabé'),
	('VC',  8739300, 'Versailles Chantiers'),
	('VCN', 8738226, 'Vaucresson'),
	('VCX', 8727662, 'Vaucelles'),
	('VD' , 8768124, 'Le Vert de Maisons'),
	('VDA', 8738179, 'Val d''Argenteuil'),
	('VDE', 8773006, 'Val d''Europe'),
	('VDF', 8711371, 'Val de Fontenay RER E'),
	('VDO', 8738236, 'Le Val d''Or'),
	('VDV', 8738234, 'Sèvres Ville d''Avray'),
	('VEH', 8739388, 'Villiers Neauphle Pontchartrain'),
	('VEP', 8739341, 'Villepreux les Clayes'),
	('VET', 8738665, 'Vernouillet Verneuil'),
	('VFD', 8738288, 'Viroflay Rive Droite'),
	('VFG', 8739321, 'Viroflay Rive Gauche'),
	('VFR', 8775830, 'Val de Fontenay RER A'),
	('VGL', 8727143, 'Vert Galant'),
	('VGS', 8768130, 'Vigneux sur Seine'),
	('VIB', 8727622, 'Villiers le Bel Gonesse Arnouville'),
	('VII', 8727151, 'Villeparisis Mitry Le Neuf'),
	('VMD', 8727653, 'Valmondois'),
	('VMK', 8739153, 'Vanves Malakoff'),
	('VMS', 8727656, 'Viarmes'),
	('VNC', 8775811, 'Vincennes'),
	('VNL', 8711607, 'Verneuil l''Étang'),
	('VOM', 8768250, 'Vosves'),
	('VP' , 8768185, 'Villeneuve Prairie'),
	('VPN', 8727145, 'Villepinte'),
	('VRD', 8738286, 'Versailles Rive Droite'),
	('VRG', 8739315, 'Versailles Rive Gauche Château'),
	('VRI', 8754527, 'Villeneuve le Roi'),
	('VSG', 8768182, 'Villeneuve Saint-Georges'),
	('VSM', 8711379, 'Villiers sur Marne Plessis Trévise'),
	('VSS', 8768246, 'Vernou sur Seine'),
	('VSW', 8738664, 'Villennes sur Seine'),
	('VTV', 8768180, 'Villeneuve Triage'),
	('VUN', 8768244, 'Vulaines sur Seine Samoreau'),
	('VW',  8727202, 'Villaines'),
	('VWC', 8768131, 'Viry Châtillon'),
	('VWT', 8738120, 'La Villetertre'),
	('VXS', 8738181, 'Vaux sur Seine'),
	('VY',  8754529, 'Vitry sur Seine'),
	('VYL', 8739325, 'La Verrière'),
	('WEE', 8768217, 'Le Mée'),
	('XBY', 8775874, 'La Croix de Berny'),
	('XCS', 8711617, 'Saint-Colombe - Septveilles'),
	('XFA', 8768254, 'Saint-Fargeau'),
	('XMC', 8775815, 'Saint-Maur-Créteil'),
	('XND', 8778543, 'Saint-Michel Notre Dame RER B'),
	('XOA', 8738142, 'Saint-Ouen l''Aumône Quartier de l''Église'),
	('XPY', 8738118, 'Santeuil - Le Perchay'),
	('YES', 8768211, 'Yerres'),
	('ZTN', 8768218, 'Savigny le Temple Nandy'),
	('ZUB', 8775819, 'Sucy Bonneuil');


INSERT INTO gares (code, uic, name, is_transilien) VALUES
	('ERU', 8753413, 'Ermont Eaubonne', 0), -- hack pour certains trains de AEE qui marchent pas
	('PAZ', 8754700, 'Paris Austerlitz', 0),   -- grandes lignes
 	('VTP', 8739417, 'La Villette Saint-Prest', 0),  -- TODO: verifier si cette gare est interrogeable
 	('PVA', 8739110, 'Paris Montparnasse', 0), -- Paris Vaugirard
	('PNB', 8727103, 'Paris Nord', 0);

-- INSERT INTO gares (code, name, is_transilien) VALUES
-- 	('AGR', 'Aingeray', 0),
-- 	('AGV', 'Angerville', 0),
-- 	('API', 'Anizy-Pinon', 0),
-- 	('AR',  'Argentan', 0),
-- 	('AS',  'Amiens', 0),
-- 	('ASN', 'Ailly-sur-Noye', 0),
-- 	('ATY', 'Artenay', 0),
-- 	('AUN', 'Auneau', 0),
-- 	('AVY', 'Avrechy', 0),
-- 	('BAX', 'Boisseaux', 0),
-- 	('BAY', 'Bayeux', 0),
-- 	('BBI', 'Bornel-Belle-Église', 0),
-- 	('BEB', 'Breteuil-Embranchement', 0),
-- 	('BLG', 'Brive la Gaillarde', 0),
-- 	('BLR', 'Beaumont-le-Roger', 0),
-- 	('BNR', 'Bonnières', 0),
-- 	('BO',  'Bonneval', 0),
-- 	('BUE', 'Bueil', 0),
-- 	('BVS', 'Beauvais', 0),
-- 	('BVU', 'La Bonneville-sur-Iton', 0),
-- 	('BZN', 'Briouze', 0),
-- 	('CAR', 'Carentan', 0),
-- 	('CBU', 'Cherbourg', 0),
-- 	('CCH', 'Conches', 0),
-- 	('CCT', 'Cercottes', 0),
-- 	('CDO', 'Clermont-de-l''Oise', 0),
-- 	('CFO', 'Conflans-Fin-d''Oise', 0), -- redondant avec CFD
-- 	('CGK', 'Château-Gaillard', 0),
-- 	('CN',  'Caen', 0),
-- 	('CNY', 'Chauny', 0),
-- 	('COB', 'Connerré - Beillé', 0),
-- 	('COU', 'Avignon TGV', 0),
-- 	('CPE', 'Compiègne', 0),
-- 	('CSY', 'Champigny sur Yonne', 0),
-- 	('CUN', 'Châteaudun', 0),
-- 	('CVB', 'Courville sur Eure', 0),
-- 	('CVE', 'Chevrières', 0),
-- 	('CVK', 'Chambly', 0),
-- 	('CVY', 'Chevilly', 0),
-- 	('DEJ', 'Laboissière-le-Déluge', 0),
-- 	('ESC', 'Esches', 0),
-- 	('ERE', 'Ermont Eaubonne', 0),      -- redondant avec ERT
-- 	('EVX', 'Évreux-Normandie', 0),
-- 	('FL',  'Flers', 0),
-- 	('GAA', 'Gaillon Aubevoye', 0),
-- 	('GAI', 'Gaillac', 0),
-- 	('GRV', 'Granville', 0),
-- 	('GU',  'Guillerval', 0),
-- 	('JAX', 'Jaux', 0),
-- 	('JOI', 'Joigny', 0),
-- 	('LAB', 'Les Aubrais-Orléans', 0),
-- 	('LAE', 'L''Aigle', 0),
-- 	('LAI', 'Laigneville', 0),
-- 	('LAO', 'Laon', 0),
-- 	('LAR', 'Laroche Mignennes', 0),
-- 	('LEW', 'Lille Europe', 0),
-- 	('LFB', 'La Ferté Bernard', 0),
-- 	('LIA', 'Liancourt-Rantigny', 0),
-- 	('LJP', 'Longpont', 0),
-- 	('LLP', 'La Loupe', 0),
-- 	('LLT', 'Le-Merlerault', 0),
-- 	('LM',  'Le Mans', 0),
-- 	('LSN', 'Lison', 0),
-- 	('LUA', 'Longueau', 0),
-- 	('LUE', 'Longueuil-Sainte-Marie', 0),
-- 	('LXS', 'Le Meux La Croix-Saint-Ouen', 0),
-- 	('LYD', 'Lyon Part-Dieu', 0),
-- 	('MRU', 'Méru', 0),
-- 	('MSC', 'Marseille Saint-Charles', 0),
-- 	('MW',  'Monnerville', 0),
-- 	('NCO', 'Nonancourt', 0),
-- 	('NGR', 'Nogent le Rotrou', 0),
-- 	('NOY', 'Noyon', 0),
-- 	('OI',  'Oissel', 0),
-- 	('ORL', 'Orléans', 0),
-- 	('PAZ', 'Paris Austerlitz', 0),
-- 	('PNO', 'Paris Nord', 0), -- grandes lignes, redondant 
-- 	('PUY', 'Pont-sur-Yonne', 0),
-- 	('PXE', 'Pont Sainte-Maxence', 0),
-- 	('RIA', 'Rieux Angicourt', 0),
-- 	('RN',  'Rouen Rive Droite', 0),
-- 	('RSS', 'Rosny sur Seine', 0),
-- 	('RYP', 'Romilly-la-Puthenaye', 0),
-- 	('SDN', 'Surdon', 0),
-- 	('SES', 'Sens', 0),
-- 	('SGG', 'Sainte-Gauburge', 0),
-- 	('SJS', 'Saint-Just-en-Chaussée', 0),
-- 	('SJX', 'Saint-Julien-du-Sault', 0),
-- 	('SOI', 'Soissons', 0),
-- 	('SQ',  'Saint-Quentin', 0),
-- 	('SUP', 'Saint-Sulpice-Auteuil', 0),
-- 	('SY',  'Serquigny', 0),
-- 	('TGR', 'Tergnier', 0),
-- 	('TY',  'Toury', 0),
-- 	('VAL', 'Valognes', 0),
-- 	('VCT', 'Villers-Cotterets', 0),
-- 	('VDR', 'Val-de-Reuil', 0),
-- 	('VDS', 'Villedieu-les-Poêles', 0),
-- 	('VEA', 'Verneuil sur Avre', 0),
-- 	('VIR', 'Vire', 0),
-- 	('VN',  'Vernon', 0),
-- 	('VO',  'Voves', 0),
-- 	('VPL', 'Villers-Saint-Paul', 0),
-- 	('VSX', 'Villeneuve Point X', 0),
-- 	('VVG', 'Villeneuve la Guyard', 0),
-- 	('VXN', 'Valence TGV', 0),
-- 	('VYE', 'Villeneuve sur Yonne', 0);

CREATE UNIQUE INDEX index_tr3a ON gares (code);



INSERT INTO gares_lines VALUES 
	(8700147, 'B'),		-- AEROPORT CHARLES DE GAULLE 2 TGV - Roissy
	(8711127, 'C'),		-- PORTE DE CLICHY
	(8711300, 'P'),		-- PARIS EST (GARE DE L'EST)
	(8711320, 'E'),		-- PANTIN
	(8711321, 'E'),		-- NOISY LE SEC
	(8711340, 'E'),		-- BONDY
	(8711340, 'T4'),	-- BONDY
	(8711347, 'E'),		-- LE RAINCY VILLEMONBLE MONTFERMEIL
	(8711351, 'E'),		-- GAGNY
	(8711352, 'E'),		-- LE CHENAY GAGNY
	(8711369, 'E'),		-- ROSNY BOIS PERRIER
	(8711370, 'E'),		-- ROSNY SOUS BOIS
--	(8711371, 'A'),		-- VAL DE FONTENAY
	(8711371, 'E'),		-- VAL DE FONTENAY
	(8711374, 'E'),		-- NOGENT LE PERREUX
	(8711377, 'E'),		-- LES BOULLEREAUX CHAMPIGNY
	(8711379, 'E'),		-- VILLIERS SUR MARNE PLESSIS TREVISE
	(8711380, 'E'),		-- LES YVRIS - NOISY LE GRAND
	(8711384, 'T4'),	-- LES COQUETIERS (T4)
	(8711385, 'T4'),	-- LES PAVILLONS SOUS BOIS (T4)
	(8711386, 'T4'),	-- GARGAN (T4)
	(8711387, 'T4'),	-- ALLEE DE LA TOUR RENDEZ VOUS (T4)
	(8711388, 'T4'),	-- L'ABBAYE (T4)
	(8711389, 'T4'),	-- FREINVILLE SEVRAN (T4)
	(8711587, 'P'),		-- CHAMPBENOIST POIGNY
	(8711601, 'E'),		-- GRETZ ARMAINVILLIERS
	(8711601, 'P'),		-- GRETZ ARMAINVILLIERS
	(8711602, 'E'),		-- OZOIR LA FERRIERE
	(8711603, 'E'),		-- ROISSY EN BRIE
	(8711604, 'E'),		-- EMERAINVILLE - PONTAULT COMBAULT
	(8711607, 'P'),		-- VERNEUIL L'ETANG
	(8711608, 'P'),		-- MORMANT
	(8711609, 'P'),		-- NANGIS
	(8711610, 'P'),		-- MEAUX
	(8711611, 'E'),		-- CHELLES GOURNAY
	(8711611, 'P'),		-- CHELLES GOURNAY
	(8711613, 'P'),		-- LONGUEVILLE
	(8711616, 'P'),		-- PROVINS
	(8711617, 'P'),		-- SAINTE-COLOMBE SEPTVEILLES
	(8711621, 'E'),		-- TOURNAN
	(8711621, 'P'),		-- TOURNAN
	(8711622, 'P'),		-- MARLES EN BRIE
	(8711624, 'P'),		-- MORTCERF
	(8711626, 'P'),		-- GUERARD LA CELLE SUR MORIN
	(8711627, 'P'),		-- FAREMOUTIERS POMMEUSE
	(8711628, 'P'),		-- MOUROUX
	(8711629, 'P'),		-- VAIRES TORCY
	(8711630, 'P'),		-- COULOMMIERS
	(8711631, 'P'),		-- LAGNY THORIGNY
	(8711632, 'P'),		-- ESBLY
	(8711634, 'P'),		-- CHAILLY BOISSY LE CHATEL
	(8711635, 'P'),		-- CHAUFFRY
	(8711636, 'P'),		-- SAINT-SIMEON
	(8711637, 'P'),		-- SAINT-REMY LA VANNE
	(8711640, 'P'),		-- MONTRY CONDE
	(8711649, 'P'),		-- TRILPORT
	(8711650, 'P'),		-- CHANGIS SAINT-JEAN
	(8711651, 'P'),		-- LA FERTE SOUS JOUARRE
	(8711655, 'P'),		-- NANTEUIL SAACY
	(8711656, 'P'),		-- NOGENT L'ARTAUD CHARLY
	(8711657, 'P'),		-- CHEZY SUR MARNE
	(8711658, 'P'),		-- CHATEAU THIERRY
	(8711661, 'P'),		-- ISLES ARMENTIERES CONGIS
	(8711663, 'P'),		-- LIZY SUR OURCQ
	(8711664, 'P'),		-- CROUY SUR OURCQ
	(8711666, 'P'),		-- MAREUIL SUR OURCQ
	(8711667, 'P'),		-- LA FERTE MILON
	(8711673, 'P'),		-- COUILLY SAINT-GERMAIN QUINCY
	(8711674, 'P'),		-- VILLIERS MONTBARBIN
	(8711677, 'P'),		-- CRECY LA CHAPELLE
	(8716478, 'D'),		-- STADE DE FRANCE SAINT-DENIS
	(8716479, 'B'),		-- LA PLAINE STADE DE FRANCE - Saint-Denis Aubervilliers
	(8727101, 'D'),		-- SAINT-DENIS
	(8727101, 'H'),		-- SAINT-DENIS
	(8727102, 'B'),		-- GARE DU NORD RER
	(8727102, 'D'),		-- GARE DU NORD RER
	(8727103, 'B'),		-- PARIS NORD (GARE DU NORD)
	(8727103, 'D'),		-- PARIS NORD (GARE DU NORD)
	(8727103, 'H'),		-- PARIS NORD (GARE DU NORD)
	(8727103, 'K'),		-- PARIS NORD (GARE DU NORD)
	(8727112, 'H'),		-- EPINAY VILLETANEUSE
	(8727114, 'C'),		-- EPINAY SUR SEINE
	(8727116, 'D'),		-- PIERREFITTE STAINS
	(8727117, 'H'),		-- LA BARRE ORMESSON
	(8727120, 'C'),		-- GENNEVILLIERS
	(8727124, 'C'),		-- SAINT-OUEN
	(8727130, 'B'),		-- LA COURNEUVE AUBERVILLIERS
	(8727139, 'B'),		-- LE BOURGET
	(8727140, 'B'),		-- DRANCY
	(8727141, 'B'),		-- AULNAY SOUS BOIS
	(8727141, 'K'),		-- AULNAY SOUS BOIS
	(8727141, 'T4'),	-- AULNAY SOUS BOIS
	(8727142, 'B'),		-- SEVRAN LIVRY
	(8727143, 'B'),		-- VERT GALANT
	(8727144, 'B'),		-- SEVRAN BEAUDOTTES
	(8727145, 'B'),		-- VILLEPINTE
	(8727146, 'B'),		-- AEROPORT CHARLES DE GAULLE  1 - Roissy
	(8727147, 'B'),		-- LE BLANC MESNIL
	(8727148, 'B'),		-- PARC DES EXPOSITIONS
	(8727151, 'B'),		-- VILLEPARISIS MITRY LE NEUF
	(8727152, 'B'),		-- MITRY CLAYE
	(8727152, 'K'),		-- MITRY CLAYE
	(8727153, 'K'),		-- DAMMARTIN JUILLY SAINT-MARD
	(8727155, 'K'),		-- LE PLESSIS BELLEVILLE
	(8727157, 'K'),		-- NANTEUIL LE HAUDOIN
	(8727158, 'K'),		-- ORMOY VILLERS
	(8727159, 'K'),		-- CREPY EN VALOIS
	(8727202, 'H'),		-- VILLAINES
	(8727203, 'H'),		-- SEUGY
	(8727204, 'K'),		-- COMPANS
	(8727205, 'K'),		-- THIEUX NANTOUILLET
	(8727214, 'C'),		-- LES GRESILLONS
	(8727600, 'D'),		-- CREIL
	(8727600, 'H'),		-- CREIL
	(8727602, 'H'),		-- ENGHIEN LES BAINS
	(8727603, 'H'),		-- CHAMP DE COURSES D'ENGHIEN
	(8727605, 'C'),		-- ERMONT EAUBONNE
	(8727605, 'H'),		-- ERMONT EAUBONNE
	(8727605, 'J'),		-- ERMONT EAUBONNE
	(8727606, 'C'),		-- CERNAY
	(8727606, 'H'),		-- CERNAY
	(8727607, 'C'),		-- FRANCONVILLE LE PLESSIS BOUCHARD
	(8727607, 'H'),		-- FRANCONVILLE LE PLESSIS BOUCHARD
	(8727608, 'C'),		-- MONTIGNY BEAUCHAMP
	(8727608, 'H'),		-- MONTIGNY BEAUCHAMP
	(8727609, 'C'),		-- PIERRELAYE
	(8727609, 'H'),		-- PIERRELAYE
	(8727610, 'C'),		-- SAINT-OUEN L'AUMONE
	(8727610, 'H'),		-- SAINT-OUEN L'AUMONE
	(8727611, 'D'),		-- CHANTILLY GOUVIEUX
	(8727613, 'C'),		-- PONTOISE
	(8727613, 'H'),		-- PONTOISE
	(8727613, 'J'),		-- PONTOISE
	(8727614, 'H'),		-- EPLUCHES
	(8727615, 'H'),		-- PONT PETIT
	(8727616, 'H'),		-- CHAPONVAL
	(8727617, 'C'),		-- SAINT-GRATIEN
	(8727618, 'J'),		-- SANNOIS
	(8727619, 'D'),		-- GARGES SARCELLES
	(8727622, 'D'),		-- VILLIERS LE BEL GONESSE ARNOUVILLE
	(8727623, 'D'),		-- LES NOUES
	(8727624, 'D'),		-- GOUSSAINVILLE
	(8727625, 'D'),		-- LOUVRES
	(8727626, 'D'),		-- SURVILLIERS FOSSES
	(8727627, 'D'),		-- ORRY LA VILLE COYE LA FORET
	(8727628, 'D'),		-- LA BORNE BLANCHE
	(8727634, 'H'),		-- DEUIL MONTMAGNY
	(8727636, 'H'),		-- GROSLAY
	(8727638, 'H'),		-- SARCELLES SAINT-BRICE
	(8727639, 'H'),		-- ECOUEN EZANVILLE
	(8727640, 'H'),		-- SAINT-LEU D ESSERENT
	(8727641, 'H'),		-- PRECY SUR OISE
	(8727643, 'H'),		-- DOMONT
	(8727644, 'H'),		-- BORAN SUR OISE
	(8727645, 'H'),		-- BRUYERES SUR OISE
	(8727646, 'H'),		-- PERSAN BEAUMONT
	(8727648, 'H'),		-- BOUFFEMONT MOISSELLES
	(8727649, 'H'),		-- MONTSOULT MAFFLIERS
	(8727650, 'H'),		-- PRESLES COURCELLES
	(8727651, 'H'),		-- CHAMPAGNE SUR OISE
	(8727652, 'H'),		-- L'ISLE ADAM PARMAIN
	(8727653, 'H'),		-- VALMONDOIS
	(8727654, 'H'),		-- AUVERS SUR OISE
	(8727655, 'H'),		-- BELLOY SAINT-MARTIN
	(8727656, 'H'),		-- VIARMES
	(8727657, 'H'),		-- LUZARCHES
	(8727658, 'H'),		-- ERMONT HALTE
	(8727659, 'H'),		-- GROS NOYER SAINT-PRIX
	(8727660, 'H'),		-- SAINT-LEU LA FORET
	(8727662, 'H'),		-- VAUCELLES
	(8727663, 'H'),		-- TAVERNY
	(8727664, 'H'),		-- BESSANCOURT
	(8727665, 'H'),		-- FREPILLON
	(8727666, 'H'),		-- MERY SUR OISE
	(8727667, 'H'),		-- MERIEL
	(8727675, 'H'),		-- NOINTEL MOURS
	(8728187, 'E'),		-- MAGENTA
	(8728189, 'E'),		-- HAUSSMANN SAINT-LAZARE
	(8732832, 'C'),		-- BIBLIOTHEQUE FRANCOIS MITTERRAND
	(8733293, 'C'),		-- MONDESIR
	(8733294, 'C'),		-- MONNERVILLE CENTRE
	(8733295, 'C'),		-- ROUTE DE MONNERVILLE
	(8733296, 'C'),		-- CREDIT AGRICOLE (DOMMERVILLE)
	(8733297, 'C'),		-- SALLE DES FETES
	(8733448, 'A'),		-- NEUVILLE UNIVERSITE
	(8733448, 'L'),		-- NEUVILLE UNIVERSITE
	(8733798, 'C'),		-- SAINT-OUEN L'AUMONE LIESSE
	(8733798, 'H'),		-- SAINT-OUEN L'AUMONE LIESSE
	(8736692, 'L'),		-- SAINT-GERMAIN EN LAYE BEL AIR FOURQUEUX
	(8738101, 'C'),		-- PEREIRE LEVALLOIS
	(8738102, 'C'),		-- NEUILLY PORTE MAILLOT - Palais des Congrès
	(8738103, 'C'),		-- AVENUE FOCH
	(8738104, 'C'),		-- AVENUE HENRI MARTIN
	(8738107, 'J'),		-- BOIS COLOMBES
	(8738108, 'J'),		-- COLOMBES
	(8738109, 'J'),		-- LE STADE
	(8738111, 'L'),		-- PONT CARDINET
	(8738112, 'L'),		-- CLICHY LEVALLOIS
	(8738113, 'J'),		-- ASNIERES SUR SEINE
	(8738113, 'L'),		-- ASNIERES SUR SEINE
	(8738114, 'J'),		-- OSNY
	(8738115, 'J'),		-- BOISSY L'AILLERIE
	(8738116, 'J'),		-- MONTGEROULT COURCELLES
	(8738117, 'J'),		-- US
	(8738118, 'J'),		-- SANTEUIL LE PERCHAY
	(8738119, 'J'),		-- CHARS
	(8738120, 'J'),		-- LA VILLETERTRE
	(8738121, 'J'),		-- LIANCOURT SAINT PIERRE
	(8738122, 'J'),		-- CHAUMONT EN VEXIN
	(8738123, 'J'),		-- TRIE CHATEAU
	(8738124, 'J'),		-- GISORS
	(8738141, 'J'),		-- ERAGNY NEUVILLE
	(8738142, 'J'),		-- SAINT-OUEN L'AUMONE QUARTIER DE L'EGLISE
	(8738145, 'A'),		-- CONFLANS FIN D'OISE
	(8738145, 'J'),		-- CONFLANS FIN D'OISE
	(8738145, 'L'),		-- CONFLANS FIN D'OISE
	(8738147, 'J'),		-- CHANTELOUP LES VIGNES
	(8738148, 'J'),		-- MAURECOURT
	(8738149, 'J'),		-- ANDRESY
	(8738150, 'J'),		-- MANTES LA JOLIE
	(8738150, 'N'),		-- MANTES LA JOLIE
	(8738155, 'J'),		-- JUZIERS
	(8738156, 'J'),		-- GARGENVILLE
	(8738157, 'J'),		-- ISSOU PORCHEVILLE
	(8738158, 'J'),		-- LIMAY
	(8738159, 'J'),		-- MANTES STATION
	(8738165, 'A'),		-- ACHERES VILLE
	(8738165, 'L'),		-- ACHERES VILLE
	(8738171, 'N'),		-- MAREIL SUR MAULDRE
	(8738172, 'N'),		-- MAULE
	(8738173, 'N'),		-- NEZEL AULNAY
	(8738179, 'J'),		-- VAL D'ARGENTEUIL
	(8738180, 'J'),		-- TRIEL SUR SEINE
	(8738181, 'J'),		-- VAUX SUR SEINE
	(8738182, 'J'),		-- THUN LE PARADIS
	(8738183, 'J'),		-- MEULAN HARDRICOURT
	(8738184, 'J'),		-- ARGENTEUIL
	(8738186, 'J'),		-- CORMEILLES EN PARISIS
	(8738187, 'J'),		-- LA FRETTE MONTIGNY
	(8738188, 'J'),		-- HERBLAY
	(8738189, 'J'),		-- CONFLANS SAINTE-HONORINE
	(8738190, 'A'),		-- CERGY PREFECTURE
	(8738190, 'L'),		-- CERGY PREFECTURE
	(8738200, 'L'),		-- BECON LES BRUYERES
	(8738220, 'L'),		-- COURBEVOIE
	(8738221, 'A'),		-- LA DEFENSE
	(8738221, 'L'),		-- LA DEFENSE
	(8738221, 'U'),		-- LA DEFENSE
	(8738225, 'L'),		-- GARCHES MARNES LA COQUETTE
	(8738226, 'L'),		-- VAUCRESSON
	(8738233, 'L'),		-- CHAVILLE RIVE DROITE
	(8738234, 'L'),		-- SEVRES VILLE D'AVRAY
	(8738235, 'L'),		-- SAINT-CLOUD
	(8738235, 'U'),		-- SAINT-CLOUD
	(8738236, 'L'),		-- LE VAL D'OR
	(8738236, 'U'),		-- LE VAL D'OR
	(8738237, 'L'),		-- SURESNES MONT VALERIEN
	(8738237, 'U'),		-- SURESNES MONT VALERIEN
	(8738238, 'L'),		-- PUTEAUX
	(8738238, 'U'),		-- PUTEAUX
	(8738243, 'L'),		-- LA CELLE SAINT-CLOUD
	(8738244, 'L'),		-- BOUGIVAL
	(8738245, 'L'),		-- LOUVECIENNES
	(8738246, 'L'),		-- MARLY LE ROI
	(8738247, 'L'),		-- L'ETANG LA VILLE
	(8738248, 'L'),		-- SAINT-NOM LA BRETECHE FORET DE MARLY
	(8738249, 'A'),		-- CERGY SAINT-CHRISTOPHE
	(8738249, 'L'),		-- CERGY SAINT-CHRISTOPHE
	(8738265, 'A'),		-- CERGY LE HAUT
	(8738265, 'L'),		-- CERGY LE HAUT
	(8738280, 'L'),		-- SAINT-GERMAIN EN LAYE GRANDE CEINTURE
	(8738281, 'L'),		-- MAREIL MARLY
	(8738286, 'L'),		-- VERSAILLES RIVE DROITE
	(8738287, 'L'),		-- MONTREUIL
	(8738288, 'L'),		-- VIROFLAY RIVE DROITE
--	(8738328, 'B'),		-- MASSY VERRIERES
	(8738328, 'C'),		-- MASSY VERRIERES
	(8738400, 'J'),		-- PARIS SAINT-LAZARE (GARE SAINT-LAZARE)
	(8738400, 'L'),		-- PARIS SAINT-LAZARE (GARE SAINT-LAZARE)
	(8738600, 'L'),		-- LA GARENNE COLOMBES
	(8738605, 'A'),		-- ACHERES GRAND CORMIER
	(8738605, 'J'),		-- ACHERES GRAND CORMIER
	(8738630, 'L'),		-- LES VALLEES
--	(8775802, 'A'),		-- NANTERRE PREFECTURE (mauvais code UIC et doublon !)
	(8738631, 'A'),		-- NANTERRE UNIVERSITE
	(8738631, 'L'),		-- NANTERRE UNIVERSITE
	(8738640, 'A'),		-- HOUILLES CARRIERES SUR SEINE
	(8738640, 'J'),		-- HOUILLES CARRIERES SUR SEINE
	(8738640, 'L'),		-- HOUILLES CARRIERES SUR SEINE
	(8738641, 'A'),		-- SARTROUVILLE
	(8738641, 'L'),		-- SARTROUVILLE
	(8738642, 'A'),		-- MAISONS LAFFITTE
	(8738642, 'L'),		-- MAISONS LAFFITTE
	(8738657, 'A'),		-- POISSY
	(8738657, 'J'),		-- POISSY
	(8738664, 'J'),		-- VILLENNES SUR SEINE
	(8738665, 'J'),		-- VERNOUILLET VERNEUIL
	(8738666, 'J'),		-- LES CLAIRIERES DE VERNEUIL
	(8738668, 'J'),		-- LES MUREAUX
	(8738673, 'J'),		-- AUBERGENVILLE ELISABETHVILLE
	(8738676, 'J'),		-- EPONE MEZIERES
	(8738676, 'N'),		-- EPONE MEZIERES
	(8739100, 'N'),		-- PARIS MONTPARNASSE (GARE MONTPARNASSE)
	(8739153, 'N'),		-- VANVES MALAKOFF
	(8739156, 'N'),		-- CLAMART
	(8739300, 'C'),		-- VERSAILLES CHANTIERS
	(8739300, 'N'),		-- VERSAILLES CHANTIERS
	(8739300, 'U'),		-- VERSAILLES CHANTIERS
	(8739303, 'C'),		-- INVALIDES
	(8739304, 'C'),		-- PONT DE L'ALMA
	(8739305, 'C'),		-- CHAMP DE MARS TOUR EIFFEL
	(8739306, 'C'),		-- JAVEL
	(8739307, 'C'),		-- ISSY
	(8739308, 'C'),		-- MEUDON VAL FLEURY
	(8739310, 'N'),		-- MEUDON
	(8739311, 'N'),		-- BELLEVUE
	(8739312, 'N'),		-- SEVRES RIVE GAUCHE
	(8739315, 'C'),		-- VERSAILLES RIVE GAUCHE - CHÂTEAU DE VERSAILLES
	(8739316, 'C'),		-- PORCHEFONTAINE
	(8739317, 'C'),		-- CHAVILLE VELIZY
	(8739320, 'N'),		-- CHAVILLE RIVE GAUCHE
	(8739321, 'C'),		-- VIROFLAY RIVE GAUCHE
	(8739321, 'N'),		-- VIROFLAY RIVE GAUCHE
	(8739322, 'C'),		-- SAINT-CYR
	(8739322, 'N'),		-- SAINT-CYR
	(8739322, 'U'),		-- SAINT-CYR
	(8739325, 'N'),		-- LA VERRIERE
	(8739325, 'U'),		-- LA VERRIERE
	(8739327, 'N'),		-- COIGNIERES
	(8739328, 'N'),		-- LES ESSARTS LE ROI
	(8739329, 'N'),		-- LE PERRAY
	(8739330, 'C'),		-- ISSY VAL DE SEINE
	(8739331, 'N'),		-- RAMBOUILLET
	(8739332, 'C'),		-- PONT DU GARIGLIANO - Hôpital Européen Georges Pompidou
	(8739336, 'N'),		-- BEYNES
	(8739340, 'N'),		-- FONTENAY LE FLEURY
	(8739341, 'N'),		-- VILLEPREUX LES CLAYES
	(8739342, 'N'),		-- PLAISIR GRIGNON
	(8739343, 'N'),		-- GARANCIERES LA QUEUE
	(8739344, 'N'),		-- ORGERUS BEHOUST
	(8739345, 'N'),		-- TACOIGNIERES RICHEBOURG
	(8739346, 'N'),		-- HOUDAN
	(8739347, 'N'),		-- MARCHEZAIS BROUE
	(8739348, 'N'),		-- DREUX
	(8739350, 'C'),		-- PETIT JOUY LES LOGES
	(8739351, 'C'),		-- JOUY EN JOSAS
	(8739353, 'C'),		-- VAUBOYEN
	(8739354, 'C'),		-- BIEVRES
	(8739356, 'C'),		-- IGNY
--	(8739357, 'B'),		-- MASSY PALAISEAU
	(8739357, 'C'),		-- MASSY PALAISEAU
	(8739361, 'C'),		-- LONGJUMEAU
	(8739362, 'N'),		-- PLAISIR LES CLAYES
	(8739363, 'C'),		-- CHILLY MAZARIN
	(8739364, 'C'),		-- GRAVIGNY BALIZY
	(8739365, 'C'),		-- PETIT VAUX
	(8739383, 'N'),		-- TRAPPES
	(8739383, 'U'),		-- TRAPPES
	(8739384, 'C'),		-- SAINT-QUENTIN EN YVELINES
	(8739384, 'N'),		-- SAINT-QUENTIN EN YVELINES
	(8739384, 'U'),		-- SAINT-QUENTIN EN YVELINES
	(8739387, 'L'),		-- NOISY LE ROI
	(8739388, 'N'),		-- VILLIERS NEAUPHLE PONTCHARTRAIN
	(8739389, 'N'),		-- MONTFORT L'AMAURY MERE
	(8741560, 'J'),		-- VERNON
	(8741588, 'J'),		-- ROSNY SUR SEINE
	(8741589, 'J'),		-- BONNIERES
	(8743081, 'P'),		-- LA FERTE GAUCHER CENTRE
	(8743088, 'P'),		-- JOUY SUR MORIN MONUMENT
	(8743090, 'P'),		-- JOUY SUR MORIN EUSTACHE
	(8743091, 'P'),		-- JOUY SUR MORIN CHAMPGOULIN
	(8743179, 'T4'),	-- ROUGEMONT CHANTELOUP (T4)
	(8749210, 'C'),		-- LES ARDOINES
	(8754017, 'C'),		-- DOURDAN LA FORET
	(8754309, 'C'),		-- ANGERVILLE
	(8754318, 'C'),		-- BOULAINVILLIERS
	(8754320, 'C'),		-- AVENUE DU PRESIDENT KENNEDY - Maison de Radio France
	(8754513, 'C'),		-- ETAMPES
	(8754514, 'C'),		-- ETRECHY
	(8754515, 'C'),		-- CHAMARANDE
	(8754516, 'C'),		-- LARDY
	(8754517, 'C'),		-- BOURAY
	(8754518, 'C'),		-- MAROLLES EN HUREPOIX
	(8754519, 'C'),		-- BRETIGNY
	(8754520, 'C'),		-- SAINT-MICHEL SUR ORGE
	(8754521, 'C'),		-- SAINTE-GENEVIEVE DES BOIS
	(8754522, 'C'),		-- EPINAY SUR ORGE
	(8754523, 'C'),		-- SAVIGNY SUR ORGE
	(8754524, 'C'),		-- JUVISY
	(8754524, 'D'),		-- JUVISY
	(8754525, 'C'),		-- ATHIS MONS
	(8754526, 'C'),		-- ABLON
	(8754527, 'C'),		-- VILLENEUVE LE ROI
	(8754528, 'C'),		-- CHOISY LE ROI
	(8754529, 'C'),		-- VITRY SUR SEINE
	(8754530, 'C'),		-- IVRY SUR SEINE
	(8754535, 'C'),		-- SAINT-MARTIN D ETAMPES
	(8754545, 'C'),		-- LA NORVILLE SAINT-GERMAIN LES ARPAJON
	(8754546, 'C'),		-- ARPAJON
	(8754547, 'C'),		-- EGLY
	(8754548, 'C'),		-- BREUILLET BRUYERES LE CHATEL
	(8754549, 'C'),		-- BREUILLET VILLAGE
	(8754550, 'C'),		-- SAINT-CHERON
	(8754551, 'C'),		-- SERMAISE
	(8754552, 'C'),		-- DOURDAN
	(8754619, 'C'),		-- PONT DE RUNGIS Aéroport d'Orly
	(8754620, 'C'),		-- ORLY VILLE
	(8754622, 'C'),		-- LES SAULES
	(8754629, 'C'),		-- RUNGIS LA FRATERNELLE
	(8754631, 'C'),		-- CHEMIN D'ANTONY
	(8754702, 'C'),		-- PARIS AUSTERLITZ (GARE D'AUSTERLITZ)
	(8754730, 'C'),		-- MUSEE D'ORSAY
	(8754731, 'C'),		-- SAINT MICHEL NOTRE DAME RER C
	(8760880, 'D'), 	-- CRETEIL POMPADOUR
	(8768100, 'D'),		-- CORBEIL ESSONNES
	(8768115, 'D'),		-- MAISONS ALFORT ALFORTVILLE
	(8768124, 'D'),		-- LE VERT DE MAISONS
	(8768130, 'D'),		-- VIGNEUX SUR SEINE
	(8768131, 'D'),		-- VIRY CHATILLON
	(8768133, 'D'),		-- RIS ORANGIS
	(8768134, 'D'),		-- ORANGIS BOIS DE L'EPINE
	(8768135, 'D'),		-- GRAND BOURG
	(8768136, 'D'),		-- EVRY - Val de Seine
	(8768137, 'D'),		-- GRIGNY CENTRE
	(8768138, 'D'),		-- EVRY COURCOURONNES - Centre
	(8768139, 'D'),		-- LE BRAS DE FER - Evry Génopole
	(8768140, 'D'),		-- MOULIN GALANT
	(8768141, 'D'),		-- MENNECY
	(8768143, 'D'),		-- BALLANCOURT
	(8768145, 'D'),		-- LA FERTE ALAIS
	(8768147, 'D'),		-- BOUTIGNY
	(8768148, 'D'),		-- MAISSE
	(8768151, 'D'),		-- BUNO GIRONVILLE
	(8768160, 'D'),		-- ESSONNES ROBINSON
	(8768161, 'D'),		-- VILLABE
	(8768162, 'D'),		-- LE PLESSIS CHENET
	(8768163, 'D'),		-- LE COUDRAY MONTCEAUX
	(8768180, 'D'),		-- VILLENEUVE TRIAGE
	(8768182, 'D'),		-- VILLENEUVE SAINT-GEORGES
	(8768185, 'D'),		-- VILLENEUVE PRAIRIE
	(8768200, 'D'),		-- MELUN
	(8768200, 'R'),		-- MELUN
	(8768210, 'D'),		-- MONTGERON CROSNE
	(8768211, 'D'),		-- YERRES
	(8768212, 'D'),		-- BRUNOY
	(8768213, 'D'),		-- BOUSSY SAINT-ANTOINE
	(8768214, 'D'),		-- COMBS LA VILLE QUINCY
	(8768215, 'D'),		-- LIEUSAINT MOISSY
	(8768216, 'D'),		-- CESSON
	(8768217, 'D'),		-- LE MEE
	(8768218, 'D'),		-- SAVIGNY LE TEMPLE NANDY
	(8768220, 'R'),		-- BOIS LE ROI
	(8768221, 'R'),		-- FONTAINEBLEAU AVON
	(8768225, 'R'),		-- THOMERY
	(8768227, 'R'),		-- MORET VENEUX LES SABLONS
	(8768229, 'R'),		-- SAINT-MAMMES
	(8768230, 'R'),		-- MONTEREAU
	(8768240, 'R'),		-- LIVRY SUR SEINE
	(8768241, 'R'),		-- CHARTRETTES
	(8768242, 'R'),		-- FONTAINE LE PORT
	(8768243, 'R'),		-- HERICY
	(8768244, 'R'),		-- VULAINES SUR SEINE SAMOREAU
	(8768245, 'R'),		-- CHAMPAGNE SUR SEINE
	(8768246, 'R'),		-- VERNOU SUR SEINE
	(8768247, 'R'),		-- LA GRANDE PAROISSE
	(8768250, 'D'),		-- VOSVES
	(8768251, 'D'),		-- BOISSISE LE ROI
	(8768252, 'D'),		-- PONTHIERRY PRINGY
	(8768254, 'D'),		-- SAINT-FARGEAU
	(8768400, 'R'),		-- MONTARGIS
	(8768410, 'R'),		-- MONTIGNY SUR LOING
	(8768411, 'R'),		-- BOURRON MARLOTTE GREZ
	(8768412, 'R'),		-- NEMOURS SAINT-PIERRE
	(8768419, 'R'),		-- BAGNEAUX SUR LOING
	(8768421, 'R'),		-- SOUPPES CHÂTEAU LANDON
	(8768423, 'R'),		-- DORDIVES
	(8768424, 'R'),		-- FERRIERES FONTENAY
	(8768440, 'D'),		-- BOIGNEVILLE
	(8768441, 'D'),		-- MALESHERBES
	(8768603, 'A'),		-- PARIS - GARE DE LYON
	(8768603, 'D'),		-- PARIS - GARE DE LYON
	(8768603, 'R'),		-- PARIS - GARE DE LYON
	(8768666, 'R'),		-- PARIS BERCY (GARE DE BERCY)
	(8773006, 'A'),		-- VAL D'EUROPE
	(8775498, 'A'),		-- BUSSY SAINT-GEORGES
	(8775499, 'A'),		-- MARNE LA VALLEE CHESSY
	(8775800, 'A'),		-- CHARLES DE GAULLE ETOILE
	(8775801, 'A'),		-- GARE DE LA DEFENSE RER A
	(8775802, 'A'),		-- GARE DE NANTERRE PREFECTURE
	(8775803, 'A'),		-- GARE DE NANTERRE UNIVERSITE RER A
	(8775804, 'A'),		-- NANTERRE VILLE
	(8775805, 'A'),		-- RUEIL MALMAISON
	(8775806, 'A'),		-- CHATOU CROISSY
	(8775807, 'A'),		-- LE VESINET CENTRE
	(8775808, 'A'),		-- LE VESINET LE PECQ
	(8775809, 'A'),		-- SAINT-GERMAIN EN LAYE
	(8775810, 'A'),		-- NATION
	(8775811, 'A'),		-- VINCENNES
	(8775812, 'A'),		-- FONTENAY SOUS BOIS
	(8775813, 'A'),		-- NOGENT SUR MARNE
	(8775814, 'A'),		-- JOINVILLE LE PONT
	(8775815, 'A'),		-- SAINT-MAUR CRETEIL
	(8775816, 'A'),		-- LE PARC DE SAINT-MAUR
	(8775817, 'A'),		-- CHAMPIGNY
	(8775818, 'A'),		-- LA VARENNE CHENNEVIERES
	(8775819, 'A'),		-- SUCY BONNEUIL
	(8775820, 'A'),		-- BOISSY SAINT-LEGER
	(8775831, 'A'),		-- NEUILLY PLAISANCE
	(8775832, 'A'),		-- BRY SUR MARNE
	(8775833, 'A'),		-- NOISY LE GRAND MONT D'EST
	(8775834, 'A'),		-- NOISY CHAMPS
	(8775835, 'A'),		-- NOISIEL
	(8775836, 'A'),		-- LOGNES
	(8775837, 'A'),		-- TORCY
	(8775859, 'A'),		-- AUBER
	(8775860, 'A'),		-- CHATELET LES HALLES
	(8775860, 'B'),		-- CHATELET LES HALLES
	(8775860, 'D'),		-- CHATELET LES HALLES
	(8775861, 'B'),		-- LUXEMBOURG
	(8775862, 'B'),		-- PORT ROYAL
	(8775863, 'B'),		-- DENFERT ROCHEREAU
	(8775864, 'B'),		-- CITE UNIVERSITAIRE
	(8775865, 'B'),		-- GENTILLY
	(8775866, 'B'),		-- LAPLACE
	(8775867, 'B'),		-- ARCUEIL CACHAN
	(8775868, 'B'),		-- BAGNEUX
	(8775869, 'B'),		-- BOURG LA REINE
	(8775870, 'B'),		-- SCEAUX
	(8775871, 'B'),		-- FONTENAY AUX ROSES
	(8775872, 'B'),		-- ROBINSON
	(8775873, 'B'),		-- PARC DE SCEAUX
	(8775874, 'B'),		-- LA CROIX DE BERNY
	(8775875, 'B'),		-- ANTONY
	(8775876, 'B'),		-- FONTAINE MICHALON
	(8775877, 'B'),		-- LES BACONNETS
	(8775880, 'B'),		-- PALAISEAU
	(8775881, 'B'),		-- PALAISEAU VILLEBON
	(8775882, 'B'),		-- LOZERE
	(8775883, 'B'),		-- LE GUICHET
	(8775884, 'B'),		-- ORSAY VILLE
	(8775885, 'B'),		-- BURES SUR YVETTE
	(8775886, 'B'),		-- LA HACQUINIERE
	(8775887, 'B'),		-- GIF SUR YVETTE
	(8775888, 'B'),		-- COURCELLE SUR YVETTE
	(8775889, 'B'),		-- SAINT-REMY LES CHEVREUSE
	(8778543, 'B'),		-- SAINT-MICHEL NOTRE DAME RER B
	(8798870, 'T4'),	-- REMISE A JORELLE (T4)
	(8739400, 'TER'),	-- CHARTRES
	(8739411, 'TER'),	-- EPERNON
	(8775858, 'A'),		-- GARE DE LYON RER A
	(8739334, 'TER'),	-- GAZERAN
	(8739415, 'TER'),	-- JOUY
	(8775879, 'B'),		-- MASSY PALAISEAU RER B
	(8739413, 'TER'),	-- MAINTENON
	(8775878, 'B'), 	-- MASSY VERRIERES RER B
	(8768600, 'A'),		-- PARIS - GARE DE LYON (alternatif)
	(8768600, 'D'),		-- PARIS - GARE DE LYON (alternatif)
	(8768600, 'R'),		-- PARIS - GARE DE LYON (alternatif)
	(8739414, 'TER'),	-- SAINT PIAT
	(8775830, 'A'),		-- VAL DE FONTENAY RER A
	(8798871, 'T4');	-- LYCEE HENRI SELLIER (T4)

-- Une procédure stockée pour faire un CURDATE() translaté d'un jour en 
-- si besoin (lorsqu'on touche à des heures postérieures à "minuit du
-- jour suivant", i.e. 24:00:00).

DROP FUNCTION IF EXISTS DATE_GTFS; 
CREATE FUNCTION DATE_GTFS(d DATE, t TIME)
RETURNS DATE DETERMINISTIC
RETURN IF(t >= '24:00:00', SUBDATE(d, INTERVAL 1 DAY), d);



DROP PROCEDURE IF EXISTS train_times_for_date;
DROP PROCEDURE IF EXISTS train_station_list;

DELIMITER //
CREATE PROCEDURE `train_times_for_date`(_d DATE, _station_code TEXT, _train_number CHAR(6))
BEGIN
SELECT r.route_short_name,
	SUBSTR(trip_id, 6, 6) AS train_number,
	ADDTIME(CAST(DATE_GTFS(_d, departure_time) AS DATETIME), departure_time) AS due_time,
	gares.code,
	CAST(COALESCE(gares.uic, SUBSTR(stop_id, 14)) AS CHAR) AS uic,
	gares.name,
	stop_times.stop_sequence
FROM trips AS t
	LEFT JOIN calendar AS c USING (service_id)
	LEFT JOIN calendar_dates AS cd USING (service_id)
	LEFT JOIN routes AS r USING (route_id)
	JOIN stop_times USING (trip_id)
	LEFT JOIN gares ON (SUBSTR(stop_id, 14) = gares.uic)
WHERE (
	(start_date <= DATE_GTFS(_d, departure_time)
		AND DATE_GTFS(_d, departure_time) <= end_date
		AND (date <> DATE_GTFS(_d, departure_time) OR date IS NULL OR exception_type <> 2)
        )
        OR (
		date = DATE_GTFS(_d, departure_time) AND exception_type = 1)
        )
	AND (trip_id LIKE CONCAT('DUASN', _train_number, '%'))
	AND (code = _station_code);
END //


CREATE PROCEDURE `train_station_list`(_d DATE, _train_number CHAR(6), _index INTEGER)
BEGIN
SELECT DISTINCT gares.code,
	CAST(COALESCE(gares.uic, SUBSTR(stop_id, 14)) AS CHAR) AS uic,
	gares.name
FROM trips AS t
	LEFT JOIN calendar AS c USING (service_id)
	LEFT JOIN calendar_dates AS cd USING (service_id)
	LEFT JOIN routes AS r USING (route_id)
	JOIN stop_times USING (trip_id)
	LEFT JOIN gares ON (SUBSTR(stop_id, 14) = gares.uic)
WHERE (
	(start_date <= DATE_GTFS(_d, departure_time)
		AND DATE_GTFS(_d, departure_time) <= end_date
		AND (date <> DATE_GTFS(_d, departure_time) OR date IS NULL OR exception_type <> 2)
        )
        OR (
		date = DATE_GTFS(_d, departure_time) AND exception_type = 1)
        )
	AND (trip_id LIKE CONCAT('DUASN', _train_number, '%'))
	AND (stop_sequence > _index);
END //

DELIMITER ;

