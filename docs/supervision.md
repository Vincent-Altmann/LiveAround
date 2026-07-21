# Systeme de supervision

## Ce qui est surveille

| Signal | Source | Ce qu'il revele |
|---|---|---|
| `GET /health` (statut + horodatage) | endpoint public de l'API | disponibilite de l'API ; sonde utilisee par le HEALTHCHECK Docker et adaptee a un uptime-checker externe |
| `pg_isready` | healthcheck du conteneur PostGIS | disponibilite de la base ; conditionne le demarrage de l'API en production (`depends_on: service_healthy`) |
| Logs applicatifs NestJS | stdout des conteneurs (`docker compose logs`) | voir tableau ci-dessous |

## Evenements journalises par l'API

Chaque module journalise avec son contexte (logger NestJS) :

| Contexte | Evenements | Niveau |
|---|---|---|
| `DatabaseService` | migrations appliquees / differees, base indisponible (mode degrade) | log / warn |
| `ConcertsService` | bascule Ticketmaster → cache PostGIS → demo | warn |
| `TicketmasterClient` | echecs HTTP Ticketmaster (statut + extrait de reponse) | warn |
| `ConcertStore` | volumes ingeres, purge des concerts passes | log |
| `NotificationsService` / `InAppPushSender` | alertes creees, contenu des alertes, echecs de balayage | log / warn |
| `UsersService` | echecs d'operations de compte (sans donnees sensibles) | error |
| `AuthController` | generation des codes de reinitialisation (en attendant l'envoi SMTP) | log |

Principe : **aucune panne silencieuse** — toute bascule sur un mecanisme de repli laisse une trace ; les mots de passe, jetons et codes ne sont jamais journalises en production.

## Indicateurs metier surveilles en base

```sql
-- Volume et fraicheur du cache concerts
SELECT COUNT(*), MAX(source_updated_at) FROM concerts;
-- Activite des alertes (pertinence : taux de clic)
SELECT COUNT(*) AS envoyees, COUNT(clicked_at) AS cliquees FROM user_notifications;
-- Signalements utilisateurs en attente
SELECT COUNT(*) FROM concert_reports WHERE status = 'open';
```

## Limites et cible

La supervision actuelle est passive (sondes + logs). Cible identifiee dans les [recommandations](recommandations.md) : centralisation des erreurs avec **Sentry** (prevu par l'architecture) cote API et mobile, et alerte automatique (mail/Slack) sur echec du healthcheck via l'hebergeur ou un service type UptimeRobot.
