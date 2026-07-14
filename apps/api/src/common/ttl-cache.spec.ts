import { TtlCache } from './ttl-cache';

describe('TtlCache', () => {
  afterEach(() => {
    jest.useRealTimers();
  });

  it('retourne la valeur avant expiration', () => {
    const cache = new TtlCache<string>(1000, 10);
    cache.set('a', 'valeur');
    expect(cache.get('a')).toBe('valeur');
  });

  it('expire les entrees apres le TTL', () => {
    jest.useFakeTimers({ now: 0 });
    const cache = new TtlCache<string>(1000, 10);
    cache.set('a', 'valeur');

    jest.setSystemTime(1001);
    expect(cache.get('a')).toBeUndefined();
    expect(cache.size).toBe(0);
  });

  it('borne le nombre d entrees en evincant la plus ancienne', () => {
    const cache = new TtlCache<number>(60000, 2);
    cache.set('a', 1);
    cache.set('b', 2);
    cache.set('c', 3);

    expect(cache.size).toBe(2);
    expect(cache.get('a')).toBeUndefined();
    expect(cache.get('b')).toBe(2);
    expect(cache.get('c')).toBe(3);
  });

  it('rafraichit l ordre LRU a la lecture', () => {
    const cache = new TtlCache<number>(60000, 2);
    cache.set('a', 1);
    cache.set('b', 2);
    cache.get('a');
    cache.set('c', 3);

    expect(cache.get('a')).toBe(1);
    expect(cache.get('b')).toBeUndefined();
  });
});
