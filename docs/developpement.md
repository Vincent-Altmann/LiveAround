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

L'application affiche d'abord une page de connexion. Apres connexion ou creation de compte, l'identifiant de session renvoye par l'API est conserve avec `shared_preferences` puis envoye dans l'en-tete `x-livearound-device-id`.

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
- `POST /auth/register`
- `POST /auth/login`
- `POST /users/me`
- `GET /users/me`
- `PATCH /users/me/preferences`
- `GET /users/me/favorites`
- `GET /concerts`
- `GET /concerts/:id`
- `POST /concerts/:id/favorite`
- `POST /concerts/:id/report`

Exemple de creation de compte :

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "content-type: application/json" \
  -d '{"displayName":"Demo","email":"demo@livearound.local","password":"Concerts123!"}'
```

Exemple de connexion :

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "content-type: application/json" \
  -d '{"email":"demo@livearound.local","password":"Concerts123!"}'
```

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
"C:\Program Files\Docker\Docker\resources\bin\docker.exe" compose up -d
```

PostgreSQL est expose sur `localhost:5432`.

L'API applique les migrations de developpement au demarrage :

- ajout de `device_id` sur `users` ;
- hash de mot de passe `password_hash` ;
- preferences `preferred_genres` et `preferred_radius_km` ;
- table `user_concert_favorites` pour les favoris Ticketmaster sauvegardes avec un snapshot JSON.

Si PostgreSQL n'est pas joignable en local, l'API demarre tout de meme avec un stockage volatile afin de garder l'application mobile testable.

### Docker Desktop sous Windows

Docker Desktop est installe dans `C:\Program Files\Docker\Docker` lorsque l'installeur officiel est utilise. Si `docker info` indique que le daemon n'est pas joignable et que `wsl --status` indique que WSL n'est pas installe, ouvrir PowerShell en administrateur puis lancer :

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --install
```

Redemarrer Windows si l'une de ces commandes le demande, ouvrir Docker Desktop, puis relancer la commande `docker compose up -d` depuis `apps/api`.

## Prochaines integrations

- Cle Ticketmaster reelle dans `apps/api/.env`.
- Geocodage ville -> latitude/longitude.
- Jetons JWT pour remplacer le `deviceId` de session MVP.
- Persistance avancee des signalements.
- Firebase Cloud Messaging.
