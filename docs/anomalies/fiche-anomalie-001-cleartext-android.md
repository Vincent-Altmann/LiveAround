# Fiche d'anomalie 001 — Appels API bloques par la politique cleartext d'Android

| Champ | Valeur |
|---|---|
| Identifiant | ANO-001 |
| Date de detection | 13/07/2026 (audit du MVP) |
| Detecteur | Revue technique (audit de code) |
| Composant | Application mobile Android + replis silencieux (mobile et API) |
| Severite | S1 — bloquant (la fonction cœur n'utilisait jamais les donnees reelles) |
| Statut | Corrigee et verifiee — livree en v0.1.0 (PR #1) |

## Symptome observe

L'application semblait fonctionner normalement mais n'affichait que les 6 concerts de demonstration lyonnais, jamais les concerts reels de Ticketmaster. Aucun message d'erreur, ni a l'ecran ni dans les logs applicatifs mobiles. Le probleme pouvait passer totalement inapercu en demonstration.

## Reproduction

1. Demarrer l'API locale et la base ; verifier avec `curl` que `GET /concerts` renvoie des concerts Ticketmaster reels.
2. Lancer l'application sur un emulateur Android API 28+ (`flutter run`).
3. Se connecter et observer la liste : donnees de demonstration au lieu des donnees reelles.

## Diagnostic (cause racine)

Deux causes superposees :

1. **Cause declenchante** : depuis Android 9, le trafic HTTP en clair est bloque par defaut. L'application appelait `http://10.0.2.2:3000` sans autorisation cleartext dans le manifest → chaque requete echouait immediatement au niveau systeme.
2. **Cause aggravante (defaut de conception)** : la couche d'acces aux donnees intercepait *toutes* les exceptions et basculait silencieusement sur le repository de demonstration — y compris pour l'authentification, ou un mock acceptait n'importe quel mot de passe. La panne etait donc invisible.

## Correctif

- `android:usesCleartextTraffic="true"` ajoute au **manifest de debug uniquement** (`apps/mobile/android/app/src/debug/AndroidManifest.xml`) : les builds de release restent soumis au blocage — la production doit etre en HTTPS.
- Suppression des replis silencieux sur le chemin d'authentification : le login/l'inscription echouent desormais explicitement (« Serveur injoignable », « Identifiants invalides »...) ; les replis de consultation restants sont journalises ; un mode demonstration explicite (`--dart-define LIVEAROUND_DEMO_MODE=true`) remplace l'usage accidentel des mocks.

## Verification

- Connexion reelle depuis l'emulateur avec un compte persiste en base (parcours complet verifie a l'ecran) ;
- liste affichant 50 concerts Ticketmaster reels ;
- scenario de recette M8 ajoute (panne simulee → comportement explicite).

## Mesures d'evitement

- Regle de qualite ajoutee : **toute bascule de repli doit etre journalisee ; l'authentification ne se replie jamais** ([qualite-performance.md](../qualite-performance.md)).
- Ce cas a motive l'etat d'erreur visible avec bouton « Reessayer » sur les ecrans de liste.
