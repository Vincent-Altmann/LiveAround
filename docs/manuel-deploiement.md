# Manuel de deploiement

Ce manuel decrit le deploiement de LiveAround en production. Pour l'environnement de developpement, voir [developpement.md](developpement.md).

## Composants a deployer

| Composant | Artefact | Ou |
|---|---|---|
| API NestJS | Image Docker `ghcr.io/vincent-altmann/livearound-api:<version>` | Serveur (VPS, cloud) |
| Base de donnees | Image `postgis/postgis:16-3.4` | Meme serveur (Compose) ou service manage |
| Application mobile | `app-release.apk` attache a la release GitHub | Appareils Android / store |

## Prerequis serveur

- Docker et Docker Compose v2 ;
- un nom de domaine et un reverse proxy TLS (Caddy, Traefik ou Nginx) devant le port 3000 — l'application mobile de production doit appeler l'API en HTTPS (le trafic en clair n'est autorise que pour les builds de debug) ;
- acces au registre GitHub Container Registry (image publique ou `docker login ghcr.io`).

## Variables d'environnement

Creer un fichier `.env` a cote de `docker-compose.prod.yml` (jamais commite) :

| Variable | Obligatoire | Role |
|---|---|---|
| `POSTGRES_PASSWORD` | oui | Mot de passe de la base |
| `JWT_SECRET` | oui | Signature des jetons (l'API refuse de demarrer en production sans secret fort) |
| `TICKETMASTER_API_KEY` | recommande | Sans cle, l'API sert le cache PostGIS puis les donnees de demonstration |
| `CORS_ORIGINS` | si clients web | Liste blanche d'origines, separees par des virgules ; ferme par defaut en production |
| `LIVEAROUND_VERSION` | non | Version de l'image API (defaut `latest`) |

## Procedure de deploiement

```bash
# 1. Recuperer les fichiers de deploiement (ou cloner le depot)
git clone https://github.com/Vincent-Altmann/LiveAround.git && cd LiveAround/apps/api

# 2. Creer le fichier .env (voir tableau ci-dessus)

# 3. Demarrer
docker compose -f docker-compose.prod.yml up -d

# 4. Verifier
curl http://localhost:3000/health   # {"status":"ok",...}
docker compose -f docker-compose.prod.yml logs api | grep Migration
```

Les **migrations de schema s'appliquent automatiquement au demarrage de l'API** (table `schema_migrations`) : aucune commande SQL manuelle n'est necessaire, ni a l'installation ni lors des mises a jour.

## Application mobile

L'APK de release est construit par le workflow `release.yml` avec l'URL d'API definie par la variable de depot GitHub `LIVEAROUND_API_BASE_URL` (Settings > Variables). Pour un build manuel :

```bash
cd apps/mobile
flutter build apk --release --dart-define LIVEAROUND_API_BASE_URL=https://api.mondomaine.fr
```

## Retour arriere (rollback)

Les images sont versionnees : revenir a la version precedente consiste a redeployer l'ancien tag.

```bash
LIVEAROUND_VERSION=0.3.0 docker compose -f docker-compose.prod.yml up -d api
```

Les migrations sont additives (jamais de suppression de colonne dans une version publiee) : une API `n-1` fonctionne sur un schema `n`, ce qui rend le rollback sans risque pour les donnees.
