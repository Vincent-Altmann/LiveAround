# Frameworks et paradigmes de developpement

## Frameworks retenus (conformes au cadrage)

| Couche | Framework | Justification |
|---|---|---|
| Mobile | **Flutter** (Dart) | une seule base de code Android/iOS, rendu declaratif performant, ecosysteme de packages (cartes, localisation), accessibilite et internationalisation integrees |
| API | **NestJS** (TypeScript, Node 22) | architecture modulaire avec injection de dependances, validation declarative, guards, ecosysteme mature (JWT, throttling, Swagger) |
| Base | **PostgreSQL + PostGIS** | requetes geospatiales indexees (`ST_DWithin`, tri par distance), fiabilite transactionnelle |
| CI/CD | GitHub Actions + **Docker** | pipeline reproductible, images immuables versionnees |

## Paradigmes et patrons appliques

### Cote API (NestJS)

- **Programmation orientee objet et modulaire** : un module par domaine (auth, users, concerts, notifications, database, common), services a responsabilite unique.
- **Injection de dependances** : les services recoivent leurs collaborateurs par constructeur — testabilite (doubles de test) et couplage faible.
- **Programmation declarative par decorateurs** : routes (`@Get`, `@Post`), validation (`class-validator` sur les DTO), protection (`@UseGuards`, `@Throttle`).
- **Inversion de dependance** : `PushSender` est une abstraction dont l'implementation (in-app aujourd'hui, FCM demain) est choisie par le module — le service d'alertes n'en sait rien.
- **Patron Strategy / chaine de repli** : source de concerts Ticketmaster → cache PostGIS → donnees de demonstration, chaque maillon etant interchangeable.
- **Migrations versionnees** : evolution du schema par etapes numerotees, transactionnelles et historisees.

### Cote mobile (Flutter)

- **UI declarative et composition** : l'interface est une fonction de l'etat ; widgets petits et composables.
- **Patron Repository** : `ConcertRepository` / `AccountRepository` sont des interfaces ; les implementations API (HTTP) et mock (demonstration hors ligne) sont interchangeables sans toucher aux ecrans.
- **Separation en couches** : `domain/` (modeles metier purs), `data/` (acces aux donnees), `features/` (ecrans par fonctionnalite), `theme/`.
- **Patron Observateur** : `DiscoveryController extends ChangeNotifier` porte l'etat de la decouverte (filtres, pagination, resultats) ; la vue s'abonne via `ListenableBuilder` — l'etat survit aux reconstructions de widgets.
- **Programmation asynchrone** : `Future`/`async-await` systematiques, debounce des saisies, verrou de renouvellement de session partage entre appels concurrents.
- **Immutabilite** : modeles et filtres immuables avec `copyWith` (y compris la gestion explicite de l'effacement via sentinelle).

### Transverse

- **API REST** avec DTO valides et codes HTTP semantiques ; documentation Swagger exposee sur `/docs`.
- **Fail-fast cote authentification** (aucun repli silencieux) et **degradation progressive cote consultation** (replis journalises) — regle nee de l'anomalie 001.
- **Tests unitaires** sur la logique pure (mapping, caches, geometrie, pagination) et **verifications de bout en bout** scriptees.
