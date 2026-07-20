# Processus de collecte et de consignation des anomalies

## Canaux de collecte

1. **Utilisateurs — donnees incorrectes** : le bouton de signalement present sur chaque fiche concert enregistre le signalement en base (`concert_reports` : concert, motif, auteur, statut, horodatage). C'est le canal « support » integre a l'application.
2. **Utilisateurs — dysfonctionnements** : remontes au support (mail/store), retranscrits par l'equipe en issue GitHub.
3. **Equipe et recette** : toute anomalie constatee en developpement, en revue de PR ou lors du deroulement du [cahier de recettes](cahier-recettes.md) est consignee en issue GitHub.
4. **Automatique** : echecs de CI (chaque PR), logs d'erreur applicatifs ([supervision](supervision.md)).

## Consignation

Chaque anomalie est consignee via le modele d'issue GitHub « Rapport d'anomalie » (`.github/ISSUE_TEMPLATE/rapport-anomalie.md`) qui impose les rubriques :

- symptome observe (et message d'erreur exact) ;
- etapes de reproduction ;
- resultat attendu / resultat obtenu ;
- environnement (version de l'app, appareil/emulateur, version de l'API) ;
- extraits de logs.

Les anomalies significatives donnent ensuite lieu a une **fiche detaillee** dans `docs/anomalies/` documentant le diagnostic complet : cause racine, correctif, verification, mesures d'evitement. Deux fiches reelles du projet :

- [Fiche 001 — appels API bloques par la politique cleartext Android](anomalies/fiche-anomalie-001-cleartext-android.md)
- [Fiche 002 — filtres de genre sans resultat (classifications Ticketmaster)](anomalies/fiche-anomalie-002-genres-ticketmaster.md)

## Cycle de vie d'une issue d'anomalie

`ouverte` → `qualifiee` (severite S1-S4, composant) → `en correction` (branche `fix/*`) → `en verification` (CI + recette + revue) → `fermee` (reference de la PR et de la version corrigee).

Les delais par severite et les regles de traitement sont definis dans le [plan de correction des bogues](plan-correction-bogues.md). Le traitement des signalements « donnees incorrectes » suit le meme cycle : qualification (erreur de la source ou de notre normalisation), correction ou remontee a la source, passage du statut `open` a `resolved` en base.
