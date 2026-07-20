# Processus de mise a jour des dependances

## Outils

- **Dependabot** (`.github/dependabot.yml`) : passe hebdomadaire sur les dependances npm de l'API et pub de l'application Flutter (une PR groupee par ecosysteme pour limiter le bruit), passe mensuelle sur les actions GitHub.
- **Verification manuelle** avant chaque release :

```bash
cd apps/api && npm outdated && npm audit
cd apps/mobile && flutter pub outdated
```

## Regles de traitement

1. **Toute mise a jour passe par une PR** et doit avoir la CI verte (lint, build, 26 tests) : les dependances suivent le meme protocole que le code.
2. **Correctifs de securite** (`npm audit`, alertes GitHub) : traites en priorite S1/S2 selon l'exposition, sans attendre la passe hebdomadaire.
3. **Mises a jour mineures/correctives** : fusionnees apres CI verte et relecture du journal des changements.
4. **Mises a jour majeures** : traitees individuellement, avec lecture du guide de migration, rejeu du cahier de recettes sur la zone concernee, et mention dans le CHANGELOG.
5. **Versions verrouillees** : `package-lock.json` commite et `npm ci` en CI/CD garantissent des builds reproductibles ; `pubspec.lock` joue le meme role cote Flutter.

## Historique notable

- `typeorm` retire (dependance installee mais jamais utilisee) — reduction de la surface et du temps d'installation.
- ESLint migre vers la configuration flat (v9) pour suivre la version majeure de l'outil.
- Ajouts justifies au fil du projet : `@nestjs/jwt` (sessions), `@nestjs/throttler` + `helmet` (durcissement), `url_launcher` (billetterie), `flutter_localizations` (accessibilite/langue).
