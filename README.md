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

L'API expose `POST /auth/register` et `POST /auth/login`, qui renvoient un jeton `accessToken` (JWT signe avec `JWT_SECRET`). Les endpoints compte, preferences, favoris et signalements exigent ce jeton dans l'en-tete `Authorization: Bearer <token>` ; la consultation des concerts reste publique.

En developpement, si `JWT_SECRET` vaut `replace-me` ou est vide, un secret de developpement est utilise ; en production le demarrage echoue tant qu'un vrai secret n'est pas defini.

## Mode demonstration

Pour presenter l'application sans API ni base de donnees (donnees mock uniquement) :

```bash
cd apps/mobile
flutter run --dart-define LIVEAROUND_DEMO_MODE=true
```

## Statut actuel

Premiere base de code initialisee avec :

- application Flutter avec page Connexion/Creation, puis onglets Decouvrir, Favoris et Profil ;
- API NestJS avec endpoints auth, concerts, compte utilisateur, preferences, favoris et signalements ;
- integration Ticketmaster pour les vrais concerts ;
- configuration Docker Compose PostGIS et migrations applicatives de developpement ;
- documentation d'architecture et de developpement.
