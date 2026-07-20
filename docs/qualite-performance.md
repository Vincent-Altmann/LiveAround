# Criteres de qualite et de performance

## Criteres de qualite (bloquants en CI)

| Critere | Cible | Verification |
|---|---|---|
| Analyse statique Flutter | 0 probleme (`flutter_lints`) | `flutter analyze` en CI |
| Lint API | 0 erreur ESLint (config flat v9, typescript-eslint) | `npm run lint` en CI |
| Compilation TypeScript | 0 erreur | `npm run build` en CI |
| Tests unitaires | 100 % verts (16 API + 10 mobile) | `npm test` / `flutter test` en CI |
| Revue de code | toute fusion passe par une pull request | protocole de branches |
| Validation des entrees | 100 % des DTO valides (`class-validator`, whitelist) | revue + tests |
| Panne silencieuse | interdite : toute bascule de repli est journalisee et, cote auth, echoue explicitement | revue (regle issue de la [fiche d'anomalie 001](anomalies/fiche-anomalie-001-cleartext-android.md)) |

## Criteres de performance

| Critere | Cible | Mesure |
|---|---|---|
| Reponse API — recherche en cache | < 150 ms | mesure : 68 ms (contre 370 ms sans cache) |
| Reponse API — recherche via Ticketmaster | < 1 s | mesure : ~370 ms |
| Quota Ticketmaster (5 req/s, 5000 req/j) | jamais atteint en usage normal | cache TTL 2 min (recherches) et 10 min (details), debounce 400 ms sur la saisie, rechargement du rayon en fin de geste uniquement, favori bascule en 1 requete |
| Memoire API | bornee | caches LRU a taille fixe (200 recherches / 500 details), purge des concerts passes |
| Charge base | requetes geo indexees | index GIST sur les positions, index dates/genres, pagination LIMIT/OFFSET |
| Fluidite mobile | pas de rechargement complet inutile | mise a jour en place des favoris, resynchronisation unitaire au retour de fiche, defilement infini par pages de 50 |
| Resilience | l'app reste utilisable si un maillon tombe | chaine Ticketmaster → cache PostGIS → demonstration, verifiee en recette (M8) |

## Protection de l'API

Themes rattaches a la qualite de service : rate limiting global 100 req/min et 5 req/min sur l'authentification, timeouts client de 4 s, pool de connexions base borne. Details : [securite.md](securite.md).

## Suivi

Ces criteres sont verifies a chaque PR (CI), completes par le [cahier de recettes](cahier-recettes.md) avant chaque release et par la [supervision](supervision.md) en exploitation.
