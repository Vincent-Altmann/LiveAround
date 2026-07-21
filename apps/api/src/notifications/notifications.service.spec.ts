import {
  buildAlertContent,
  buildReminderContent,
} from './notifications.service';

describe('buildAlertContent', () => {
  it('construit un titre avec genre et distance arrondie', () => {
    const content = buildAlertContent({
      artist: 'Nora Blue',
      genre: 'Pop',
      starts_at: '2026-08-14T20:00:00.000Z',
      venue_name: 'Radiant-Bellevue',
      venue_city: 'Caluire-et-Cuire',
      distance_km: 6.4,
    });

    expect(content.title).toBe('Nouveau concert Pop a 6 km');
    expect(content.body).toContain('Nora Blue');
    expect(content.body).toContain('Radiant-Bellevue, Caluire-et-Cuire');
    expect(content.body).toContain('14 ao');
  });

  it('affiche moins de 1 km pour les concerts tres proches', () => {
    const content = buildAlertContent({
      artist: 'Kobalt',
      genre: 'Rap',
      starts_at: '2026-08-14T20:00:00.000Z',
      venue_name: 'Halle Tony Garnier',
      venue_city: 'Lyon',
      distance_km: 0.4,
    });

    expect(content.title).toBe('Nouveau concert Rap a moins de 1 km');
  });

  it('omet la distance quand elle est inconnue', () => {
    const content = buildAlertContent({
      artist: 'Kobalt',
      genre: 'Rap',
      starts_at: '2026-08-14T20:00:00.000Z',
      venue_name: 'Halle Tony Garnier',
      venue_city: 'Lyon',
      distance_km: 'invalide',
    });

    expect(content.title).toBe('Nouveau concert Rap');
  });
});

describe('buildReminderContent', () => {
  const inDays = (days: number) => {
    const date = new Date();
    date.setDate(date.getDate() + days);
    date.setHours(20, 30, 0, 0);
    return date;
  };

  it('annonce un concert le jour meme', () => {
    const content = buildReminderContent({
      artist: 'Nora Blue',
      starts_at: inDays(0),
      venue_name: 'Radiant-Bellevue',
      venue_city: 'Caluire-et-Cuire',
    });

    expect(content.title).toContain("c'est aujourd'hui");
    expect(content.body).toContain('Nora Blue');
    expect(content.body).toContain('Radiant-Bellevue, Caluire-et-Cuire');
  });

  it('annonce un concert le lendemain', () => {
    const content = buildReminderContent({
      artist: 'Kobalt',
      starts_at: inDays(1),
      venue_name: 'Halle Tony Garnier',
      venue_city: 'Lyon',
    });

    expect(content.title).toContain("c'est demain");
  });

  it('annonce un concert dans quelques jours', () => {
    const content = buildReminderContent({
      artist: 'Kobalt',
      starts_at: inDays(3),
      venue_name: 'Halle Tony Garnier',
      venue_city: 'Lyon',
    });

    expect(content.title).toContain('dans 3 jours');
  });

  it('reste lisible sans artiste ni salle (snapshot incomplet)', () => {
    const content = buildReminderContent({
      artist: null,
      starts_at: inDays(2),
      venue_name: null,
      venue_city: null,
    });

    expect(content.body).toContain('Concert en favori');
    expect(content.body).toContain('lieu a confirmer');
  });
});
