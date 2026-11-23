# SAÉ « Le Jardin de Charlotte » – Base de données d'un fleuriste

Projet réalisé en 1re année de BUT Informatique (semestre 1), IUT Lyon 1.

## Contexte

Une fleuriste lyonnaise vend des bouquets sur commande. Chaque commande contient un ou plusieurs bouquets, chaque bouquet est composé de plusieurs fleurs, et la commande est soit livrée (avec des frais selon le code postal), soit retirée en magasin. La fleuriste achète ses fleurs chaque matin auprès de grossistes.

L'objectif : concevoir la base de données, l'alimenter à partir des fichiers CSV fournis, puis répondre aux questions de la fleuriste avec des requêtes SQL.

## Contenu

| Fichier | Rôle |
|---|---|
| `01_creation_tables.sql` | Création des tables avec clés primaires, clés étrangères et contraintes |
| `02_import_donnees.sql` | Import des CSV dans des tables intermédiaires, nettoyage et remplissage des tables finales |
| `03_requetes_analyse.sql` | Requêtes d'analyse R1 à R9 |

## Modèle de données

- **CLIENT** passe des **COMMANDE**s ; une commande peut être envoyée à un **DESTINATAIRE** et livrée selon un tarif de **LIVRAISON** (par code postal).
- Une commande contient des **BOUQUET**s ; chaque bouquet est composé (**COMPOSER**) de **FLEUR**s.
- Les fleurs sont achetées (**ACHETER**) auprès de **GROSSISTE**s.

Le MCD et le MPD ont été réalisés sous Looping.

## Difficultés rencontrées

- **Identifier les clients** : un même nom apparaît dans plusieurs commandes. Le nom seul n'étant pas une clé fiable, un client est identifié par son numéro de téléphone.
- **Valeurs manquantes** : dans le fichier des compositions, les numéros de commande et de bouquet ne sont écrits qu'en tête de chaque groupe. Ils sont propagés vers le bas avec `LAST_VALUE ... IGNORE NULLS` avant de remplir `BOUQUET` et `COMPOSER`.
- **Prix stockés en texte** : les tarifs contenaient des espaces, des virgules ou le symbole €, ce qui provoquait l'erreur `ORA-01722`. Ils sont nettoyés avant la conversion avec `TO_NUMBER`.
- **Retraits en magasin** : les commandes sans destinataire étaient perdues avec une jointure interne. Un `LEFT JOIN` permet de les conserver.
- **Ordre d'import** : les tables sont remplies dans l'ordre des clés étrangères (tables de référence, puis clients, commandes, bouquets et compositions).

## Requêtes d'analyse

R1 commandes payées en 2021 · R2 codes postaux les plus livrés · R3 fleur la plus utilisée en 2021 · R4 nombre moyen de bouquets par client · R5 fleurs jamais utilisées · R6 fleur préférée de chaque client · R7 montant de chaque commande · R8 commande la plus chère en retrait magasin · R9 commande la plus chère.

## Note

Les fichiers d'origine ont été perdus. Les scripts de ce dossier ont été reconstitués à partir de mes notes de projet, avec l'aide d'une IA. Les données CSV fournies par l'IUT ne sont pas publiées ici.
