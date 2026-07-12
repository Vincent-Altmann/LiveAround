export interface UserProfileModel {
  id: string;
  email: string;
  displayName: string;
  preferredGenres: string[];
  preferredRadiusKm: number;
  favoritesCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface FavoriteConcertRow {
  concert_external_id: string;
  concert_snapshot: unknown;
}

export interface UserRow {
  id: string;
  email: string;
  display_name: string | null;
  preferred_genres: string[] | null;
  preferred_radius_km: number | null;
  favorites_count?: string | number | null;
  created_at: Date | string;
  updated_at: Date | string;
}
