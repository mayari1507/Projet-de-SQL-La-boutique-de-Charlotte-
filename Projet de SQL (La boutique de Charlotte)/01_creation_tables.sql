-- ============================================================
-- SAÉ « Le Jardin de Charlotte » – Création des tables (Oracle)
-- Reconstitution à partir de mes notes de projet (fichiers d'origine perdus).
-- MCD / MPD réalisés sous Looping.
-- ============================================================

-- Tables de référence -----------------------------------------

CREATE TABLE CLIENT (
  idClient          NUMBER        CONSTRAINT pk_client PRIMARY KEY,
  nomClient         VARCHAR2(50)  NOT NULL,
  numTelClient      VARCHAR2(20),
  mailClient        VARCHAR2(100),
  adresseClient     VARCHAR2(100),
  codePostalClient  VARCHAR2(10),
  villeClient       VARCHAR2(50)
);

CREATE TABLE DESTINATAIRE (
  idDestinataire          NUMBER        CONSTRAINT pk_destinataire PRIMARY KEY,
  nomDestinataire         VARCHAR2(50)  NOT NULL,
  numTelDestinataire      VARCHAR2(20),
  adresseDestinataire     VARCHAR2(100),
  codePostalDestinataire  VARCHAR2(10),
  villeDestinataire       VARCHAR2(50)
);

CREATE TABLE LIVRAISON (
  codePostal      VARCHAR2(10)  CONSTRAINT pk_livraison PRIMARY KEY,
  tarifLivraison  NUMBER(6,2)   NOT NULL
);

CREATE TABLE GROSSISTE (
  numSIREN  NUMBER(9)     CONSTRAINT pk_grossiste PRIMARY KEY,
  nom       VARCHAR2(50)  NOT NULL
);

CREATE TABLE FLEUR (
  nomFleur    VARCHAR2(30)  CONSTRAINT pk_fleur PRIMARY KEY,
  tarifFleur  NUMBER(6,2)   CONSTRAINT ck_fleur_tarif CHECK (tarifFleur > 0)
);

-- Commandes ----------------------------------------------------
-- codePostalLivraison et idDestinataire restent NULL pour un retrait en magasin.

CREATE TABLE COMMANDE (
  numCommande             NUMBER        CONSTRAINT pk_commande PRIMARY KEY,
  dateCommande            DATE,
  datePaiement            DATE,
  dateRealisation         DATE,
  dateLivraisonEffective  DATE,
  idClient                NUMBER        NOT NULL
                          CONSTRAINT fk_cmd_client REFERENCES CLIENT(idClient),
  codePostalLivraison     VARCHAR2(10)
                          CONSTRAINT fk_cmd_livraison REFERENCES LIVRAISON(codePostal),
  idDestinataire          NUMBER
                          CONSTRAINT fk_cmd_dest REFERENCES DESTINATAIRE(idDestinataire)
);

-- Un bouquet est numéroté à l'intérieur d'une commande.
CREATE TABLE BOUQUET (
  numCommande  NUMBER(5),
  numBouquet   NUMBER(5),
  nbrBouquets  NUMBER(5),
  CONSTRAINT pk_bouquet PRIMARY KEY (numCommande, numBouquet),
  CONSTRAINT fk_bouquet_cmd FOREIGN KEY (numCommande) REFERENCES COMMANDE(numCommande)
);

-- Composition d'un bouquet : quelles fleurs, en quelle quantité.
CREATE TABLE COMPOSER (
  numCommande  NUMBER,
  numBouquet   NUMBER,
  nomFleur     VARCHAR2(30),
  nbrFleurs    NUMBER,
  CONSTRAINT pk_composer PRIMARY KEY (numCommande, numBouquet, nomFleur),
  CONSTRAINT fk_composer_bouquet FOREIGN KEY (numCommande, numBouquet)
             REFERENCES BOUQUET(numCommande, numBouquet),
  CONSTRAINT fk_composer_fleur FOREIGN KEY (nomFleur) REFERENCES FLEUR(nomFleur)
);

-- Achats de fleurs auprès des grossistes.
CREATE TABLE ACHETER (
  nomFleur           VARCHAR2(30),
  numSIREN           NUMBER(9),
  dateAchat          DATE,
  nbrFleursAchetees  NUMBER(5),
  prixAchatUnitaire  NUMBER(8,2),
  CONSTRAINT pk_acheter PRIMARY KEY (nomFleur, numSIREN),
  CONSTRAINT fk_acheter_fleur FOREIGN KEY (nomFleur) REFERENCES FLEUR(nomFleur),
  CONSTRAINT fk_acheter_grossiste FOREIGN KEY (numSIREN) REFERENCES GROSSISTE(numSIREN)
);
