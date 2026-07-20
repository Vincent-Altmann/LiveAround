# Fiche d'anomalie 002 — Filtres de genre sans resultat (classifications Ticketmaster)

| Champ | Valeur |
|---|---|
| Identifiant | ANO-002 |
| Date de detection | 13/07/2026 (audit du MVP) |
| Detecteur | Revue technique, confirmee par test sur l'API reelle |
| Composant | API — client Ticketmaster |
| Severite | S2 — majeur (fonctionnalite cœur « filtrer par genre » inoperante sur donnees reelles) |
| Statut | Corrigee et verifiee — livree en v0.1.0 (PR #1) |

## Symptome observe

Avec une cle Ticketmaster reelle, les filtres « Electro », « Classique » ou « Rap » ne renvoyaient aucun concert pertinent, alors que des concerts de ces genres existaient bien dans la zone. Les filtres « Rock », « Pop » et « Jazz » semblaient fonctionner.

## Reproduction

1. API demarree avec une cle Ticketmaster valide.
2. `GET /concerts?latitude=45.76&longitude=4.83&radiusKm=50&genres=Electro`
3. Constat : 0 resultat pertinent, la ou `genres=Rock` renvoyait des concerts.

## Diagnostic (cause racine)

Les libelles de genre de l'interface (en francais : « Electro », « Classique », « Rap ») etaient transmis tels quels au parametre `classificationName` de l'API Discovery, qui attend les classifications **anglaises** de Ticketmaster (« Electronic », « Classical », « Hip-Hop/Rap »). « Rock », « Pop » et « Jazz » ne fonctionnaient que par coincidence orthographique. Anomalie invisible en developpement car le jeu de demonstration utilisait les libelles francais.

## Correctif

Table de correspondance bidirectionnelle dans le client Ticketmaster (`ticketmaster.client.ts`) : les genres FR sont convertis vers les classifications officielles a l'envoi (`Electro → Electronic`, `Rap → Hip-Hop/Rap`, `Classique → Classical`), et les classifications recues sont reconverties vers les libelles FR a l'affichage, pour rester coherents avec les filtres et les preferences.

## Verification

- Test sur l'API reelle : `genres=Electro` renvoie 12 concerts autour de Lyon, etiquetes « Electro » ;
- tests unitaires dedies (`ticketmaster.client.spec.ts`) : conversion aller et retour, genres combines, genres inconnus conserves — rejoues a chaque CI ;
- scenario de recette M4.

## Mesures d'evitement

- Les fonctions de mapping sont exportees et couvertes par des tests unitaires (non-regression en CI).
- Enseignement consigne : toute integration externe doit etre validee contre le service reel, pas seulement contre les donnees de demonstration.
