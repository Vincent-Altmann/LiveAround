interface CacheEntry<T> {
  value: T;
  expiresAt: number;
}

/**
 * Cache memoire borne avec expiration : evite d'appeler Ticketmaster a
 * chaque requete (quota ~5 req/s et 5000 req/jour) tout en gardant une
 * empreinte memoire fixe grace a une eviction LRU.
 */
export class TtlCache<T> {
  private readonly entries = new Map<string, CacheEntry<T>>();

  constructor(
    private readonly ttlMs: number,
    private readonly maxEntries: number,
  ) {}

  get(key: string): T | undefined {
    const entry = this.entries.get(key);
    if (!entry) return undefined;

    if (Date.now() > entry.expiresAt) {
      this.entries.delete(key);
      return undefined;
    }

    // Reinsertion pour conserver l'ordre d'acces (LRU).
    this.entries.delete(key);
    this.entries.set(key, entry);
    return entry.value;
  }

  set(key: string, value: T) {
    if (this.entries.has(key)) {
      this.entries.delete(key);
    } else if (this.entries.size >= this.maxEntries) {
      const oldestKey = this.entries.keys().next().value;
      if (oldestKey !== undefined) this.entries.delete(oldestKey);
    }

    this.entries.set(key, { value, expiresAt: Date.now() + this.ttlMs });
  }

  get size() {
    return this.entries.size;
  }
}
