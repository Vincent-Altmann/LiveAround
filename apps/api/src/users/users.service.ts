import {
  ConflictException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { pbkdf2Sync, randomBytes, timingSafeEqual } from 'crypto';

import { LoginDto } from '../auth/dto/login.dto';
import { RegisterDto } from '../auth/dto/register.dto';
import { ConcertModel } from '../concerts/concert.model';
import { DatabaseService } from '../database/database.service';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';
import {
  AuthSessionModel,
  FavoriteConcertRow,
  UserProfileModel,
  UserRow,
} from './user.model';

interface EditableUserFields {
  email?: string;
  displayName?: string;
}

interface FallbackUserState {
  profile: UserProfileModel;
  favorites: Map<string, ConcertModel>;
  passwordHash?: string;
}

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);
  private readonly fallbackUsers = new Map<string, FallbackUserState>();

  constructor(private readonly database: DatabaseService) {}

  async registerAccount(body: RegisterDto): Promise<AuthSessionModel> {
    const email = normalizeEmail(body.email) ?? body.email.trim().toLowerCase();
    const displayName =
      normalizeText(body.displayName) ?? displayNameFromEmail(email);
    const deviceId = generateAccountDeviceId();
    const passwordHash = hashPassword(body.password);

    try {
      const result = await this.database.query<UserRow>(
        `
          INSERT INTO users (device_id, email, display_name, password_hash)
          VALUES ($1, $2, $3, $4)
          RETURNING
            id,
            device_id,
            email,
            display_name,
            preferred_genres,
            preferred_radius_km,
            created_at,
            updated_at,
            (
              SELECT COUNT(*)
              FROM user_concert_favorites favorites
              WHERE favorites.user_id = users.id
            ) AS favorites_count
        `,
        [deviceId, email, displayName, passwordHash],
      );

      return toAuthSession(deviceId, result.rows[0]);
    } catch (error) {
      if (isUniqueViolation(error)) {
        throw new ConflictException('Un compte existe deja avec cet email');
      }

      this.warnFallback(error);
      const existing = this.findFallbackUserByEmail(email);
      if (existing) {
        throw new ConflictException('Un compte existe deja avec cet email');
      }

      const fallback = this.getFallbackUser(deviceId, {
        email,
        displayName,
      });
      fallback.passwordHash = passwordHash;
      return {
        deviceId,
        profile: fallback.profile,
      };
    }
  }

  async login(body: LoginDto): Promise<AuthSessionModel> {
    const email = normalizeEmail(body.email) ?? body.email.trim().toLowerCase();

    try {
      const result = await this.database.query<
        UserRow & { password_hash: string | null }
      >(
        `
          SELECT
            id,
            device_id,
            email,
            display_name,
            password_hash,
            preferred_genres,
            preferred_radius_km,
            created_at,
            updated_at,
            (
              SELECT COUNT(*)
              FROM user_concert_favorites favorites
              WHERE favorites.user_id = users.id
            ) AS favorites_count
          FROM users
          WHERE email = $1
          LIMIT 1
        `,
        [email],
      );

      const user = result.rows[0];
      if (
        !user?.password_hash ||
        !verifyPassword(body.password, user.password_hash)
      ) {
        throw new UnauthorizedException('Identifiants invalides');
      }

      const deviceId = user.device_id ?? generateAccountDeviceId();
      if (!user.device_id) {
        await this.database.query(
          `
            UPDATE users
            SET device_id = $2, updated_at = now()
            WHERE id = $1
          `,
          [user.id, deviceId],
        );
      }

      return toAuthSession(deviceId, user);
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;

      this.warnFallback(error);
      const fallback = this.findFallbackUserByEmail(email);
      if (
        !fallback?.passwordHash ||
        !verifyPassword(body.password, fallback.passwordHash)
      ) {
        throw new UnauthorizedException('Identifiants invalides');
      }

      return {
        deviceId: fallback.profile.id,
        profile: fallback.profile,
      };
    }
  }

  async getOrCreateCurrentUser(
    deviceId: string | undefined,
    fields: EditableUserFields = {},
  ): Promise<UserProfileModel> {
    const normalizedDeviceId = normalizeDeviceId(deviceId);
    const email =
      normalizeEmail(fields.email) ?? fallbackEmail(normalizedDeviceId);
    const displayName =
      normalizeText(fields.displayName) ?? 'Utilisateur LiveAround';

    try {
      const result = await this.database.query<UserRow>(
        `
          INSERT INTO users (device_id, email, display_name)
          VALUES ($1, $2, $3)
          ON CONFLICT (device_id) WHERE device_id IS NOT NULL
          DO UPDATE SET
            email = COALESCE(NULLIF($4, ''), users.email),
            display_name = COALESCE(NULLIF($5, ''), users.display_name),
            updated_at = now()
          RETURNING
            id,
            email,
            display_name,
            preferred_genres,
            preferred_radius_km,
            created_at,
            updated_at,
            (
              SELECT COUNT(*)
              FROM user_concert_favorites favorites
              WHERE favorites.user_id = users.id
            ) AS favorites_count
        `,
        [
          normalizedDeviceId,
          email,
          displayName,
          fields.email ?? '',
          fields.displayName ?? '',
        ],
      );

      return toProfile(result.rows[0]);
    } catch (error) {
      this.warnFallback(error);
      return this.getFallbackUser(normalizedDeviceId, fields).profile;
    }
  }

  async updatePreferences(
    deviceId: string | undefined,
    preferences: UpdatePreferencesDto,
  ): Promise<UserProfileModel> {
    const normalizedDeviceId = normalizeDeviceId(deviceId);
    const genres = sanitizeGenres(preferences.preferredGenres);
    const radiusKm = clampRadius(preferences.preferredRadiusKm);

    try {
      const user = await this.getOrCreateCurrentUser(normalizedDeviceId);
      const result = await this.database.query<UserRow>(
        `
          UPDATE users
          SET
            preferred_genres = $2,
            preferred_radius_km = $3,
            updated_at = now()
          WHERE id = $1
          RETURNING
            id,
            email,
            display_name,
            preferred_genres,
            preferred_radius_km,
            created_at,
            updated_at,
            (
              SELECT COUNT(*)
              FROM user_concert_favorites favorites
              WHERE favorites.user_id = users.id
            ) AS favorites_count
        `,
        [user.id, genres, radiusKm],
      );

      return toProfile(result.rows[0]);
    } catch (error) {
      this.warnFallback(error);
      const fallback = this.getFallbackUser(normalizedDeviceId);
      fallback.profile = {
        ...fallback.profile,
        preferredGenres: genres,
        preferredRadiusKm: radiusKm,
        updatedAt: new Date().toISOString(),
      };
      return fallback.profile;
    }
  }

  async getFavoriteIds(deviceId: string | undefined): Promise<Set<string>> {
    const normalizedDeviceId = normalizeDeviceId(deviceId);

    try {
      const user = await this.getOrCreateCurrentUser(normalizedDeviceId);
      const result = await this.database.query<{ concert_external_id: string }>(
        `
          SELECT concert_external_id
          FROM user_concert_favorites
          WHERE user_id = $1
        `,
        [user.id],
      );

      return new Set(result.rows.map((row) => row.concert_external_id));
    } catch (error) {
      this.warnFallback(error);
      return new Set(this.getFallbackUser(normalizedDeviceId).favorites.keys());
    }
  }

  async toggleFavorite(
    deviceId: string | undefined,
    concert: ConcertModel,
  ): Promise<boolean> {
    const normalizedDeviceId = normalizeDeviceId(deviceId);

    try {
      const user = await this.getOrCreateCurrentUser(normalizedDeviceId);
      const inserted = await this.database.query(
        `
          INSERT INTO user_concert_favorites
            (user_id, concert_external_id, concert_snapshot)
          VALUES ($1, $2, $3::jsonb)
          ON CONFLICT DO NOTHING
        `,
        [user.id, concert.id, JSON.stringify(concert)],
      );

      if (inserted.rowCount > 0) return true;

      await this.database.query(
        `
          DELETE FROM user_concert_favorites
          WHERE user_id = $1 AND concert_external_id = $2
        `,
        [user.id, concert.id],
      );

      return false;
    } catch (error) {
      this.warnFallback(error);
      const favorites = this.getFallbackUser(normalizedDeviceId).favorites;
      if (favorites.has(concert.id)) {
        favorites.delete(concert.id);
        return false;
      }

      favorites.set(concert.id, concert);
      return true;
    }
  }

  async findFavoriteConcerts(
    deviceId: string | undefined,
  ): Promise<ConcertModel[]> {
    const normalizedDeviceId = normalizeDeviceId(deviceId);

    try {
      const user = await this.getOrCreateCurrentUser(normalizedDeviceId);
      const result = await this.database.query<FavoriteConcertRow>(
        `
          SELECT concert_external_id, concert_snapshot
          FROM user_concert_favorites
          WHERE user_id = $1
          ORDER BY created_at DESC
        `,
        [user.id],
      );

      return result.rows
        .map((row) =>
          toConcertSnapshot(row.concert_snapshot, row.concert_external_id),
        )
        .filter((concert): concert is ConcertModel => Boolean(concert));
    } catch (error) {
      this.warnFallback(error);
      return [...this.getFallbackUser(normalizedDeviceId).favorites.values()];
    }
  }

  private getFallbackUser(
    deviceId: string,
    fields: EditableUserFields = {},
  ): FallbackUserState {
    const existing = this.fallbackUsers.get(deviceId);
    if (existing) {
      existing.profile = {
        ...existing.profile,
        email: normalizeEmail(fields.email) ?? existing.profile.email,
        displayName:
          normalizeText(fields.displayName) ?? existing.profile.displayName,
        favoritesCount: existing.favorites.size,
        updatedAt: new Date().toISOString(),
      };
      return existing;
    }

    const now = new Date().toISOString();
    const state = {
      profile: {
        id: deviceId,
        email: normalizeEmail(fields.email) ?? fallbackEmail(deviceId),
        displayName:
          normalizeText(fields.displayName) ?? 'Utilisateur LiveAround',
        preferredGenres: [],
        preferredRadiusKm: 25,
        favoritesCount: 0,
        createdAt: now,
        updatedAt: now,
      },
      favorites: new Map<string, ConcertModel>(),
    };
    this.fallbackUsers.set(deviceId, state);
    return state;
  }

  private findFallbackUserByEmail(email: string) {
    return [...this.fallbackUsers.values()].find(
      (user) => user.profile.email.toLowerCase() === email,
    );
  }

  private warnFallback(error: unknown) {
    this.logger.warn(`Database fallback active: ${errorMessage(error)}`);
  }
}

