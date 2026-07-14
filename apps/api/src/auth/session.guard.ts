import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

import { AuthTokenPayload } from './auth.service';

export type SessionRequest = Request & { sessionDeviceId?: string };

/**
 * Exige un jeton Bearer valide : l'identite de session provient du JWT signe
 * par l'API, jamais d'un en-tete fourni librement par le client.
 */
@Injectable()
export class SessionGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<SessionRequest>();
    const deviceId = await resolveSessionDeviceId(this.jwtService, request);
    if (!deviceId) {
      throw new UnauthorizedException('Session invalide ou expiree');
    }

    request.sessionDeviceId = deviceId;
    return true;
  }
}

/**
 * Variante pour les endpoints publics (liste et detail des concerts) : la
 * session est prise en compte quand elle est presente, sinon la requete
 * continue en anonyme.
 */
@Injectable()
export class OptionalSessionGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<SessionRequest>();
    const deviceId = await resolveSessionDeviceId(this.jwtService, request);
    if (deviceId) {
      request.sessionDeviceId = deviceId;
    }

    return true;
  }
}

async function resolveSessionDeviceId(
  jwtService: JwtService,
  request: Request,
): Promise<string | null> {
  const header = request.headers.authorization;
  if (!header?.startsWith('Bearer ')) return null;

  try {
    const payload = await jwtService.verifyAsync<AuthTokenPayload>(
      header.slice('Bearer '.length),
    );
    return payload.sub ?? null;
  } catch {
    return null;
  }
}
