# Synthese du cadrage

## Contexte

PulseEvent SAS souhaite proposer LiveAround, une application mobile nationale qui rend visibles les concerts proches de l'utilisateur partout en France.

La valeur attendue n'est pas une simple liste d'evenements : LiveAround doit devenir une plateforme de recommandation locale, fiable, personnalisee et compatible avec les contraintes de donnees mobiles.

## Besoin exprime

- Voir les concerts proches.
- Filtrer par date, genre et distance.
- Recevoir des alertes.
- Acceder a la billetterie.

## Besoin reel

- Centraliser les donnees concerts.
- Qualifier et normaliser les donnees evenementielles.
- Personnaliser l'experience utilisateur.
- Gerer un service national tout en conservant une logique de proximite.

## Enjeux prioritaires

- Qualite et fraicheur des donnees concerts.
- Consentement et minimisation des donnees de geolocalisation.
- Adoption utilisateur via une experience mobile simple.
- Dependances aux API externes.
- Viabilite economique via affiliation, partenariats et mise en avant encadree.

## Stack recommandee par le cadrage

- Flutter pour le mobile Android/iOS.
- NestJS pour l'API backend.
- PostgreSQL + PostGIS pour les recherches geospatiales.
- Firebase Cloud Messaging pour les notifications.
- API concerts + partenariats + cache interne pour la donnee.

