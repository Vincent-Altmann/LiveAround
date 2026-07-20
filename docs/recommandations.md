# Recommandations argumentees d'amelioration

Etat au terme de la v0.3.0. Les priorites tiennent compte de la valeur utilisateur, du risque technique et de l'effort estime.

## Priorite haute

1. **Brancher l'envoi push FCM** — Toute la chaine d'alertes existe (opt-in, calcul, anti-spam, persistance, mesure des clics) ; seul l'envoi push manque. *Pourquoi* : les alertes sont le principal levier de retention prevu par le cadrage ; en pull (in-app), leur portee est limitee. *Comment* : projet Firebase, `google-services.json` cote Android, table des jetons d'appareil, implementation `PushSender` avec firebase-admin (~1 jour). *Risque si absent* : promesse produit « recevoir des alertes » incomplete.
2. **Envoi des codes de reinitialisation par email (SMTP)** — Le flux fonctionne mais le code n'est pas achemine a l'utilisateur en production. *Comment* : service transactionnel (Brevo, Mailgun) + module mailer ; le point d'insertion est isole dans `AuthController.forgotPassword`. *Risque si absent* : un utilisateur reel ne peut pas recuperer son compte seul.
3. **Supervision active (Sentry + alerte d'indisponibilite)** — Les logs existent mais personne n'est prevenu d'une panne. *Comment* : SDK Sentry (API et Flutter), sonde externe sur `/health`. Effort faible, gain de fiabilite eleve — prevu par l'architecture initiale.

## Priorite moyenne

4. **Geocodage de ville complet** — La liste embarquee de 40 villes couvre les grandes agglomerations mais pas « un service national » complet. *Comment* : API Adresse (data.gouv.fr, gratuite, sans cle) derriere un endpoint `/geocode` avec cache, en conservant la liste locale comme repli hors-ligne.
5. **Verification d'adresse email a l'inscription** — Renforce la qualite des comptes et conditionne les futurs envois d'emails. A mutualiser avec le chantier SMTP (2).
6. **Internationalisation propre (fichiers ARB)** — Les textes sont codes en dur et sans accents (« Decouvrir », « reessayez »). *Pourquoi* : qualite percue, accents corrects, et ouverture multilingue a cout marginal ensuite. *Comment* : `flutter_intl`/`gen-l10n`, extraction progressive ecran par ecran.
7. **Tests d'integration API (supertest)** — Les 16 tests unitaires couvrent la logique pure ; les guards, DTO et contrats HTTP meriteraient 8-10 tests d'integration (supertest est deja en dependance) + mesure de couverture en CI.

## Priorite basse

8. **Carte : regroupement des marqueurs et bouton « recentrer »** — Utile au-dela de ~50 resultats affiches (package `flutter_map_marker_cluster`).
9. **Mode sombre** — Le theme Material 3 est centralise, l'effort est modere ; benefice confort et accessibilite (photosensibilite).
10. **Pull-to-refresh sur Decouvrir et badge de nouveautes sur la cloche** — Confort ; le rafraichissement existe deja via les filtres.
11. **Publication sur les stores** — Signature de release dediee (keystore), politique de confidentialite publiee, captures et fiches store ; prerequis a un vrai panel d'utilisateurs.

## Dette technique assumee (a surveiller, sans action immediate)

- `LIMIT/OFFSET` pour la pagination du cache PostGIS : suffisant aux volumes actuels ; passer en keyset si le cache depasse ~10 000 concerts actifs.
- Snapshot JSON des favoris (`concert_snapshot`) : pratique et resilient, mais peut diverger de la donnee fraiche ; a rapprocher de la table `concerts` maintenant qu'elle existe.
- Les replis mock cote consultation restent actifs en build de developpement ; verifier a chaque nouvelle fonctionnalite qu'ils n'absorbent pas une erreur qui devrait etre visible (regle du plan qualite).
