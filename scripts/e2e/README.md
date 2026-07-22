# Scripts de verification de bout en bout

Executes contre l'API reelle (demarree avec sa base) avant chaque release.

```bash
# API demarree sur http://127.0.0.1:3000 (voir docs/developpement.md)
node scripts/e2e/cycle-de-vie-compte.mjs   # 17 controles : compte, jetons, securite
node scripts/e2e/fonctionnel.mjs           # 16 controles : concerts, favoris, alertes
```

Le second script utilise le compte de test `vince.test@example.com` /
`motdepasse123` (a creer via /auth/register si absent). Chaque ligne `OK |`
correspond a un controle du cahier de recettes (docs/cahier-recettes.md).
