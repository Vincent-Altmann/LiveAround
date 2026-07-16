import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { createHash, randomBytes } from 'crypto';

import { DatabaseService } from '../database/database.service';
import { AuthSessionModel } from '../users/user.model';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

export interface AuthTokenPayload {
  sub: string;
}

// Le jeton d'acces est volontairement court (7 jours) : le refresh token,
// stocke hashe en base et rotatif, permet de renouveler la session sans
// redemander le mot de passe pendant 90 jours.
const REFRESH_TOKEN_TTL_DAYS = 90;

export interface AuthTokensModel extends AuthSessionModel {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly database: DatabaseService,
  ) {}

  async register(body: RegisterDto): Promise<AuthTokensModel> {
    return this.issueTokens(await this.usersService.registerAccount(body));
  }

  async login(body: LoginDto): Promise<AuthTokensModel> {
    return this.issueTokens(await this.usersService.login(body));
  }

  /**
   * Renouvelle la session a partir d'un refresh token : verification du
   * hash en base, rotation (l'ancien jeton est detruit), nouveaux jetons.
   */
  async refresh(refreshToken: string): Promise<AuthTokensModel> {
    const tokenHash = hashToken(refreshToken);
    const result = await this.database.query<{
      user_id: string;
      expires_at: Date | string;
    }>(
      `
        DELETE FROM user_refresh_tokens
        WHERE token_hash = $1
        RETURNING user_id, expires_at
      `,
      [tokenHash],
    );

    const row = result.rows[0];
    if (!row || new Date(row.expires_at) < new Date()) {
      throw new UnauthorizedException('Session expiree, reconnectez-vous');
    }

    const session = await this.usersService.findSessionByUserId(row.user_id);
    if (!session) {
      throw new UnauthorizedException('Session expiree, reconnectez-vous');
    }

    return this.issueTokens(session);
  }

  /** Revoque tous les refresh tokens d'un compte (changement/reset de mot de passe). */
  async revokeAllSessions(userId: string) {
    await this.database.query(
      'DELETE FROM user_refresh_tokens WHERE user_id = $1',
      [userId],
    );
  }

  async issueTokens(session: AuthSessionModel): Promise<AuthTokensModel> {
    const payload: AuthTokenPayload = { sub: session.deviceId };
    const accessToken = await this.jwtService.signAsync(payload);

    const refreshToken = randomBytes(48).toString('hex');
    await this.database.query(
      `
        INSERT INTO user_refresh_tokens (token_hash, user_id, expires_at)
        VALUES ($1, $2, now() + interval '${REFRESH_TOKEN_TTL_DAYS} days')
      `,
      [hashToken(refreshToken), session.profile.id],
    );

    return {
      ...session,
      accessToken,
      refreshToken,
    };
  }
}

function hashToken(token: string) {
  return createHash('sha256').update(token).digest('hex');
}
