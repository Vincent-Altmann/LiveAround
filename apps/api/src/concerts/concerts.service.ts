import { Injectable, NotFoundException } from '@nestjs/common';

import { ConcertModel, ConcertReportModel } from './concert.model';
import { FindConcertsDto } from './dto/find-concerts.dto';

@Injectable()
export class ConcertsService {
  private readonly favorites = new Set<string>();
  private readonly reports: ConcertReportModel[] = [];

  findNearby(query: FindConcertsDto) {
    const normalizedQuery = query.query?.trim().toLowerCase();
    const from = query.from ? new Date(query.from) : null;
    const to = query.to ? new Date(query.to) : null;

    return seedConcerts
      .map((concert) => ({
        ...concert,
        distanceKm: distanceKm(
          query.latitude,
          query.longitude,
          concert.venue.latitude,
          concert.venue.longitude,
        ),
        isFavorite: this.favorites.has(concert.id),
      }))
      .filter((concert) => concert.distanceKm <= query.radiusKm)
      .filter((concert) => {
        if (query.genres.length === 0) return true;
        return query.genres.includes(concert.genre);
      })
      .filter((concert) => {
        const startsAt = new Date(concert.startsAt);
        if (from && startsAt < from) return false;
        if (to && startsAt > to) return false;
        return true;
      })
      .filter((concert) => {
        if (!normalizedQuery) return true;
        return (
          concert.artist.toLowerCase().includes(normalizedQuery) ||
          concert.title.toLowerCase().includes(normalizedQuery) ||
          concert.venue.city.toLowerCase().includes(normalizedQuery)
        );
      })
      .sort((a, b) => a.distanceKm - b.distanceKm);
  }

  findOne(id: string) {
    const concert = seedConcerts.find((item) => item.id === id);
    if (!concert) return null;
    return {
      ...concert,
      isFavorite: this.favorites.has(id),
    };
  }

  toggleFavorite(id: string) {
    const concert = this.findOne(id);
    if (!concert) {
      throw new NotFoundException('Concert introuvable');
    }

    if (this.favorites.has(id)) {
      this.favorites.delete(id);
    } else {
      this.favorites.add(id);
    }

    return {
      concertId: id,
      isFavorite: this.favorites.has(id),
    };
  }

  report(concertId: string, reason: string) {
    const concert = this.findOne(concertId);
    if (!concert) {
      throw new NotFoundException('Concert introuvable');
    }

    const report = {
      concertId,
      reason,
      createdAt: new Date().toISOString(),
    };
    this.reports.push(report);
    return report;
  }
}

function distanceKm(
  latitudeA: number,
  longitudeA: number,
  latitudeB: number,
  longitudeB: number,
) {
  const earthRadiusKm = 6371;
  const dLat = toRadians(latitudeB - latitudeA);
  const dLon = toRadians(longitudeB - longitudeA);
  const latA = toRadians(latitudeA);
  const latB = toRadians(latitudeB);

  const haversine =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.sin(dLon / 2) *
      Math.sin(dLon / 2) *
      Math.cos(latA) *
      Math.cos(latB);

  return earthRadiusKm * 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
}

function toRadians(value: number) {
  return (value * Math.PI) / 180;
}

const seedConcerts: ConcertModel[] = [
  {
    id: 'la-001',
    artist: 'The Velvet Echoes',
    title: 'Tournee d ete',
    genre: 'Rock',
    startsAt: '2026-07-24T20:30:00.000Z',
    venue: {
      name: 'Le Transbordeur',
      city: 'Villeurbanne',
      address: '3 boulevard Stalingrad',
      latitude: 45.7832,
      longitude: 4.8605,
    },
    priceFrom: 32,
    ticketUrl: 'https://tickets.example/livearound/la-001',
    description: 'Un concert rock nerveux dans une salle lyonnaise emblematique.',
  },
  {
    id: 'la-002',
    artist: 'Nora Blue',
    title: 'Fragments acoustiques',
    genre: 'Pop',
    startsAt: '2026-07-27T19:45:00.000Z',
    venue: {
      name: 'Radiant-Bellevue',
      city: 'Caluire-et-Cuire',
      address: '1 rue Jean Moulin',
      latitude: 45.7958,
      longitude: 4.8446,
    },
    priceFrom: 28,
    ticketUrl: 'https://tickets.example/livearound/la-002',
    description: 'Une soiree pop lumineuse avec une scenographie intimiste.',
  },
  {
    id: 'la-003',
    artist: 'Collectif Minuit',
    title: 'Warehouse live session',
    genre: 'Electro',
    startsAt: '2026-08-02T23:00:00.000Z',
    venue: {
      name: 'Ninkasi Gerland',
      city: 'Lyon',
      address: '267 rue Marcel Merieux',
      latitude: 45.7272,
      longitude: 4.8307,
    },
    priceFrom: 24,
    ticketUrl: 'https://tickets.example/livearound/la-003',
    description: 'Set electro nocturne, pense pour les amateurs de decouverte locale.',
  },
  {
    id: 'la-004',
    artist: 'Maya Quartet',
    title: 'Jazz sur la Saone',
    genre: 'Jazz',
    startsAt: '2026-08-09T21:00:00.000Z',
    venue: {
      name: 'Hot Club de Lyon',
      city: 'Lyon',
      address: '26 rue Lanterne',
      latitude: 45.7669,
      longitude: 4.8277,
    },
    priceFrom: 18,
    ticketUrl: 'https://tickets.example/livearound/la-004',
    description: 'Quartet jazz moderne, parfait pour une sortie de derniere minute.',
  },
  {
    id: 'la-005',
    artist: 'Kobalt',
    title: 'Nord Sud',
    genre: 'Rap',
    startsAt: '2026-08-14T20:00:00.000Z',
    venue: {
      name: 'Halle Tony Garnier',
      city: 'Lyon',
      address: '20 place Docteurs Merieux',
      latitude: 45.7302,
      longitude: 4.8239,
    },
    priceFrom: 39,
    ticketUrl: 'https://tickets.example/livearound/la-005',
    description: 'Plateau rap francophone avec premiere partie locale selectionnee.',
  },
  {
    id: 'la-006',
    artist: 'Solstice Strings',
    title: 'Classiques au parc',
    genre: 'Classique',
    startsAt: '2026-08-21T18:30:00.000Z',
    venue: {
      name: 'Auditorium de Lyon',
      city: 'Lyon',
      address: '149 rue Garibaldi',
      latitude: 45.7607,
      longitude: 4.8525,
    },
    priceFrom: 21,
    ticketUrl: 'https://tickets.example/livearound/la-006',
    description: 'Programme accessible autour de cordes et pieces orchestrales.',
  },
];

