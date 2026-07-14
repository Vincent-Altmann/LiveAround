import {
  mapGenresToClassificationName,
  toDisplayGenre,
} from './ticketmaster.client';

describe('mapGenresToClassificationName', () => {
  it('retourne music sans genre selectionne', () => {
    expect(mapGenresToClassificationName([])).toBe('music');
  });

  it('convertit les libelles francais vers les classifications Ticketmaster', () => {
    expect(mapGenresToClassificationName(['Electro'])).toBe('Electronic');
    expect(mapGenresToClassificationName(['Classique'])).toBe('Classical');
    expect(mapGenresToClassificationName(['Rap'])).toBe('Hip-Hop/Rap');
  });

  it('combine plusieurs genres et conserve les inconnus tels quels', () => {
    expect(mapGenresToClassificationName(['Rock', 'Electro', 'Blues'])).toBe(
      'Rock,Electronic,Blues',
    );
  });
});

describe('toDisplayGenre', () => {
  it('reconvertit les classifications vers les libelles de l application', () => {
    expect(toDisplayGenre('Electronic')).toBe('Electro');
    expect(toDisplayGenre('Hip-Hop/Rap')).toBe('Rap');
    expect(toDisplayGenre('Classical')).toBe('Classique');
  });

  it('laisse les genres inconnus inchanges', () => {
    expect(toDisplayGenre('Jazz')).toBe('Jazz');
  });
});
