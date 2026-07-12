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

Le MVP mobile appelle l'API NestJS lorsque `LIVEAROUND_API_BASE_URL` est disponible, avec un fallback mock pour conserver une experience testable hors ligne.

L'application cree un identifiant local avec `shared_preferences`. Cet identifiant est envoye a l'API dans l'en-tete `x-livearound-device-id` afin de rattacher profil, preferences et favoris au meme compte mobile.

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
- `POST /users/me`
- `GET /users/me`
- `PATCH /users/me/preferences`
- `GET /users/me/favorites`
- `GET /concerts`
- `GET /concerts/:id`
- `POST /concerts/:id/favorite`
- `POST /concerts/:id/report`

Exemple de creation ou chargement du compte courant :

```bash
curl -X POST http://localhost:3000/users/me \
  -H "content-type: application/json" \
  -d '{"deviceId":"mobile-demo","displayName":"Demo","email":"demo@users.livearound.local"}'
```

Exemple de sauvegarde des preferences :

```bash
curl -X PATCH http://localhost:3000/users/me/preferences \
  -H "content-type: application/json" \
  -H "x-livearound-device-id: mobile-demo" \
  -d '{"preferredGenres":["Rock","Jazz"],"preferredRadiusKm":40}'
```

## Base de donnees

```bash
cd apps/api
docker compose up -d
```

PostgreSQL est expose sur `localhost:5432`.

L'API applique les migrations de developpement au demarrage :

- ajout de `device_id` sur `users` ;
- preferences `preferred_genres` et `preferred_radius_km` ;
- table `user_concert_favorites` pour les favoris Ticketmaster sauvegardes avec un snapshot JSON.

Si PostgreSQL n'est pas joignable en local, l'API demarre tout de meme avec un stockage volatile afin de garder l'application mobile testable.

## Prochaines integrations

- Cle Ticketmaster reelle dans `apps/api/.env`.
- Geocodage ville -> latitude/longitude.
- Authentification utilisateur JWT/email.
- Persistance avancee des signalements.
- Firebase Cloud Messaging.
