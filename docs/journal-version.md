# Exemplaire de journal de version — LiveAround v0.3.0

> Notes de version publiees avec le tag `v0.3.0` (release GitHub du 16/07/2026). L'historique complet est tenu dans [CHANGELOG.md](../CHANGELOG.md).

---

## LiveAround v0.3.0 — « Sessions durables et compte maitrise »

**Date** : 16 juillet 2026 · **Perimetre** : API 0.3.0 + application mobile 0.3.0 · **PR** : #4

### Nouveautes pour les utilisateurs

- **Restez connecte en securite** : votre session se renouvelle automatiquement ; en cas d'expiration, l'application vous ramene proprement a l'ecran de connexion.
- **Mot de passe oublie ?** Reinitialisez-le avec un code a 6 chiffres depuis l'ecran de connexion.
- **Votre compte vous appartient** : changement de mot de passe et suppression definitive du compte depuis le profil (section Securite).
- **Des resultats sans limite** : la liste des concerts se complete automatiquement en defilant (par pages de 50).

### Changements techniques

- Jetons d'acces 7 jours + refresh tokens rotatifs 90 jours (hashes en base, revocation a chaque changement de mot de passe).
- Rate limiting (5 req/min sur l'authentification), en-tetes helmet, CORS par liste blanche.
- Migrations de schema versionnees et transactionnelles (`schema_migrations`) — mise a jour de production sans intervention manuelle.
- Refactorisation de l'ecran Decouvrir autour d'un controleur d'etat (pagination, favoris mis a jour en place).

### Corrections

- L'ecran Decouvrir ne perd plus la position de defilement ni la saisie en cours lorsque les preferences du profil changent.
- Le prix « 0 EUR » n'est plus affiche lorsque le tarif n'est pas communique.

### Mise a jour

- **Serveur** : `LIVEAROUND_VERSION=0.3.0 docker compose -f docker-compose.prod.yml pull api && docker compose -f docker-compose.prod.yml up -d api` — migrations automatiques, retour arriere possible vers 0.2.0.
- **Mobile** : installer l'APK `app-release.apk` attache a la release. Les comptes et favoris sont conserves.

### Verifications de la version

26 tests unitaires verts (CI), 17 controles E2E du cycle de vie du compte (rotation et revocation des jetons, reinitialisation, anti-enumeration, 429, pagination, suppression), cahier de recettes rejoue sur emulateur Android.
