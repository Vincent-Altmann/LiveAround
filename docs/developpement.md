# Guide de developpement

## Prerequis

- Flutter SDK.
- Node.js 20 ou superieur.
- npm fonctionnel.
- Docker Desktop pour PostgreSQL/PostGIS.

## Mobile

```bash
cd apps/mobile
flutter pub get
flutter test
flutter run
```

Le MVP mobile actuel utilise des donnees mockees afin de valider l'UX sans attendre les integrations API, cartographie ou notification.

## API

```bash
cd apps/api
npm install
npm run start:dev
```

API locale attendue :

```text
http://localhost:3000
```

Endpoints initiaux :

- `GET /health`
- `GET /concerts`
- `GET /concerts/:id`
- `POST /concerts/:id/favorite`
- `POST /concerts/:id/report`

## Base de donnees

```bash
cd apps/api
docker compose up -d
```

PostgreSQL est expose sur `localhost:5432`.

## Prochaines integrations

- Cle Ticketmaster reelle dans `apps/api/.env`.
- Geocodage ville -> latitude/longitude.
- Authentification utilisateur.
- Persistance favoris et signalements.
- Firebase Cloud Messaging.
