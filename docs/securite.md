# Mesures de securite mises en œuvre

## Authentification et sessions

| Mesure | Implementation | Justification |
|---|---|---|
| Hachage des mots de passe | PBKDF2-SHA256, 120 000 iterations, sel aleatoire par compte, comparaison a temps constant (`timingSafeEqual`) | jamais de mot de passe en clair ; resistance au forcage hors-ligne et aux attaques temporelles |
| Jetons d'acces courts | JWT HS256 signe (`JWT_SECRET`), duree 7 jours | limite la fenetre d'exploitation d'un jeton vole |
| Refresh tokens rotatifs | jeton aleatoire 48 octets, stocke **hashe** (SHA-256) en base, duree 90 jours, **rotation a chaque usage** (reutilisation → 401) | un vol de refresh token est detectable et sa copie devient inutilisable |
| Revocation | changement/reinitialisation de mot de passe → suppression de tous les refresh tokens du compte | eviction immediate d'un attaquant ayant obtenu une session |
| Identite de session | l'identifiant de compte provient exclusivement du JWT verifie par `SessionGuard` (plus d'en-tete client accepte tel quel) | supprime l'usurpation par identifiant devine (anomalie corrigee en v0.1.0) |
| Secret JWT | obligatoire en production (l'API refuse de demarrer avec le secret d'exemple) | pas de deploiement avec un secret connu |

## Protection des endpoints

- **Guards** : endpoints compte, preferences, favoris, alertes et signalements proteges par JWT ; consultation des concerts publique avec session optionnelle (aucun compte cree a la volee).
- **Rate limiting** (`@nestjs/throttler`) : 100 req/min global, **5 req/min sur register/login/forgot/reset** — verifie en recette (429 a la 6e tentative).
- **Validation systematique** des entrees : DTO `class-validator` avec `whitelist` (les champs inconnus sont rejetes), bornes de tailles, `ParseUUIDPipe` sur les identifiants.
- **helmet** : en-tetes de securite HTTP sur toutes les reponses.
- **CORS** : liste blanche via `CORS_ORIGINS`, ferme par defaut en production, ouvert uniquement en developpement.

## Comptes et donnees personnelles

- **Anti-enumeration** : la demande de reinitialisation renvoie une reponse identique que l'email existe ou non ; les messages d'echec de connexion ne distinguent pas email inconnu et mot de passe errone.
- **Codes de reinitialisation** : 6 chiffres aleatoires (CSPRNG), stockes hashes, expiration 15 minutes, usage unique, comparaison a temps constant.
- **RGPD** : suppression definitive du compte dans l'application (confirmee par mot de passe) — favoris, alertes et sessions supprimes en cascade, signalements anonymises ; minimisation (seuls nom, email et derniere position de recherche sont conserves) ; geolocalisation soumise au consentement avec alternative sans GPS (ville manuelle).
- **Secrets** : `.env` exclus du depot (`.gitignore`), `.env.example` sans valeur sensible, secrets de production limites au serveur.
- **Journalisation** : jamais de mot de passe, jeton ou code en production ; les erreurs sont tracees sans donnees sensibles.

## Chaine de livraison

- CI obligatoire (lint, build, tests) avant fusion ; release impossible sans rejeu de ces controles.
- `npm ci` + lockfiles : pas de derive de dependances ; veille Dependabot hebdomadaire ([dependances.md](dependances.md)).
- Image Docker : build multi-etapes sans outils de compilation dans l'image finale, execution **non-root** (`USER node`), healthcheck integre.
- Trafic mobile : HTTPS attendu en production ; le HTTP en clair n'est autorise que pour les builds de debug vers l'API locale.

## Limites connues (assumees et documentees)

- Envoi des codes de reinitialisation par email non branche (SMTP) : le code est trace cote serveur et expose en `devCode` uniquement hors production.
- Pas de verification d'adresse email a l'inscription ni de detection de compromission de mot de passe (HIBP) — voir [recommandations](recommandations.md).
