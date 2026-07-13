import { distanceKm } from './geo.util';

describe('distanceKm', () => {
  it('retourne 0 pour un meme point', () => {
    expect(distanceKm(45.764, 4.8357, 45.764, 4.8357)).toBe(0);
  });

  it('calcule la distance Lyon-Paris a environ 392 km', () => {
    const distance = distanceKm(45.764, 4.8357, 48.8566, 2.3522);
    expect(distance).toBeGreaterThan(380);
    expect(distance).toBeLessThan(400);
  });
});
