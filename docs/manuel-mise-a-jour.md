# Manuel de mise a jour

## Mettre a jour l'API (production)

Les versions sont publiees sous forme d'images Docker versionnees par le pipeline de release ([deploiement-continu.md](deploiement-continu.md)).

```bash
cd LiveAround/apps/api

# 1. Choisir la version cible (journal : CHANGELOG.md / releases GitHub)
export LIVEAROUND_VERSION=0.4.0

# 2. Recuperer et redemarrer l'API (la base n'est pas touchee)
docker compose -f docker-compose.prod.yml pull api
docker compose -f docker-compose.prod.yml up -d api

# 3. Verifier
curl http://localhost:3000/health
docker compose -f docker-compose.prod.yml logs api | grep -E "Migration|schema ready"
```

**Migrations** : elles s'appliquent automatiquement au demarrage, une seule fois chacune, en transaction (table `schema_migrations`). En cas d'echec d'une migration, l'API demarre en mode degrade et le log l'indique — voir [supervision.md](supervision.md).

**Retour arriere** : redeployer le tag precedent (`LIVEAROUND_VERSION=<ancienne version>`). Les migrations sont additives, le schema reste compatible avec la version precedente de l'API.

## Mettre a jour l'application mobile

- **Utilisateurs** : installer le nouvel APK attache a la release GitHub (ou via le store une fois publie). Les donnees (compte, favoris) sont conservees : elles vivent cote serveur.
- **Compatibilite** : l'API conserve la compatibilite ascendante des endpoints au sein d'une meme version majeure ; une app `n-1` continue de fonctionner face a une API `n`.

## Mettre a jour l'environnement de developpement

```bash
git pull
cd apps/api && npm ci            # dependances API alignees sur package-lock
cd ../mobile && flutter pub get  # dependances Flutter
```

La base locale se met a niveau automatiquement au prochain demarrage de l'API (`npm run start:dev`).
