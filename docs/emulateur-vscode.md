# Emulateur Android et VS Code

## Etat de la machine

`flutter doctor -v` detecte :

- Flutter 3.38.5 ;
- Android SDK 36.1.0 ;
- Android Emulator 36.2.12 ;
- Android Studio installe ;
- licences Android acceptees ;
- VS Code installe.

Un AVD est deja disponible :

```text
Medium_Phone_API_35
```

## Lancer l'emulateur

```bash
cd apps/mobile
flutter emulators --launch Medium_Phone_API_35
```

Puis verifier :

```bash
flutter devices
```

## Tester depuis VS Code

Extensions recommandees dans `.vscode/extensions.json` :

- Dart ;
- Flutter ;
- Docker.

Configuration de lancement disponible :

```text
LiveAround Mobile (Android Emulator)
```

Cette configuration passe automatiquement :

```text
LIVEAROUND_API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` est l'adresse speciale permettant a l'emulateur Android d'appeler l'API NestJS lancee sur la machine hote.

## Carte interactive

L'application utilise `flutter_map` avec un fond CARTO base sur les donnees OpenStreetMap. Les marqueurs utilisent les coordonnees renvoyees par l'API LiveAround, elles-memes issues de Ticketmaster lorsque `TICKETMASTER_API_KEY` est configuree.

Pour une mise en production, prevoir un fournisseur de tuiles contractualise ou une cle Mapbox/MapTiler/Google Maps selon la strategie cout/licence retenue.

L'app tente de recuperer la position GPS de l'utilisateur. Si la permission est refusee, indisponible, ou si l'emulateur renvoie une position hors France metropolitaine, elle utilise Lyon comme position de demonstration.
