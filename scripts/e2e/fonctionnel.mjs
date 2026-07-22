// Batterie fonctionnelle : concerts, filtres, cache, favoris, alertes, rappels, signalement.
const BASE = 'http://127.0.0.1:3000';

const api = async (path, { method = 'GET', token, body } = {}) => {
  const start = Date.now();
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
  return { status: response.status, data, ms: Date.now() - start };
};

const check = (label, ok, detail = '') => {
  console.log(`${ok ? 'OK ' : 'ECHEC'} | ${label}${detail ? ' — ' + detail : ''}`);
  if (!ok) process.exitCode = 1;
};

// Connexion avec le compte de test permanent
const login = await api('/auth/login', { method: 'POST', body: { email: 'vince.test@example.com', password: 'motdepasse123' } });
check('connexion compte de test', login.status === 201);
const token = login.data.accessToken;

// 1. Recherche Ticketmaster reelle
const search1 = await api('/concerts?latitude=45.76&longitude=4.83&radiusKm=50', { token });
check('recherche concerts reels', search1.status === 200 && search1.data.length === 50, `${search1.data.length} concerts en ${search1.ms} ms`);
const withImages = search1.data.filter(c => c.imageUrl).length;
check('images presentes sur une partie des concerts', withImages > 0, `${withImages}/50 avec image`);

// 2. Cache : second appel identique nettement plus rapide
const search2 = await api('/concerts?latitude=45.76&longitude=4.83&radiusKm=50', { token });
check('cache de recherche actif', search2.ms < search1.ms && search2.ms < 200, `${search1.ms} ms -> ${search2.ms} ms`);

// 3. Filtre par genre (mapping Ticketmaster)
const electro = await api('/concerts?latitude=45.76&longitude=4.83&radiusKm=100&genres=Electro', { token });
check('filtre genre Electro', electro.status === 200 && electro.data.length > 0, `${electro.data.length} resultats`);

// 4. Filtre par dates (fenetre 30 jours)
const from = new Date().toISOString();
const to = new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString();
const dated = await api(`/concerts?latitude=45.76&longitude=4.83&radiusKm=100&from=${from}&to=${to}`, { token });
const allInWindow = dated.data.every(c => new Date(c.startsAt) >= new Date(Date.now() - 24 * 3600 * 1000) && new Date(c.startsAt) <= new Date(to));
check('filtre par dates respecte la fenetre', dated.status === 200 && dated.data.length > 0 && allInWindow, `${dated.data.length} concerts sous 30 jours`);

// 5. Favoris : bascule aller-retour
const target = search1.data.find(c => !c.isFavorite);
const favOn = await api(`/concerts/${target.id}/favorite`, { method: 'POST', token });
check('ajout aux favoris', favOn.status === 201 && favOn.data.isFavorite === true, target.artist);
const favList = await api('/users/me/favorites', { token });
check('favori present dans la liste', favList.data.some(c => c.id === target.id));
const favOff = await api(`/concerts/${target.id}/favorite`, { method: 'POST', token });
check('retrait des favoris', favOff.data.isFavorite === false);

// 6. Detail d'un concert
const detail = await api(`/concerts/${target.id}`, { token });
check('fiche concert', detail.status === 200 && detail.data.venue?.latitude !== undefined);

// 7. Signalement persiste
const report = await api(`/concerts/${target.id}/report`, { method: 'POST', token, body: { reason: 'Test batterie de recette : donnee a verifier' } });
check('signalement enregistre', report.status === 201 && !!report.data.id, 'id=' + String(report.data.id).slice(0, 8));

// 8. Notifications : les deux types presents, rappel en tete
const notifs = await api('/users/me/notifications', { token });
const kinds = new Set(notifs.data.map(n => n.kind));
check('centre de notifications', notifs.status === 200 && notifs.data.length > 0, `${notifs.data.length} notifications`);
check('rappel de favori present et type', kinds.has('favorite_reminder') && kinds.has('new_concert'), [...kinds].join(', '));

// 9. Preferences completes (les 2 opt-in)
const prefs = await api('/users/me/preferences', { method: 'PATCH', token, body: { preferredGenres: ['Rock', 'Jazz'], preferredRadiusKm: 60, notificationOptIn: true, favoriteRemindersOptIn: true } });
check('preferences sauvegardees', prefs.data.preferredGenres.length === 2 && prefs.data.preferredRadiusKm === 60 && prefs.data.notificationOptIn === true && prefs.data.favoriteRemindersOptIn === true);

// 10. Profil coherent
const me = await api('/users/me', { token });
check('profil expose toutes les preferences', me.data.favoriteRemindersOptIn === true && me.data.favoritesCount !== undefined, `favoris=${me.data.favoritesCount}`);

// 11. Swagger disponible
const docs = await fetch(BASE + '/docs').then(r => r.status);
check('documentation Swagger accessible', docs === 200);