function toProfile(row: UserRow): UserProfileModel {
  return {
    id: row.id,
    email: row.email,
    displayName: row.display_name ?? 'Utilisateur LiveAround',
    preferredGenres: row.preferred_genres ?? [],
    preferredRadiusKm: row.preferred_radius_km ?? 25,
    favoritesCount: Number(row.favorites_count ?? 0),
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
  };
}

function toAuthSession(deviceId: string, row: UserRow): AuthSessionModel {
  return {
    deviceId,
    profile: toProfile(row),
  };
}

function toConcertSnapshot(
  value: unknown,
  fallbackId: string,
): ConcertModel | null {
  if (typeof value === 'string') {
    try {
      return toConcertSnapshot(JSON.parse(value), fallbackId);
    } catch {
      return null;
    }
  }

  if (!value || typeof value !== 'object') return null;
  const concert = value as Partial<ConcertModel>;
  if (!concert.id) concert.id = fallbackId;
  return concert.id ? (concert as ConcertModel) : null;
}

function normalizeDeviceId(deviceId: string | undefined) {
  const normalized = normalizeText(deviceId);
  if (!normalized) return 'livearound-demo-device';
  return normalized.replace(/[^a-zA-Z0-9._-]/g, '-').slice(0, 128);
}

function normalizeEmail(email: string | undefined) {
  const normalized = normalizeText(email)?.toLowerCase();
  return normalized?.includes('@') ? normalized : undefined;
}

