import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';

import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { OptionalSessionGuard, SessionGuard } from './session.guard';

@Module({
  imports: [
    UsersModule,
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: resolveJwtSecret(config),
        signOptions: { expiresIn: '30d' },
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
