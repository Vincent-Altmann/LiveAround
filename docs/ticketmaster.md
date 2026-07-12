# Integration Ticketmaster

## Source officielle

LiveAround utilise la Discovery API v2 de Ticketmaster :

- endpoint racine : `https://app.ticketmaster.com/discovery/v2/`
- recherche d'evenements : `GET /events.json`
- authentification : query parameter `apikey`

Documentation officielle : <https://developer.ticketmaster.com/products-and-docs/apis/discovery-api/v2/>

## Parametres utilises

L'API LiveAround appelle Ticketmaster avec :

- `classificationName=music` par defaut ;
- `geoPoint` calcule depuis latitude/longitude ;
- `radius` et `unit=km` ;
- `countryCode=FR` par defaut ;
- `locale=fr-fr,*` par defaut ;
- `sort=distance,asc` ;
- `keyword` si l'utilisateur recherche un artiste, une salle ou une ville.

## Configuration locale

Créer `apps/api/.env` :

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgres://livearound:livearound@localhost:5432/livearound
JWT_SECRET=replace-me
TICKETMASTER_API_KEY=your-ticketmaster-key
TICKETMASTER_COUNTRY_CODE=FR
TICKETMASTER_LOCALE=fr-fr,*
FCM_PROJECT_ID=
```

Sans clé Ticketmaster, l'API NestJS retourne les donnees mockees de developpement afin que l'application mobile reste testable.

