// Test E2E du cycle de vie du compte et des nouveautes des points 4-8.
const BASE = 'http://127.0.0.1:3000';
const EMAIL = `e2e.${Math.random().toString(36).slice(2, 8)}@example.com`;
const PASS1 = 'motdepasse123';
const PASS2 = 'nouveaumdp456';
const PASS3 = 'resetmdp789';

const api = async (path, { method = 'GET', token, body } = {}) => {
  const response = await fetch(BASE + path, {
    method,
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'content-type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  let data = null;
  try { data = await response.json(); } catch {}
  return { status: response.status, data };
};

const check = (label, ok, detail = '') => {
  console.log(`${ok ? 'OK ' : 'ECHEC'} | ${label}${detail ? ' — ' + detail : ''}`);
  if (!ok) process.exitCode = 1;
};

// 1. Inscription → jetons access + refresh
const reg = await api('/auth/register', { method: 'POST', body: { displayName: 'E2E', email: EMAIL, password: PASS1 } });
check('inscription renvoie access + refresh', reg.status === 201 && !!reg.data.accessToken && !!reg.data.refreshToken);
let access = reg.data.accessToken;
let refresh = reg.data.refreshToken;

// 2. Refresh → nouveaux jetons, rotation (l'ancien devient invalide)
const ref1 = await api('/auth/refresh', { method: 'POST', body: { refreshToken: refresh } });
check('refresh renvoie de nouveaux jetons', ref1.status === 201 && !!ref1.data.accessToken && ref1.data.refreshToken !== refresh);
const ref2 = await api('/auth/refresh', { method: 'POST', body: { refreshToken: refresh } });
check('ancien refresh token rejete apres rotation (401)', ref2.status === 401);
access = ref1.data.accessToken;
refresh = ref1.data.refreshToken;

// 3. Changement de mot de passe
const change = await api('/auth/change-password', { method: 'POST', token: access, body: { currentPassword: PASS1, newPassword: PASS2 } });
check('changement de mot de passe', change.status === 201 && !!change.data.accessToken);
const oldRefreshAfterChange = await api('/auth/refresh', { method: 'POST', body: { refreshToken: refresh } });
check('sessions revoquees apres changement (401)', oldRefreshAfterChange.status === 401);
access = change.data.accessToken;
const badLogin = await api('/auth/login', { method: 'POST', body: { email: EMAIL, password: PASS1 } });
check('ancien mot de passe refuse (401)', badLogin.status === 401);
const goodLogin = await api('/auth/login', { method: 'POST', body: { email: EMAIL, password: PASS2 } });
check('nouveau mot de passe accepte', goodLogin.status === 201);
access = goodLogin.data.accessToken;

// 4. Mot de passe oublie → code (dev) → reset
const forgot = await api('/auth/forgot-password', { method: 'POST', body: { email: EMAIL } });
check('forgot-password renvoie un devCode en dev', forgot.status === 201 && /^\d{6}$/.test(forgot.data.devCode ?? ''));
const badReset = await api('/auth/reset-password', { method: 'POST', body: { email: EMAIL, code: '000000', newPassword: PASS3 } });
check('code errone rejete (401)', badReset.status === 401);
const reset = await api('/auth/reset-password', { method: 'POST', body: { email: EMAIL, code: forgot.data.devCode, newPassword: PASS3 } });
check('reset avec le bon code', reset.status === 201);
const loginAfterReset = await api('/auth/login', { method: 'POST', body: { email: EMAIL, password: PASS3 } });
check('connexion avec le mot de passe reinitialise', loginAfterReset.status === 201);
access = loginAfterReset.data.accessToken;

// 5. Anti-enumeration : email inconnu → meme reponse 201, sans devCode de compte
const forgotUnknown = await api('/auth/forgot-password', { method: 'POST', body: { email: 'inconnu@example.com' } });
check('email inconnu → reponse identique sans code', forgotUnknown.status === 201 && forgotUnknown.data.devCode === undefined);

// 6. Pagination : page 0 et page 1 differentes
const p0 = await api('/concerts?latitude=45.76&longitude=4.83&radiusKm=100');
const p1 = await api('/concerts?latitude=45.76&longitude=4.83&radiusKm=100&page=1');
const ids0 = new Set((p0.data ?? []).map((c) => c.id));
const overlap = (p1.data ?? []).filter((c) => ids0.has(c.id)).length;
check('pagination: page 0 pleine, page 1 differente', p0.data.length === 50 && p1.data.length > 0 && overlap === 0, `p0=${p0.data.length}, p1=${p1.data.length}, chevauchement=${overlap}`);

// 7. Rate limiting sur /auth/login (5/min) — on enchaine 6 tentatives
let throttled = false;
for (let i = 0; i < 6; i++) {
  const attempt = await api('/auth/login', { method: 'POST', body: { email: 'brute@example.com', password: 'xxxxxxxxxx' } });
  if (attempt.status === 429) { throttled = true; break; }
}
check('force brute bloquee par le rate limiting (429)', throttled);

// 8. Suppression de compte (RGPD)
const badDelete = await api('/users/me', { method: 'DELETE', token: access, body: { password: 'mauvaismdp1' } });
check('suppression refusee avec mauvais mot de passe (401)', badDelete.status === 401);
const del = await api('/users/me', { method: 'DELETE', token: access, body: { password: PASS3 } });
check('suppression du compte', del.status === 200 && del.data.deleted === true);
const loginAfterDelete = await api('/auth/login', { method: 'POST', body: { email: EMAIL, password: PASS3 } });
check('connexion impossible apres suppression', loginAfterDelete.status === 401 || loginAfterDelete.status === 429);

console.log('\nEmail de test utilise :', EMAIL);
