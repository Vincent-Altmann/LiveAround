# Cahier de recettes

Scenarios de recette de la version v0.3.0, executes sur emulateur Android (Medium Phone API 35) avec l'API locale, la base PostGIS Docker et la cle Ticketmaster reelle. Les scenarios A sont automatises dans le script E2E (17 controles) rejouable a chaque livraison ; les scenarios M ont ete deroules manuellement sur l'emulateur.

Statuts : ✅ conforme — ❌ non conforme — ⏳ a rejouer.

## 1. Compte et session

| Id | Scenario | Etapes | Resultat attendu | Statut |
|---|---|---|---|---|
| A1 | Creation de compte | POST /auth/register (nom, email, mdp >= 8) | 201, profil + accessToken + refreshToken ; compte present en base | ✅ |
| A2 | Email deja utilise | Reinscrire le meme email | 409 « Un compte existe deja avec cet email » | ✅ |
| A3 | Connexion valide | POST /auth/login | 201, jetons emis | ✅ |
| A4 | Mauvais mot de passe | login avec mdp errone | 401, message generique (pas d'indice) | ✅ |
| A5 | Renouvellement de session | POST /auth/refresh avec le refreshToken | 201, nouveaux jetons ; l'ancien refresh est revoque (rejouer → 401) | ✅ |
| A6 | Changement de mot de passe | change-password avec l'actuel puis reconnexion | ancien mdp refuse, nouveau accepte, autres sessions revoquees | ✅ |
| A7 | Mot de passe oublie | forgot-password → code 6 chiffres → reset-password | code errone refuse ; bon code accepte ; connexion avec le nouveau mdp | ✅ |
| A8 | Anti-enumeration | forgot-password avec email inconnu | reponse identique au cas nominal, sans code | ✅ |
| A9 | Suppression de compte | DELETE /users/me avec mot de passe | mauvais mdp → 401 ; bon mdp → compte supprime, connexion impossible | ✅ |
| A10 | Force brute | 6 tentatives de connexion en < 1 min | 429 a partir de la 6e | ✅ |
| M1 | Session restauree | Fermer/rouvrir l'application | arrivee directe sur Decouvrir sans reconnexion | ✅ |
| M2 | Acces proteges | GET /users/me sans jeton ou jeton falsifie | 401 | ✅ |

## 2. Decouverte des concerts

| Id | Scenario | Etapes | Resultat attendu | Statut |
|---|---|---|---|---|
| M3 | Liste a proximite | Ouvrir Decouvrir (position Lyon) | concerts reels Ticketmaster tries par distance, carte avec reperes | ✅ |
| M4 | Filtre par genre | Selectionner « Electro » | resultats du genre correspondant (mapping vers les classifications Ticketmaster) | ✅ |
| A11 | Filtre par date | from/to sur 7 jours | uniquement des concerts dans la fenetre | ✅ |
| M5 | Ville manuelle | « Choisir une ville » → Paris | resultats et carte recentres sur Paris, sans GPS | ✅ |
| M6 | Refus du GPS | Refuser la permission de localisation | repli annonce (« Position par defaut : Lyon ») + choix de ville propose | ✅ |
| A12 | Pagination | page=0 puis page=1 | 50 resultats par page, aucun chevauchement ; defilement infini cote app | ✅ |
| M7 | Recherche | Saisir un nom d'artiste | resultats filtres, un seul appel API apres pause de saisie (debounce) | ✅ |
| M8 | Panne Ticketmaster | Cle API invalide | l'API sert le cache PostGIS (source « cache »), l'app reste fonctionnelle | ✅ |

## 3. Fiche, favoris, signalement

| Id | Scenario | Etapes | Resultat attendu | Statut |
|---|---|---|---|---|
| M9 | Fiche concert | Toucher une carte ou un repere | artiste, date, salle, carte, distance, prix (« Prix NC » si inconnu), image si disponible | ✅ |
| M10 | Billetterie | Bouton Billetterie | ouverture du lien officiel dans le navigateur ; bouton inactif sans lien | ✅ |
| M11 | Favoris persistants | Ajouter un favori, se deconnecter/reconnecter | le favori est conserve avec le compte | ✅ |
| M12 | Signalement | Drapeau sur la fiche | enregistrement en base (table concert_reports) avec l'auteur | ✅ |

## 4. Alertes personnalisees

| Id | Scenario | Etapes | Resultat attendu | Statut |
|---|---|---|---|---|
| M13 | Opt-in requis | Alertes desactivees | aucune alerte generee | ✅ |
| M14 | Generation d'alertes | Opt-in + recherche a Lyon + nouveaux concerts ingeres | alertes correspondant aux genres/rayon, max 3 par 24 h | ✅ |
| M15 | Centre d'alertes | Cloche de l'ecran Decouvrir | liste des alertes, etat lu/non lu, ouverture de la fiche, clic historise | ✅ |

## 5. Regression automatisee

La CI (GitHub Actions) rejoue a chaque commit : analyse statique Flutter, 10 tests mobiles, lint API, build API, 16 tests API. Le pipeline de release rejoue l'ensemble avant toute publication.
