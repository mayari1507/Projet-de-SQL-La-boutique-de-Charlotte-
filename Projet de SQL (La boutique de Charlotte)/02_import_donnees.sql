-- ============================================================
-- SAÉ « Le Jardin de Charlotte » – Import et nettoyage des données
-- Reconstitution à partir de mes notes de projet (fichiers d'origine perdus).
--
-- Méthode : les fichiers CSV fournis sont d'abord importés tels quels dans
-- des tables intermédiaires (clic droit sur « Tables » > Importer des données
-- dans SQL Developer), puis les tables finales sont remplies avec INSERT ... SELECT.
-- L'ordre suit les clés étrangères : on remplit les tables référencées en premier.
-- ============================================================

-- 1. Tables intermédiaires --------------------------------------
-- Les prix sont importés en texte, car certains fichiers les contiennent
-- dans un format non numérique (virgule, espaces...).

CREATE TABLE FLEURS (nomFleur VARCHAR2(30), tarifFleur VARCHAR2(20));
CREATE TABLE GROSSISTES (numSIREN NUMBER(9), nom VARCHAR2(50));
CREATE TABLE LIVRAISONS (codePostal VARCHAR2(10), tarifLivraison VARCHAR2(20));
CREATE TABLE ACHATS (dateAchat DATE, numSIREN NUMBER(9), nomFleur VARCHAR2(30),
                     nbrFleurs NUMBER, prixAchatUnitaire VARCHAR2(20));
CREATE TABLE COMMANDES (
  numCommande NUMBER, nomClient VARCHAR2(50), numTelClient VARCHAR2(20),
  mailClient VARCHAR2(100), adresseClient VARCHAR2(100), codePostalClient VARCHAR2(10),
  villeClient VARCHAR2(50), dateCommande DATE, datePaiement DATE, dateRealisation DATE,
  nomDestinataire VARCHAR2(50), numTelDestinataire VARCHAR2(20),
  adresseDestinataire VARCHAR2(100), codePostalDestinataire VARCHAR2(10),
  villeDestinataire VARCHAR2(50), dateLivraisonEffective DATE
);
-- numLigne garde l'ordre des lignes du fichier : il sert à propager
-- les numéros de commande et de bouquet laissés vides (voir étape 5).
CREATE TABLE COMPOSITIONS (
  numLigne NUMBER GENERATED ALWAYS AS IDENTITY,
  numCommande NUMBER, numBouquet NUMBER, nbrBouquets NUMBER,
  nomFleur VARCHAR2(30), nbrFleurs NUMBER
);

-- >>> Importer ici les 6 fichiers CSV dans ces tables intermédiaires. <<<

-- 2. Tables de référence ---------------------------------------
-- Conversion des prix texte en nombre : on retire les espaces et le symbole €,
-- puis on remplace la virgule par un point.

INSERT INTO FLEUR (nomFleur, tarifFleur)
SELECT TRIM(nomFleur),
       TO_NUMBER(REPLACE(REPLACE(REPLACE(tarifFleur, ' ', ''), '€', ''), ',', '.'),
                 '999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')
FROM FLEURS
WHERE nomFleur IS NOT NULL;

INSERT INTO GROSSISTE (numSIREN, nom)
SELECT DISTINCT numSIREN, TRIM(nom)
FROM GROSSISTES
WHERE numSIREN IS NOT NULL;

INSERT INTO LIVRAISON (codePostal, tarifLivraison)
SELECT TRIM(codePostal),
       TO_NUMBER(REPLACE(REPLACE(REPLACE(tarifLivraison, ' ', ''), '€', ''), ',', '.'),
                 '999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')
FROM LIVRAISONS
WHERE codePostal IS NOT NULL;

-- 3. Clients et destinataires -----------------------------------
-- Un même nom peut apparaître dans plusieurs commandes : le nom seul n'est pas
-- une clé fiable. Un client est identifié ici par son numéro de téléphone.

INSERT INTO CLIENT (idClient, nomClient, numTelClient, mailClient,
                    adresseClient, codePostalClient, villeClient)
SELECT ROWNUM, nomClient, numTelClient, mailClient,
       adresseClient, codePostalClient, villeClient
FROM (
  SELECT MAX(nomClient) AS nomClient, numTelClient, MAX(mailClient) AS mailClient,
         MAX(adresseClient) AS adresseClient, MAX(codePostalClient) AS codePostalClient,
         MAX(villeClient) AS villeClient
  FROM COMMANDES
  WHERE nomClient IS NOT NULL
  GROUP BY numTelClient
);

INSERT INTO DESTINATAIRE (idDestinataire, nomDestinataire, numTelDestinataire,
                          adresseDestinataire, codePostalDestinataire, villeDestinataire)
SELECT ROWNUM, nomDestinataire, numTelDestinataire,
       adresseDestinataire, codePostalDestinataire, villeDestinataire
FROM (
  SELECT DISTINCT nomDestinataire, numTelDestinataire, adresseDestinataire,
                  codePostalDestinataire, villeDestinataire
  FROM COMMANDES
  WHERE nomDestinataire IS NOT NULL
);

-- 4. Commandes ---------------------------------------------------
-- LEFT JOIN sur DESTINATAIRE : les commandes retirées en magasin (sans
-- destinataire) doivent aussi être importées, avec idDestinataire à NULL.

INSERT INTO COMMANDE (numCommande, dateCommande, datePaiement, dateRealisation,
                      dateLivraisonEffective, idClient, codePostalLivraison, idDestinataire)
SELECT c.numCommande, c.dateCommande, c.datePaiement, c.dateRealisation,
       c.dateLivraisonEffective, cl.idClient, c.codePostalDestinataire, d.idDestinataire
FROM COMMANDES c
JOIN CLIENT cl
  ON cl.numTelClient = c.numTelClient
LEFT JOIN DESTINATAIRE d
  ON  d.nomDestinataire = c.nomDestinataire
  AND d.adresseDestinataire = c.adresseDestinataire
  AND d.codePostalDestinataire = c.codePostalDestinataire
WHERE c.numCommande IS NOT NULL;

-- 5. Achats --------------------------------------------------------

INSERT INTO ACHETER (nomFleur, numSIREN, dateAchat, nbrFleursAchetees, prixAchatUnitaire)
SELECT TRIM(nomFleur), numSIREN, dateAchat, nbrFleurs,
       TO_NUMBER(REPLACE(REPLACE(REPLACE(prixAchatUnitaire, ' ', ''), '€', ''), ',', '.'),
                 '999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''')
FROM ACHATS;

-- 6. Bouquets et compositions ------------------------------------
-- Dans le fichier des compositions, numCommande et numBouquet ne sont écrits
-- qu'en tête de chaque groupe, puis laissés vides. On propage la dernière
-- valeur non vide vers le bas avec LAST_VALUE ... IGNORE NULLS.

CREATE OR REPLACE VIEW V_COMPOSITIONS AS
SELECT numLigne,
       LAST_VALUE(numCommande IGNORE NULLS) OVER (ORDER BY numLigne) AS numCommande,
       LAST_VALUE(numBouquet  IGNORE NULLS) OVER (ORDER BY numLigne) AS numBouquet,
       LAST_VALUE(nbrBouquets IGNORE NULLS) OVER (ORDER BY numLigne) AS nbrBouquets,
       TRIM(nomFleur) AS nomFleur,
       nbrFleurs
FROM COMPOSITIONS;

-- Une ligne par bouquet (BOUQUET doit être rempli avant COMPOSER).
INSERT INTO BOUQUET (numCommande, numBouquet, nbrBouquets)
SELECT numCommande, numBouquet, MAX(nbrBouquets)
FROM V_COMPOSITIONS
GROUP BY numCommande, numBouquet;

-- Une ligne par fleur de chaque bouquet.
INSERT INTO COMPOSER (numCommande, numBouquet, nomFleur, nbrFleurs)
SELECT numCommande, numBouquet, nomFleur, SUM(nbrFleurs)
FROM V_COMPOSITIONS
WHERE nomFleur IS NOT NULL
GROUP BY numCommande, numBouquet, nomFleur;

COMMIT;

-- 7. Vérifications --------------------------------------------------
SELECT 'CLIENT' AS table_name, COUNT(*) AS nb FROM CLIENT
UNION ALL SELECT 'DESTINATAIRE', COUNT(*) FROM DESTINATAIRE
UNION ALL SELECT 'COMMANDE', COUNT(*) FROM COMMANDE
UNION ALL SELECT 'BOUQUET', COUNT(*) FROM BOUQUET
UNION ALL SELECT 'COMPOSER', COUNT(*) FROM COMPOSER
UNION ALL SELECT 'ACHETER', COUNT(*) FROM ACHETER;
