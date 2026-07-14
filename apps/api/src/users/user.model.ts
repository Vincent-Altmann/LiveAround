export interface UserProfileModel {
  id: string;
  email: string;
  displayName: string;
  preferredGenres: string[];
  preferredRadiusKm: number;
  notificationOptIn: boolean;
  favoritesCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface AuthSessionModel {
  deviceId: string;
  profile: UserProfileModel;
}

export interface FavoriteConcertRow {
  concert_external_id: string;
  concert_snapshot: unknown;
}

export interface UserRow {
  id: string;
  device_id: string | null;
  email: string;
  display_name: string | null;
  password_hash?: string | null;
  preferred_genres: string[] | null;
  preferred_radius_km: number | null;
  notification_opt_in?: boolean | null;
  favorites_count?: string | number | null;
  created_at: Date | string;
  updated_at: Date | string;
}
