# Exemple de probleme resolu en collaboration avec le support client

> Cas traite pendant la phase de recette du MVP (v0.1.0), retranscrit selon le format de ticket du support. Il illustre la boucle complete : signalement utilisateur → diagnostic support → resolution → amelioration produit.

## Ticket SUP-2026-014

| Champ | Valeur |
|---|---|
| Canal | Formulaire de contact (recette utilisateur) |
| Utilisatrice | Testeuse du panel de recette (Angers) |
| Objet | « L'application n'affiche aucun concert» |
| Priorite initiale | Haute (fonction principale percue comme en panne) |

### Message initial de l'utilisatrice

> « Bonjour, j'ai installe LiveAround et cree mon compte, mais l'ecran principal me dit "Aucun concert dans ce rayon" alors qu'il y a plein de concerts a Angers en ce moment. L'application est-elle en panne ? »

### Echange et diagnostic (support)

1. **Question support** : « L'application vous a-t-elle demande l'acces a votre position, et qu'avez-vous repondu ? Que dit la ligne sous "Concerts proches de vous" ? »
2. **Reponse** : « J'ai refuse la localisation, je n'aime pas partager ma position. C'est ecrit "Position par defaut : Lyon, France". Et j'avais regle le rayon sur 5 km. »
3. **Analyse** : comportement conforme mais mal compris — en cas de refus du GPS, l'application se replie sur Lyon ; avec un rayon de 5 km, aucun concert lyonnais « proche d'Angers » evidemment. Le probleme est un defaut de guidage, pas une panne.

### Resolution avec l'utilisatrice

Le support guide : bouton **« Choisir une ville »** → recherche « Angers » → selection. Les concerts angevins s'affichent immediatement, sans jamais activer le GPS. L'utilisatrice confirme la resolution ; le ticket est clos en « resolu — accompagnement ».

### Actions produit issues du ticket

Le ticket a ete requalifie en demande d'amelioration (S3/UX) car le parcours « refus du GPS » laissait l'utilisateur sans guidage :

- le choix manuel de ville est propose **au meme niveau que le GPS** (deux boutons cote a cote sur l'ecran Decouvrir), et non plus seulement en repli implicite ;
- l'etat vide indique explicitement les actions possibles (elargir le rayon, changer de periode, retirer un filtre) ;
- la position affichee distingue clairement « Position par defaut » d'une position choisie ;
- entree correspondante ajoutee a la rubrique « Un probleme ? » du [manuel d'utilisation](manuel-utilisation.md).

### Enseignement

Un refus de permission n'est pas un cas d'erreur mais un parcours de premiere classe : l'alternative doit etre visible, pas seulement disponible. Ce principe est desormais applique a tout nouveau parcours dependant d'une permission.
