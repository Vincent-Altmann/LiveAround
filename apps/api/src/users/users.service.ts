import {
  ConflictException,
  Injectable,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { createHash, pbkdf2Sync, randomBytes, timingSafeEqual } from 'crypto';

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
            notification_opt_in,
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

      // Pas de repli en memoire pour la creation de compte : un compte
      // volatil disparaitrait au redemarrage du serveur sans que
      // l'utilisateur le sache.
      this.logger.error(
        `Creation de compte impossible: ${errorMessage(error)}`,
      );
      throw new ServiceUnavailableException(
        'Base de donnees indisponible, reessayez plus tard',
      );
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
            notification_opt_in,
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

      // Meme logique que registerAccount : une connexion ne doit jamais
      // reussir sur un etat en memoire.
      this.logger.error(`Connexion impossible: ${errorMessage(error)}`);
      throw new ServiceUnavailableException(
        'Base de donnees indisponible, reessayez plus tard',
      );
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
            notification_opt_in,
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
    const notificationOptIn = preferences.notificationOptIn ?? null;

    try {
      const user = await this.getOrCreateCurrentUser(normalizedDeviceId);
      const result = await this.database.query<UserRow>(
        `
          UPDATE users
          SET
            preferred_genres = $2,
            preferred_radius_km = $3,
            notification_opt_in = COALESCE($4, notification_opt_in),
            updated_at = now()
          WHERE id = $1
          RETURNING
            id,
            email,
            display_name,
            preferred_genres,
            preferred_radius_km,
            notification_opt_in,
            created_at,
            updated_at,
            (
              SELECT COUNT(*)
              FROM user_concert_favorites favorites
              WHERE favorites.user_id = users.id
            ) AS favorites_count
        `,
        [user.id, genres, radiusKm, notificationOptIn],
      );

      return toProfile(result.rows[0]);
    } catch (error) {
      this.warnFallback(error);
      const fallback = this.getFallbackUser(normalizedDeviceId);
      fallback.profile = {
        ...fallback.profile,
        preferredGenres: genres,
        preferredRadiusKm: radiusKm,
        notificationOptIn:
          notificationOptIn ?? fallback.profile.notificationOptIn,
        updatedAt: new Date().toISOString(),
      };
      return fallback.profile;
    }
  }

  /**
   * Recharge une session complete depuis l'identifiant interne du compte
   * (utilise par le renouvellement de jeton).
   */
  async findSessionByUserId(userId: string): Promise<AuthSessionModel | null> {
    const result = await this.database.query<UserRow>(
      `
        SELECT
          id,
          device_id,
          email,
          display_name,
          preferred_genres,
          preferred_radius_km,
          notification_opt_in,
          created_at,
          updated_at,
          (
            SELECT COUNT(*)
            FROM user_concert_favorites favorites
            WHERE favorites.user_id = users.id
          ) AS favorites_count
        FROM users
        WHERE id = $1
        LIMIT 1
      `,
      [userId],
    );

    const user = result.rows[0];
    if (!user) return null;

    const deviceId = user.device_id ?? generateAccountDeviceId();
    if (!user.device_id) {
      await this.database.query(
        'UPDATE users SET device_id = $2, updated_at = now() WHERE id = $1',
        [user.id, deviceId],
      );
    }

    return toAuthSession(deviceId, user);
  }

  /**
   * Change le mot de passe apres verification de l'actuel. Renvoie la
   * session pour reemettre des jetons (les anciens sont revoques).
   */
  async changePassword(
    deviceId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<AuthSessionModel> {
    try {
      const result = await this.database.query<
        UserRow & { password_hash: string | null }
      >(
        'SELECT id, password_hash FROM users WHERE device_id = $1 LIMIT 1',
        [normalizeDeviceId(deviceId)],
      );

      const user = result.rows[0];
      if (
        !user?.password_hash ||
        !verifyPassword(currentPassword, user.password_hash)
      ) {
        throw new UnauthorizedException('Mot de passe actuel invalide');
      }

      await this.database.query(
        'UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1',
        [user.id, hashPassword(newPassword)],
      );

      const session = await this.findSessionByUserId(user.id);
      if (!session) throw new UnauthorizedException('Session requise');
      return session;
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      this.logger.error(`Changement de mot de passe impossible: ${errorMessage(error)}`);
      throw new ServiceUnavailableException(
        'Base de donnees indisponible, reessayez plus tard',
      );
    }
  }

  /**
   * Genere un code de reinitialisation a 6 chiffres (15 min). Renvoie null
   * si l'email est inconnu : la reponse HTTP reste identique pour ne pas
   * permettre l'enumeration des comptes.
   */
  async createPasswordResetCode(
    email: string,
  ): Promise<{ userId: string; code: string } | null> {
    const normalizedEmail =
      normalizeEmail(email) ?? email.trim().toLowerCase();

    try {
      const result = await this.database.query<{ id: string }>(
        'SELECT id FROM users WHERE email = $1 AND password_hash IS NOT NULL LIMIT 1',
        [normalizedEmail],
      );

      const user = result.rows[0];
      if (!user) return null;

      const code = String(randomInt6());
      await this.database.query(
        `
          INSERT INTO password_reset_codes (user_id, code_hash, expires_at)
          VALUES ($1, $2, now() + interval '15 minutes')
          ON CONFLICT (user_id) DO UPDATE SET
            code_hash = EXCLUDED.code_hash,
            expires_at = EXCLUDED.expires_at,
            created_at = now()
        `,
        [user.id, hashResetCode(code)],
      );

      return { userId: user.id, code };
    } catch (error) {
      this.logger.error(`Creation du code de reset impossible: ${errorMessage(error)}`);
      throw new ServiceUnavailableException(
        'Base de donnees indisponible, reessayez plus tard',
      );
    }
  }

  /** Verifie le code de reinitialisation et applique le nouveau mot de passe. */
  async resetPassword(
    email: string,
    code: string,
    newPassword: string,
  ): Promise<string> {
    const normalizedEmail =
      normalizeEmail(email) ?? email.trim().toLowerCase();

    try {
      const result = await this.database.query<{
        id: string;
        code_hash: string | null;
        expires_at: Date | string | null;
      }>(
        `
          SELECT users.id, codes.code_hash, codes.expires_at
          FROM users
          LEFT JOIN password_reset_codes codes ON codes.user_id = users.id
          WHERE users.email = $1
          LIMIT 1
        `,
        [normalizedEmail],
      );

      const row = result.rows[0];
      const isValid =
        row?.code_hash != null &&
        row.expires_at != null &&
        new Date(row.expires_at) > new Date() &&
        timingSafeEqualHex(row.code_hash, hashResetCode(code.trim()));

      if (!row || !isValid) {
        throw new UnauthorizedException('Code invalide ou expire');
      }

      await this.database.query(
        'UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1',
        [row.id, hashPassword(newPassword)],
      );
      await this.database.query(
        'DELETE FROM password_reset_codes WHERE user_id = $1',
        [row.id],
      );

      return row.id;
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      this.logger.error(`Reset de mot de passe impossible: ${errorMessage(error)}`);
      throw new ServiceUnavailableException(
        'Base de donnees indisponible, reessayez plus tard',
      );
    }
  }

  /**
   * Suppression de compte (RGPD) : confirmation par mot de passe, puis
   * suppression en cascade (favoris, notifications, refresh tokens) ;
   * les signalements sont anonymises (SET NULL).
   */
  async deleteAccount(deviceId: string, password: string | undefined) {
    try {
      const result = await this.database.query<{
        id: string;
        password_hash: string | null;
      }>(
        'SELECT id, password_hash FROM users WHERE device_id = $1 LIMIT 1',
        [normalizeDeviceId(deviceId)],
      );

      const user = result.rows[0];
      if (!user) {
        throw new UnauthorizedException('Session requise');
      }

      if (
        user.password_hash &&
        (!password || !verifyPassword(password, user.password_hash))
      ) {
        throw new UnauthorizedException('Mot de passe invalide');
      }

      await this.database.query('DELETE FROM users WHERE id = $1', [user.id]);
      this.fallbackUsers.delete(normalizeDeviceId(deviceId));
      return { deleted: true };
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      this.logger.error(`Suppression de compte impossible: ${errorMessage(error)}`);
      throw new ServiceUnavailableException(
        'Base de donnees indisponible, reessayez plus tard',
      );
    }
  }

  /**
   * Memorise la derniere position de recherche : c'est elle qui sert de
   * point de reference aux alertes personnalisees. Jamais bloquant.
   */
  async updateLastLocation(
    deviceId: string | undefined,
    latitude: number,
    longitude: number,
  ) {
    const normalized = normalizeText(deviceId);
    if (!normalized || !Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return;
    }

    try {
      await this.database.query(
        `
          UPDATE users
          SET
            last_location = ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography,
            last_location_updated_at = now()
          WHERE device_id = $1
        `,
        [normalizeDeviceId(normalized), longitude, latitude],
      );
    } catch {
      // Base ou PostGIS indisponible : les alertes seront simplement muettes.
    }
  }

  async getFavoriteIds(deviceId: string | undefined): Promise<Set<string>> {
    // Consultation anonyme : aucun favori, et surtout aucun compte cree.
    if (!normalizeText(deviceId)) return new Set();

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
        notificationOptIn: false,
        favoritesCount: 0,
        createdAt: now,
        updatedAt: now,
      },
      favorites: new Map<string, ConcertModel>(),
    };
    this.fallbackUsers.set(deviceId, state);
    return state;
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
    notificationOptIn: row.notification_opt_in ?? false,
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
  if (!normalized) {
    // Ne doit jamais arriver derriere SessionGuard : plus de compte de
    // demonstration partage entre tous les clients sans identite.
    throw new UnauthorizedException('Session requise');
  }
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

function randomInt6() {
  // Code a 6 chiffres uniforme (100000-999999) base sur un alea crypto.
  return 100000 + (randomBytes(4).readUInt32BE(0) % 900000);
}

function hashResetCode(code: string) {
  return createHash('sha256').update(code).digest('hex');
}

function timingSafeEqualHex(expectedHex: string, candidateHex: string) {
  const expected = Buffer.from(expectedHex, 'hex');
  const candidate = Buffer.from(candidateHex, 'hex');
  if (expected.length !== candidate.length) return false;
  return timingSafeEqual(expected, candidate);
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
