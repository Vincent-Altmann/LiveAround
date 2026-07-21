# Manuel d'utilisation

LiveAround est une application mobile de decouverte de concerts a proximite, partout en France.

## 1. Creer un compte et se connecter

![Ecran de connexion](captures/01-connexion.png)

Au premier lancement, l'application propose de se connecter ou de creer un compte (onglet **Creer** : nom, e-mail, mot de passe d'au moins 8 caracteres). La session est ensuite conservee : l'application s'ouvre directement sur la decouverte lors des lancements suivants.

**Mot de passe oublie ?** Sur l'ecran de connexion, le lien « Mot de passe oublie ? » permet de recevoir un code a 6 chiffres puis de definir un nouveau mot de passe.

## 2. Decouvrir les concerts

![Ecran Decouvrir](captures/02-decouvrir.png)

L'ecran **Decouvrir** liste les concerts proches, tries par distance, avec une carte interactive (chaque repere ouvre la fiche du concert).

- **Position** : « Ma position » utilise le GPS (avec votre consentement) ; « Choisir une ville » permet de selectionner manuellement une grande ville francaise — aucun GPS requis.
- **Recherche** : par artiste, salle ou ville.
- **Filtres** : genres musicaux (plusieurs choix possibles), periode (aujourd'hui, ce week-end, 7 jours, dates libres) et rayon (5 a 120 km).
- La liste **se complete automatiquement** en defilant vers le bas.

![Liste des concerts](captures/03-liste-concerts.png)

## 3. Fiche concert et billetterie

![Fiche concert](captures/05-fiche-concert.png)

La fiche presente l'artiste, la date et l'heure, la salle localisee sur carte, la distance et le prix. Le bouton **Billetterie** ouvre la page d'achat officielle dans le navigateur. Le cœur ajoute le concert aux **favoris** ; le drapeau permet de **signaler une information incorrecte** (l'equipe est notifiee).

## 4. Favoris

L'onglet **Favoris** regroupe les concerts sauvegardes, conserves avec votre compte (vous les retrouvez apres reconnexion ou changement d'appareil).

## 5. Alertes personnalisees

![Centre d'alertes](captures/04-alertes.png)

Activez « Alertes concerts » dans votre **Profil** : des qu'un nouveau concert correspondant a vos genres et votre rayon est detecte pres de votre derniere position de recherche, une alerte apparait dans le centre d'alertes (cloche en haut de l'ecran Decouvrir), limitee a 3 par jour. Toucher une alerte ouvre la fiche du concert.

Activez aussi « **Rappels de favoris** » pour etre prevenu quand un concert que vous avez mis en favoris approche (moins de 3 jours avant la date) — un seul rappel par concert, pour ne pas manquer une sortie oubliee. Les rappels apparaissent dans le meme centre d'alertes avec une icone calendrier.

## 6. Profil et compte

L'onglet **Profil** permet de modifier :

- nom et e-mail ;
- genres preferes et rayon favori (appliques automatiquement a la decouverte et aux alertes) ;
- l'activation des alertes et des rappels de favoris ;
- la **securite** : changement de mot de passe, ou **suppression definitive du compte** (confirmee par mot de passe — profil, favoris et alertes sont alors effaces).

## Accessibilite

L'application prend en charge les lecteurs d'ecran (TalkBack) : les boutons, images et reperes de carte sont annonces en francais ; les tailles de texte du systeme sont respectees. Voir [accessibilite.md](accessibilite.md).

## Un probleme ?

- « Aucun concert dans ce rayon » : elargissez le rayon, retirez un filtre de genre ou de date, ou verifiez la ville selectionnee.
- « Serveur injoignable » : verifiez votre connexion internet, puis reessayez.
- Donnee incorrecte sur un concert : utilisez le bouton de signalement de la fiche.
