# LiveAround

Application mobile nationale de decouverte de concerts a proximite, basee sur le cadrage Master 2 fourni pour PulseEvent SAS.

## Stack retenue

- Mobile : Flutter
- API : NestJS
- Base de donnees cible : PostgreSQL + PostGIS
- Notifications cible : Firebase Cloud Messaging
- Donnees concerts : API externes + cache + enrichissement interne

## Structure

```text
apps/
  mobile/   Application Flutter
  api/      Backend NestJS
docs/       Documentation projet
```

## Documentation

| Theme | Documents |
|---|---|
| Conception | [Architecture](docs/architecture.md) · [Frameworks et paradigmes](docs/frameworks-paradigmes.md) · [Cadrage](docs/cadrage-synthese.md) · [Backlog](docs/backlog.md) · [Prototype](docs/prototype.md) |
| Qualite | [Criteres qualite/performance](docs/qualite-performance.md) · [Cahier de recettes](docs/cahier-recettes.md) · [Securite](docs/securite.md) · [Accessibilite](docs/accessibilite.md) |
| CI/CD | [Integration continue](docs/integration-continue.md) · [Deploiement continu](docs/deploiement-continu.md) |
| Manuels | [Developpement](docs/developpement.md) · [Deploiement](docs/manuel-deploiement.md) · [Utilisation](docs/manuel-utilisation.md) · [Mise a jour](docs/manuel-mise-a-jour.md) |
| Exploitation | [Supervision](docs/supervision.md) · [Anomalies (processus)](docs/anomalies-processus.md) · [Plan de correction des bogues](docs/plan-correction-bogues.md) · [Dependances](docs/dependances.md) |
| Vie du projet | [CHANGELOG](CHANGELOG.md) · [Journal de version (exemplaire)](docs/journal-version.md) · [Fiches d'anomalies](docs/anomalies/) · [Support client (exemple)](docs/support-client.md) · [Recommandations](docs/recommandations.md) |

## MVP fonctionnel vise

- Connexion, creation de compte et preferences musicales
- Geolocalisation ou ville renseignee manuellement
- Liste de concerts proches
- Filtres par date, genre et distance
- Fiche concert avec lien billetterie
- Favoris persistants par compte
- Alertes personnalisees
- Signalement d'une donnee incorrecte

## Demarrage mobile

Le code Flutter est dans `apps/mobile`.

```bash
cd apps/mobile
flutter pub get
flutter run
```

Sur emulateur Android, l'API locale de la machine hote doit etre appelee avec `10.0.2.2` :

```bash
cd apps/mobile
flutter run --dart-define LIVEAROUND_API_BASE_URL=http://10.0.2.2:3000
```

Si les dossiers natifs Android/iOS ne sont pas encore presents, lancer une seule fois :

```bash
cd apps/mobile
flutter create . --platforms=android,ios
```

## Demarrage API

Le code NestJS est dans `apps/api`.

```bash
cd apps/api
npm install
npm run start:dev
```

Pour utiliser Ticketmaster, creer `apps/api/.env` a partir de `.env.example`, puis renseigner :

```env
TICKETMASTER_API_KEY=...
TICKETMASTER_COUNTRY_CODE=FR
TICKETMASTER_LOCALE=fr-fr,*
```

Pour lancer PostgreSQL/PostGIS localement :

```bash
docker compose up -d
```

L'API expose `POST /auth/register` et `POST /auth/login`, qui renvoient un `accessToken` (JWT 7 jours) et un `refreshToken` rotatif (90 jours, stocke hashe en base) a echanger via `POST /auth/refresh`. Les endpoints compte, preferences, favoris, alertes et signalements exigent le jeton d'acces dans l'en-tete `Authorization: Bearer <token>` ; la consultation des concerts reste publique.

Gestion du compte : `POST /auth/change-password`, `POST /auth/forgot-password` (code a 6 chiffres, 15 min — l'envoi par email reste a brancher, le code est trace dans les logs et renvoye en `devCode` hors production), `POST /auth/reset-password`, `DELETE /users/me` (suppression definitive confirmee par mot de passe).

Securite : rate limiting global 100 req/min avec limite stricte 5 req/min sur les endpoints d'authentification, en-tetes helmet, CORS restreint par `CORS_ORIGINS` (ouvert en developpement uniquement). En developpement, si `JWT_SECRET` vaut `replace-me` ou est vide, un secret de developpement est utilise ; en production le demarrage echoue tant qu'un vrai secret n'est pas defini.

Le schema de base de donnees est gere par des migrations versionnees (`apps/api/src/database/migrations.ts`, historisees dans `schema_migrations`). Les recherches de concerts sont paginees (`page`, 50 resultats par page) et l'application mobile charge les pages suivantes au fil du defilement.

## Mode demonstration

Pour presenter l'application sans API ni base de donnees (donnees mock uniquement) :

```bash
cd apps/mobile
flutter run --dart-define LIVEAROUND_DEMO_MODE=true
```

## Statut actuel

Base de code MVP avec :

- application Flutter : connexion/creation de compte (session JWT), onglets Decouvrir, Favoris et Profil ;
- recherche de concerts par position GPS ou ville choisie manuellement, filtres genre, distance et date (aujourd'hui, week-end, 7 jours, periode libre), carte interactive ;
- fiche concert avec image de l'artiste, ouverture de la billetterie, favoris persistants, signalement d'une donnee incorrecte ;
- preferences musicales, rayon favori et opt-in alertes dans le profil ;
- alertes personnalisees : les nouveaux concerts correspondant aux preferences (genres, rayon, derniere position) sont notifies in-app via la cloche de l'ecran Decouvrir, avec regle anti-spam (3/jour) et historisation des clics ; l'envoi push FCM est le dernier maillon a brancher (voir apps/api/src/notifications/push-sender.ts) ;
- API NestJS : auth JWT, concerts via Ticketmaster avec cache memoire (recherches 2 min, details 10 min), preferences, favoris, signalements persistes en base ;
- ingestion PostGIS : chaque recherche Ticketmaster alimente les tables venues/concerts ; si Ticketmaster est indisponible, l'API sert les concerts depuis ce cache persistant (tri par distance PostGIS), avec purge automatique des concerts passes ;
- configuration Docker Compose PostGIS, migrations applicatives de developpement, tests unitaires API et mobile executes par la CI ;
- documentation d'architecture et de developpement.
