import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';

import { DatabaseModule } from '../database/database.module';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { OptionalSessionGuard, SessionGuard } from './session.guard';

@Module({
  imports: [
    DatabaseModule,
    UsersModule,
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: resolveJwtSecret(config),
        // Jeton d'acces court : le renouvellement passe par le refresh
        // token rotatif de 90 jours (POST /auth/refresh).
        signOptions: { expiresIn: '7d' },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, SessionGuard, OptionalSessionGuard],
  exports: [SessionGuard, OptionalSessionGuard],
})
export class AuthModule {}

function resolveJwtSecret(config: ConfigService) {
  const secret = config.get<string>('JWT_SECRET')?.trim();
  if (secret && secret !== 'replace-me') return secret;

  if (config.get<string>('NODE_ENV') === 'production') {
    throw new Error('JWT_SECRET doit etre defini en production');
  }

  return 'livearound-dev-only-secret';
}