function normalizeText(value: string | undefined) {
  const normalized = value?.trim();
  return normalized && normalized.length > 0 ? normalized : undefined;
}

function fallbackEmail(deviceId: string) {
  return `${deviceId}@users.livearound.local`;
}

function displayNameFromEmail(email: string) {
  return email.split('@')[0] || 'Utilisateur LiveAround';
}

function generateAccountDeviceId() {
  return `account-${randomBytes(16).toString('hex')}`;
}

function hashPassword(password: string) {
  const iterations = 120000;
  const salt = randomBytes(16).toString('hex');
  const hash = pbkdf2Sync(password, salt, iterations, 32, 'sha256').toString(
    'hex',
  );
  return `pbkdf2_sha256$${iterations}$${salt}$${hash}`;
}

function verifyPassword(password: string, storedHash: string) {
  const [algorithm, iterationsRaw, salt, hash] = storedHash.split('$');
  const iterations = Number(iterationsRaw);
  if (algorithm !== 'pbkdf2_sha256' || !iterations || !salt || !hash) {
    return false;
  }

  const candidate = pbkdf2Sync(
    password,
    salt,
    iterations,
    32,
    'sha256',
  ).toString('hex');
  const expectedBuffer = Buffer.from(hash, 'hex');
  const candidateBuffer = Buffer.from(candidate, 'hex');
  if (expectedBuffer.length !== candidateBuffer.length) return false;
  return timingSafeEqual(expectedBuffer, candidateBuffer);
}

function isUniqueViolation(error: unknown) {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as { code?: string }).code === '23505'
  );
}

function sanitizeGenres(genres: string[] | undefined) {
  return [
    ...new Set((genres ?? []).map((genre) => genre.trim()).filter(Boolean)),
  ];
}

function clampRadius(value: number | undefined) {
  if (value == null || Number.isNaN(value)) return 25;
  return Math.max(1, Math.min(200, Math.round(value)));
}

function toIso(value: Date | string) {
  return value instanceof Date
    ? value.toISOString()
    : new Date(value).toISOString();
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}
