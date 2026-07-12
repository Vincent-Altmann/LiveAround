export type MusicGenre = string;

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
  source?: string;
  imageUrl?: string;
}

export interface ConcertReportModel {
  concertId: string;
  reason: string;
  createdAt: string;
}
