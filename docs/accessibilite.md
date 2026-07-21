# Accessibilite

Mesures mises en œuvre pour permettre l'acces a l'application aux personnes en situation de handicap, en reference aux criteres WCAG 2.1 / RGAA applicables a une application mobile.

## Mesures en place

### Lecteurs d'ecran (deficience visuelle)

- **Tout element interactif est nomme** : les boutons-icones (favori, alertes, signalement, localisation) portent un libelle annonce par TalkBack ; les reperes de la carte sont exposes comme boutons avec un libelle explicite (« Concert de X a Y, ouvrir la fiche ») ; la position de l'utilisateur est annoncee (« Votre position » / « Position par defaut : Lyon »).
- **Images** : les photos d'artistes portent un libelle (« Photo de X ») ; l'image d'en-tete de la fiche concert, purement decorative, est exclue de la lecture pour eviter les doublons.
- **Langue** : l'application declare la locale francaise (`flutter_localizations`) — les composants systeme (selecteur de dates, actions) sont annonces en francais, et la synthese vocale utilise la bonne langue.
- **Etats** : les puces de filtre (genres, dates, favoris) utilisent les composants Material qui annoncent leur etat selectionne ; le reglage du rayon annonce sa valeur (« 50 km ») pendant la manipulation.

### Vision (contrastes, tailles)

- Palette a fort contraste : texte principal `#15171A` sur fond `#F7F4EF` (ratio ≈ 15:1) ; les textes secondaires ont ete releves (opacite ≥ 0,66, ratio ≥ 4,5:1 — niveau AA) lors de la passe d'accessibilite.
- L'information n'est jamais portee par la seule couleur : l'etat favori combine icone pleine/vide et libelle ; les alertes non lues combinent couleur, icone et graisse du texte.
- **Tailles de texte du systeme respectees** : aucune limitation du facteur d'agrandissement ; les ecrans defilent et s'adaptent.

### Motricite

- Cibles tactiles conformes au minimum de 48 dp (boutons Material, `IconButton`, reperes de carte de 48 px).
- Aucune interaction ne repose sur un geste complexe : tout est accessible au toucher simple ; le defilement infini se declenche automatiquement, sans geste specifique.
- Pas de contrainte de temps : aucune action ne doit etre effectuee dans un delai.

### Cognition

- Parcours simple et constant (3 onglets), libelles explicites, messages d'erreur en langage clair avec action de reprise (« Reessayer »).
- Formulaires : libelles permanents, validation avec messages precis sous le champ concerne.

## Verification

- Analyse statique Flutter (`flutter_lints`) sans avertissement d'accessibilite ;
- parcours des ecrans principaux avec TalkBack sur emulateur (annonce des boutons, images et reperes) ;
- controle des ratios de contraste de la palette (WebAIM Contrast Checker).

## Limites connues et pistes

- La **carte** reste d'usage essentiellement visuel : l'information est toujours disponible sous forme de liste (meme contenu), qui constitue l'alternative accessible.
- Test avec de vrais utilisateurs de lecteurs d'ecran non realise — recommande avant une publication sur les stores.
- Un mode sombre et un mode « reduction des animations » sont proposes dans les [recommandations](recommandations.md).
