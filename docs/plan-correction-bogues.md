# Plan de correction des bogues

## Classification et delais cibles

| Severite | Definition | Exemples | Prise en charge | Correction visee |
|---|---|---|---|---|
| S1 — Bloquant | Fonction essentielle inutilisable ou faille de securite | connexion impossible, acces aux donnees d'autrui | immediate | < 24 h (hotfix) |
| S2 — Majeur | Fonction degradee sans contournement simple | filtres sans effet, favoris non persistes | < 2 jours | prochaine release corrective |
| S3 — Mineur | Genant avec contournement | affichage errone, message peu clair | < 1 semaine | prochaine release planifiee |
| S4 — Cosmetique | Sans impact fonctionnel | alignement, faute de frappe | au fil de l'eau | opportuniste |

## Flux de traitement

1. **Consignation** — toute anomalie devient une issue GitHub via le modele « Rapport d'anomalie » ([processus complet](anomalies-processus.md)) : symptome, etapes de reproduction, environnement, logs.
2. **Qualification** — reproduction, classement en severite, identification du composant (mobile / API / donnees).
3. **Correction** — branche `fix/<sujet>` depuis `main` ; le correctif inclut un **test qui reproduit le bogue** (non-regression) chaque fois que c'est possible.
4. **Verification** — CI verte (lint, build, tests des deux applications) + rejeu du scenario du cahier de recettes concerne + revue via pull request.
5. **Livraison** — merge sur `main` ; S1 declenche immediatement une release corrective (tag `vX.Y.Z+1`), les autres partent avec la release suivante.
6. **Cloture** — l'issue référence la PR et la version corrigée ; la fiche d'anomalie est completee (cause racine, correctif, verification).

## Regles

- Un bogue S1/S2 sur `main` **bloque toute nouvelle fonctionnalite** jusqu'a correction.
- Pas de correctif sans comprehension de la cause racine : les symptomes masques (fallbacks silencieux) ont deja coute cher au projet — voir [fiche-anomalie-001](anomalies/fiche-anomalie-001-cleartext-android.md).
- Toute anomalie recurrente (2 occurrences) donne lieu a une action de fond (test automatise, garde-fou, documentation).

## Exemples reels traites selon ce plan

| Anomalie | Severite | Issue → correctif |
|---|---|---|
| Appels API bloques par la politique cleartext Android 9+ | S1 | [fiche 001](anomalies/fiche-anomalie-001-cleartext-android.md) — corrige en v0.1.0 |
| Filtres de genre sans resultat (classifications Ticketmaster) | S2 | [fiche 002](anomalies/fiche-anomalie-002-genres-ticketmaster.md) — corrige en v0.1.0 |
