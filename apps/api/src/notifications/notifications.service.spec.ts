import { buildAlertContent } from './notifications.service';

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
