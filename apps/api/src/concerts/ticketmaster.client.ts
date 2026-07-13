import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { ConcertModel } from './concert.model';
import { FindConcertsDto } from './dto/find-concerts.dto';
import { encodeGeoHash } from './geo-hash';
import { distanceKm } from './geo.util';

interface TicketmasterEvent {
  id?: string;
  name?: string;
  url?: string;
  info?: string;
  pleaseNote?: string;
  distance?: number;
  dates?: {
    start?: {
      dateTime?: string;
      localDate?: string;
      localTime?: string;
    };
  };
  priceRanges?: Array<{
    min?: number;
    currency?: string;
  }>;
  images?: Array<{
    url?: string;
    width?: number;
    ratio?: string;
    fallback?: boolean;
  }>;
  classifications?: Array<{
    segment?: { name?: string };
    genre?: { name?: string };
    subGenre?: { name?: string };
  }>;
  _embedded?: {
    venues?: TicketmasterVenue[];
    attractions?: Array<{ name?: string }>;
  };
}

interface TicketmasterVenue {
  name?: string;
  distance?: number;
  units?: string;
  address?: {
    line1?: string;
    line2?: string;
  };
  city?: {
    name?: string;
  };
  location?: {
    latitude?: string;
    longitude?: string;
  };
}

interface TicketmasterSearchResponse {
  _embedded?: {
    events?: TicketmasterEvent[];
  };
}

@Injectable()
export class TicketmasterClient {
  private readonly logger = new Logger(TicketmasterClient.name);
  private readonly baseUrl = 'https://app.ticketmaster.com/discovery/v2';

  constructor(private readonly config: ConfigService) {}

  isEnabled() {
    return Boolean(this.apiKey);
  }

  async searchEvents(query: FindConcertsDto) {
    if (!this.apiKey) return [];

    const url = new URL(`${this.baseUrl}/events.json`);
    url.searchParams.set('apikey', this.apiKey);
    url.searchParams.set('countryCode', this.countryCode);
    url.searchParams.set('locale', this.locale);
    url.searchParams.set(
      'geoPoint',
      encodeGeoHash(query.latitude, query.longitude),
    );
    url.searchParams.set('radius', String(query.radiusKm));
    url.searchParams.set('unit', 'km');
    url.searchParams.set('sort', 'distance,asc');
    url.searchParams.set('size', '50');
    url.searchParams.set('includeTBA', 'no');
    url.searchParams.set('includeTBD', 'no');
    url.searchParams.set(
      'classificationName',
      this.classificationName(query.genres),
    );

    if (query.query?.trim()) {
      url.searchParams.set('keyword', query.query.trim());
    }
    if (query.from) {
      url.searchParams.set('startDateTime', toTicketmasterDate(query.from));
    }
    if (query.to) {
      url.searchParams.set('endDateTime', toTicketmasterDate(query.to));
    }

    const data = await this.getJson<TicketmasterSearchResponse>(url);
    return (data._embedded?.events ?? [])
      .map((event) => this.toConcert(event, query))
      .filter((concert): concert is ConcertModel => Boolean(concert));
  }

  async getEvent(id: string) {
    if (!this.apiKey) return null;

    const url = new URL(`${this.baseUrl}/events/${id}.json`);
    url.searchParams.set('apikey', this.apiKey);
    url.searchParams.set('locale', this.locale);

    return this.toConcert(await this.getJson<TicketmasterEvent>(url));
  }

  private get apiKey() {
    return this.config.get<string>('TICKETMASTER_API_KEY')?.trim();
  }

  private get countryCode() {
    return this.config.get<string>('TICKETMASTER_COUNTRY_CODE')?.trim() || 'FR';
  }

  private get locale() {
    return this.config.get<string>('TICKETMASTER_LOCALE')?.trim() || 'fr-fr,*';
  }

  private classificationName(genres: string[]) {
    return mapGenresToClassificationName(genres);
  }

