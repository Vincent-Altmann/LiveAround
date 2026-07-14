import { storedRowToConcert } from './concert-store.service';

describe('storedRowToConcert', () => {
  const baseRow = {
    external_id: 'tm-123',
    artist: 'Nora Blue',
    title: 'Fragments acoustiques',
    genre: 'Pop',
    starts_at: '2026-07-27T19:45:00.000Z',
    price_from: '28.00',
    ticket_url: 'https://tickets.example/tm-123',
    description: 'Une soiree pop.',
    image_url: 'https://images.example/tm-123.jpg',
    venue_name: 'Radiant-Bellevue',
    venue_city: 'Caluire-et-Cuire',
    venue_address: '1 rue Jean Moulin',
    latitude: '45.7958',
    longitude: '4.8446',
    distance_km: '6.4321',
  };

  it('convertit une ligne SQL en ConcertModel', () => {
    const concert = storedRowToConcert(baseRow);

    expect(concert.id).toBe('tm-123');
    expect(concert.priceFrom).toBe(28);
    expect(concert.venue.latitude).toBeCloseTo(45.7958);
    expect(concert.venue.longitude).toBeCloseTo(4.8446);
    expect(concert.distanceKm).toBe(6.4);
    expect(concert.imageUrl).toBe('https://images.example/tm-123.jpg');
    expect(concert.source).toBe('cache');
  });

  it('gere les valeurs nulles (prix, image, adresse)', () => {
    const concert = storedRowToConcert({
      ...baseRow,
      price_from: null,
      ticket_url: null,
      description: null,
      image_url: null,
      venue_address: null,
      distance_km: null,
    });

    expect(concert.priceFrom).toBe(0);
    expect(concert.ticketUrl).toBe('');
    expect(concert.imageUrl).toBeUndefined();
    expect(concert.venue.address).toBe('');
    expect(concert.distanceKm).toBeUndefined();
  });
});
