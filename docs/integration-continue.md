# Protocole d'integration continue

## Strategie de branches

- `main` est la branche de reference : toujours fonctionnelle, fiable et deployable ; les versions y sont taguees (`vX.Y.Z`).
- Tout travail passe par une branche courte `feat/<sujet>` ou `fix/<sujet>` creee depuis `main`.
- L'integration se fait exclusivement par **pull request** vers `main`, avec description detaillee (objectif, changements, tests effectues). Historique applique : PR #1 (correctifs bloquants), #2 (completion MVP), #3 (ingestion et alertes), #4 (sessions et durcissement).
- Les commits suivent la convention `type(scope): sujet` (`feat(api): ...`, `fix(mobile): ...`) avec un corps expliquant le pourquoi.

## Pipeline (GitHub Actions — `.github/workflows/ci.yml`)

Declenche sur chaque push vers `main` et chaque pull request, en deux jobs paralleles :

| Job | Etapes | Ce qui est bloque |
|---|---|---|
| mobile | `flutter pub get` → `flutter analyze` → `flutter test` | tout avertissement d'analyse statique, tout test rouge (10 tests) |
| api | `npm ci` → `npm run lint` → `npm run build` → `npm test` | installation non reproductible, erreur ESLint, erreur TypeScript, test rouge (16 tests) |

Une PR ne peut etre fusionnee que si le pipeline est vert : la CI est le garde-fou des [criteres de qualite](qualite-performance.md).

## Reproductibilite

- Versions verrouillees : `package-lock.json` + `npm ci` (API), `pubspec.lock` (Flutter).
- Les memes commandes fonctionnent a l'identique en local et en CI (aucune etape magique du pipeline).

## Articulation avec le deploiement

Le pipeline de release ([deploiement-continu.md](deploiement-continu.md)) **rejoue l'integralite de ces verifications** avant de construire les artefacts : rien ne peut etre publie qui ne passe pas la CI.