  private async getJson<T>(url: URL): Promise<T> {
    const response = await fetch(url, {
      headers: {
        accept: 'application/json',
      },
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.warn(
        `Ticketmaster request failed ${response.status}: ${body.slice(0, 240)}`,
      );
      throw new Error(
        `Ticketmaster request failed with status ${response.status}`,
      );
    }

    return response.json() as Promise<T>;
  }

  private toConcert(
    event: TicketmasterEvent,
    query?: FindConcertsDto,
  ): ConcertModel | null {
    const id = event.id;
    const startsAt = eventStartDate(event);
    const venue = event._embedded?.venues?.[0];
    const latitude = Number(venue?.location?.latitude);
    const longitude = Number(venue?.location?.longitude);

    if (
      !id ||
      !startsAt ||
      !venue ||
      Number.isNaN(latitude) ||
      Number.isNaN(longitude)
    ) {
      return null;
    }

    const distance =
      event.distance ??
      venue.distance ??
      (query
        ? distanceKm(query.latitude, query.longitude, latitude, longitude)
        : 0);

    return {
      id,
      artist:
        event._embedded?.attractions?.[0]?.name ?? event.name ?? 'Artiste',
      title: event.name ?? 'Concert',
      genre: toDisplayGenre(
        event.classifications?.[0]?.genre?.name ??
          event.classifications?.[0]?.subGenre?.name ??
          event.classifications?.[0]?.segment?.name ??
          'Musique',
      ),
      startsAt,
      venue: {
        name: venue.name ?? 'Salle a confirmer',
        city: venue.city?.name ?? 'Ville a confirmer',
        address: [venue.address?.line1, venue.address?.line2]
          .filter(Boolean)
          .join(', '),
        latitude,
        longitude,
      },
      distanceKm: Number(distance.toFixed(1)),
      priceFrom: event.priceRanges?.[0]?.min ?? 0,
      ticketUrl: event.url ?? '',
      description:
        event.info ?? event.pleaseNote ?? event.name ?? 'Concert Ticketmaster',
      source: 'ticketmaster',
      imageUrl: bestImageUrl(event),
    };
  }
}

// Les genres proposes dans l'application sont en francais, alors que le
// parametre classificationName de l'API Discovery attend les classifications
// anglaises de Ticketmaster. Sans cette table, "Electro" ou "Classique" ne
// remontent aucun resultat.
const GENRE_TO_TICKETMASTER: Record<string, string> = {
  rock: 'Rock',
  pop: 'Pop',
  electro: 'Electronic',
  jazz: 'Jazz',
  rap: 'Hip-Hop/Rap',
  classique: 'Classical',
};

const TICKETMASTER_TO_DISPLAY: Record<string, string> = {
  electronic: 'Electro',
  'dance/electronic': 'Electro',
  'hip-hop/rap': 'Rap',
  classical: 'Classique',
};

export function mapGenresToClassificationName(genres: string[]) {
  if (genres.length === 0) return 'music';
  return genres
    .map((genre) => GENRE_TO_TICKETMASTER[genre.toLowerCase()] ?? genre)
    .join(',');
}

export function toDisplayGenre(genre: string) {
  return TICKETMASTER_TO_DISPLAY[genre.toLowerCase()] ?? genre;
}

function eventStartDate(event: TicketmasterEvent) {
  const start = event.dates?.start;
  if (start?.dateTime) return start.dateTime;
  if (!start?.localDate) return null;
  return `${start.localDate}T${start.localTime ?? '00:00:00'}`;
}

function bestImageUrl(event: TicketmasterEvent) {
  return event.images
    ?.filter((image) => image.url && !image.fallback)
    .sort((a, b) => (b.width ?? 0) - (a.width ?? 0))[0]?.url;
}

function toTicketmasterDate(value: string) {
  return new Date(value).toISOString().replace('.000Z', 'Z');
}
