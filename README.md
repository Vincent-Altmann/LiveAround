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

- Compte utilisateur, puis preferences musicales
- Geolocalisation ou ville renseignee manuellement
- Liste de concerts proches
- Filtres par date, genre et distance
- Fiche concert avec lien billetterie
- Favoris
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

## Statut actuel

Premiere base de code initialisee avec :

- application Flutter MVP sur donnees mockees ;
- API NestJS avec endpoints concerts, favoris et signalements ;
- configuration Docker Compose PostGIS ;
- documentation d'architecture et de developpement.
