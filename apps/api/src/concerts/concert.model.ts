export type MusicGenre =
  | 'Rock'
  | 'Pop'
  | 'Electro'
  | 'Jazz'
  | 'Rap'
  | 'Classique';

export interface VenueModel {
  name: string;
  city: string;
  address: string;
  latitude: number;
  longitude: number;
}

export interface ConcertModel {
  id: string;
  artist: string;
  title: string;
  genre: MusicGenre;
  startsAt: string;
  venue: VenueModel;
  distanceKm?: number;
  priceFrom: number;
  ticketUrl: string;
  description: string;
}

export interface ConcertReportModel {
  concertId: string;
  reason: string;
  createdAt: string;
}

