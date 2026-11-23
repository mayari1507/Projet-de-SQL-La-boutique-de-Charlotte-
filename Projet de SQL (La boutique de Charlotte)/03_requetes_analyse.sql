-- ============================================================
-- SAÉ « Le Jardin de Charlotte » – Requêtes d'analyse R1 à R9
-- Reconstitution à partir de l'énoncé (fichiers d'origine perdus).
-- ============================================================

-- Vue utilitaire : montant de chaque commande.
-- Montant = somme (nombre de fleurs x nombre d'exemplaires du bouquet x prix de la fleur)
--         + frais de livraison du code postal (0 en cas de retrait en magasin).
CREATE OR REPLACE VIEW V_MONTANT_COMMANDE AS
SELECT co.numCommande,
       co.dateCommande,
       co.idClient,
       co.codePostalLivraison,
       SUM(cp.nbrFleurs * b.nbrBouquets * f.tarifFleur) + NVL(MAX(l.tarifLivraison), 0) AS montant
FROM COMMANDE co
JOIN BOUQUET b    ON b.numCommande = co.numCommande
JOIN COMPOSER cp  ON cp.numCommande = b.numCommande AND cp.numBouquet = b.numBouquet
JOIN FLEUR f      ON f.nomFleur = cp.nomFleur
LEFT JOIN LIVRAISON l ON l.codePostal = co.codePostalLivraison
GROUP BY co.numCommande, co.dateCommande, co.idClient, co.codePostalLivraison;

-- R1 – Nombre de commandes payées en 2021
SELECT COUNT(*) AS nb_commandes_payees_2021
FROM COMMANDE
WHERE EXTRACT(YEAR FROM datePaiement) = 2021;

-- R2 – Les trois codes postaux ayant le plus de livraisons
SELECT codePostalLivraison, COUNT(*) AS nb_livraisons
FROM COMMANDE
WHERE codePostalLivraison IS NOT NULL
GROUP BY codePostalLivraison
ORDER BY nb_livraisons DESC
FETCH FIRST 3 ROWS WITH TIES;

-- R3 – La fleur la plus utilisée en 2021
SELECT cp.nomFleur, SUM(cp.nbrFleurs * b.nbrBouquets) AS nb_fleurs
FROM COMPOSER cp
JOIN BOUQUET b   ON b.numCommande = cp.numCommande AND b.numBouquet = cp.numBouquet
JOIN COMMANDE co ON co.numCommande = cp.numCommande
WHERE EXTRACT(YEAR FROM co.dateRealisation) = 2021
GROUP BY cp.nomFleur
ORDER BY nb_fleurs DESC
FETCH FIRST 1 ROWS WITH TIES;

-- R4 – Nombre moyen de bouquets par client
SELECT ROUND(AVG(nb_bouquets), 2) AS moyenne_bouquets_par_client
FROM (
  SELECT cl.idClient, NVL(SUM(b.nbrBouquets), 0) AS nb_bouquets
  FROM CLIENT cl
  LEFT JOIN COMMANDE co ON co.idClient = cl.idClient
  LEFT JOIN BOUQUET b   ON b.numCommande = co.numCommande
  GROUP BY cl.idClient
);

-- R5 – Fleurs jamais utilisées dans les bouquets
SELECT nomFleur FROM FLEUR
MINUS
SELECT nomFleur FROM COMPOSER;

-- R6 – Fleur préférée de chaque client (celle qu'il a commandée en plus grande quantité)
WITH fleurs_client AS (
  SELECT co.idClient, cp.nomFleur,
         SUM(cp.nbrFleurs * b.nbrBouquets) AS quantite,
         RANK() OVER (PARTITION BY co.idClient
                      ORDER BY SUM(cp.nbrFleurs * b.nbrBouquets) DESC) AS rang
  FROM COMMANDE co
  JOIN BOUQUET b   ON b.numCommande = co.numCommande
  JOIN COMPOSER cp ON cp.numCommande = b.numCommande AND cp.numBouquet = b.numBouquet
  GROUP BY co.idClient, cp.nomFleur
)
SELECT cl.nomClient, fc.nomFleur, fc.quantite
FROM fleurs_client fc
JOIN CLIENT cl ON cl.idClient = fc.idClient
WHERE fc.rang = 1
ORDER BY cl.nomClient;

-- R7 – Numéro, date, nom du client et montant de chaque commande
SELECT m.numCommande, m.dateCommande, cl.nomClient, m.montant
FROM V_MONTANT_COMMANDE m
JOIN CLIENT cl ON cl.idClient = m.idClient
ORDER BY m.numCommande;

-- R8 – Client ayant passé la commande la plus chère avec retrait en magasin
SELECT cl.nomClient, m.numCommande, m.montant
FROM V_MONTANT_COMMANDE m
JOIN CLIENT cl ON cl.idClient = m.idClient
WHERE m.codePostalLivraison IS NULL
ORDER BY m.montant DESC
FETCH FIRST 1 ROWS WITH TIES;

-- R9 – Client ayant passé la commande la plus chère (livraison ou retrait)
SELECT cl.nomClient, m.numCommande, m.montant
FROM V_MONTANT_COMMANDE m
JOIN CLIENT cl ON cl.idClient = m.idClient
ORDER BY m.montant DESC
FETCH FIRST 1 ROWS WITH TIES;
