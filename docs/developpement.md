# Guide de developpement

## Prerequis

- Flutter SDK (stable) ;
- Node.js 22 et npm ;
- Docker Desktop (PostgreSQL/PostGIS).

## Demarrage rapide

```bash
# Base de donnees
cd apps/api && docker compose up -d

# API (migrations appliquees automatiquement au demarrage)
npm install && npm run start:dev

# Mobile (emulateur Android : l'hote est accessible via 10.0.2.2)
cd ../mobile && flutter pub get
flutter run --dart-define LIVEAROUND_API_BASE_URL=http://10.0.2.2:3000
```

Cle Ticketmaster : creer `apps/api/.env` a partir de `.env.example`. Sans cle, l'API sert le cache PostGIS puis les donnees de demonstration. Mode demo sans API : `flutter run --dart-define LIVEAROUND_DEMO_MODE=true`.

## Verifications locales (identiques a la CI)

```bash
cd apps/api && npm run lint && npm run build && npm test
cd apps/mobile && flutter analyze && flutter test
```

## Authentification

`POST /auth/register` et `POST /auth/login` renvoient `accessToken` (JWT 7 j) et `refreshToken` (rotatif 90 j). Les endpoints proteges attendent `Authorization: Bearer <accessToken>` ; le renouvellement passe par `POST /auth/refresh`.

```bash
# Creation de compte
curl -X POST http://localhost:3000/auth/register \
  -H "content-type: application/json" \
  -d '{"displayName":"Demo","email":"demo@livearound.local","password":"Concerts123!"}'

# Requete authentifiee
curl http://localhost:3000/users/me -H "Authorization: Bearer <accessToken>"
```

## Endpoints

Documentation interactive Swagger : `http://localhost:3000/docs`.

| Domaine | Endpoints |
|---|---|
| Sante | `GET /health` |
| Auth | `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/change-password`, `/auth/forgot-password`, `/auth/reset-password` |
| Compte | `GET/POST /users/me`, `PATCH /users/me/preferences`, `GET /users/me/favorites`, `DELETE /users/me` |
| Concerts | `GET /concerts` (position, rayon, genres, dates, recherche, page), `GET /concerts/:id`, `POST /concerts/:id/favorite`, `POST /concerts/:id/report` |
| Alertes | `GET /users/me/notifications`, `POST /users/me/notifications/:id/click` |

## Base de donnees

Le schema est gere par les **migrations versionnees** de `apps/api/src/database/migrations.ts` (voir table `schema_migrations`). Pour ajouter une evolution : ajouter une entree avec un `id` superieur — ne jamais modifier une migration fusionnee. Si PostgreSQL est injoignable, l'API demarre en mode degrade (etat volatil, auth indisponible) en le journalisant.

## Emulateur Android

Voir [emulateur-vscode.md](emulateur-vscode.md). AVD utilise pour la recette : `Medium_Phone_API_35`.

## Conventions

Branches `feat/*` / `fix/*` depuis `main`, commits `type(scope): sujet`, fusion par pull request avec CI verte — protocole complet : [integration-continue.md](integration-continue.md).
