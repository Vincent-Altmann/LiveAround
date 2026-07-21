# Journal des modifications

Historique des versions de LiveAround. Format inspire de [Keep a Changelog](https://keepachangelog.com/fr/), versionnement semantique. Chaque version correspond a un tag Git et a une release GitHub.

## [Non publie]

### Ajoute
- Rappels de concerts favoris (opt-in dans le profil) : notification unique quand un concert en favoris demarre dans moins de 3 jours (« c'est aujourd'hui / c'est demain / dans N jours »), affichee dans le centre d'alertes avec une icone calendrier. Les notifications sont desormais typees (alerte decouverte / rappel de favori).

## [0.4.0] — 2026-07-22

### Ajoute
- Deploiement continu : Dockerfile de l'API, composition de production, workflow de release sur tag (image ghcr.io + APK attache a la release).
- Accessibilite : locale francaise des composants systeme, libelles pour lecteurs d'ecran (boutons, images, reperes de carte), contrastes releves au niveau AA, annonce de la valeur du rayon.
- Veille des dependances automatisee (Dependabot) et modeles d'issues (anomalie, amelioration).
- Documentation complete du projet : manuels (deploiement, utilisation, mise a jour), protocoles CI/CD, criteres qualite/performance, securite, accessibilite, supervision, cahier de recettes, plan de correction des bogues, processus anomalies et dependances, fiches d'anomalies, presentation du prototype, recommandations.

## [0.3.0] — 2026-07-16

### Ajoute
- Refresh tokens rotatifs (90 j, hashes en base) avec `POST /auth/refresh` ; renouvellement automatique cote mobile et retour a la connexion en fin de session.
- Gestion complete du compte : changement de mot de passe, reinitialisation par code a 6 chiffres (anti-enumeration), suppression de compte RGPD confirmee par mot de passe.
- Pagination des recherches (pages de 50) et defilement infini.
- Migrations de schema versionnees (table `schema_migrations`), transactionnelles.
### Modifie
- Jeton d'acces raccourci de 30 a 7 jours.
- Etat de l'ecran Decouvrir porte par un controleur (fin des reconstructions forcees ; favoris mis a jour en place).
### Securite
- Rate limiting (100/min global, 5/min sur l'authentification), en-tetes helmet, CORS par liste blanche.

## [0.2.0] — 2026-07-14

### Ajoute
- Ingestion PostGIS : les recherches alimentent les tables `venues`/`concerts` ; repli geospatial complet si Ticketmaster est indisponible ; purge des concerts passes.
- Alertes personnalisees : balayage periodique (genres, rayon, derniere position), anti-spam 3/24 h, centre d'alertes in-app, clics historises, abstraction PushSender (FCM a brancher).
- Photos des artistes sur les cartes et les fiches concert.

## [0.1.0] — 2026-07-13

### Ajoute
- MVP complet : comptes JWT, recherche Ticketmaster (genres, distance, dates, recherche libre), ville manuelle sans GPS, carte interactive, favoris persistants, billetterie, signalements, opt-in alertes, caches API, mode demonstration.
### Corrige
- Appels API bloques par la politique cleartext d'Android 9+ (fiche d'anomalie 001).
- Filtres de genre sans resultat face aux classifications Ticketmaster (fiche d'anomalie 002).
- Authentification sans verification cote serveur (en-tete client accepte tel quel) remplacee par des sessions JWT signees.

[0.4.0]: https://github.com/Vincent-Altmann/LiveAround/releases/tag/v0.4.0
[0.3.0]: https://github.com/Vincent-Altmann/LiveAround/releases/tag/v0.3.0
[0.2.0]: https://github.com/Vincent-Altmann/LiveAround/releases/tag/v0.2.0
[0.1.0]: https://github.com/Vincent-Altmann/LiveAround/releases/tag/v0.1.0
