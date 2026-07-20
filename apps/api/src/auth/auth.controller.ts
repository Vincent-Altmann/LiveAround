import { Body, Controller, Logger, Post, UseGuards } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Throttle } from '@nestjs/throttler';

import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { SessionDeviceId } from './session-device-id.decorator';
import { SessionGuard } from './session.guard';

// Limites serrees sur les endpoints sensibles a la force brute.
const STRICT_THROTTLE = { default: { limit: 5, ttl: 60_000 } };

@Controller('auth')
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
    private readonly config: ConfigService,
  ) {}

  @Post('register')
  @Throttle(STRICT_THROTTLE)
  register(@Body() body: RegisterDto) {
    return this.authService.register(body);
  }

  @Post('login')
  @Throttle(STRICT_THROTTLE)
  login(@Body() body: LoginDto) {
    return this.authService.login(body);
  }

  @Post('refresh')
  refresh(@Body() body: RefreshTokenDto) {
    return this.authService.refresh(body.refreshToken);
  }

  @Post('change-password')
  @UseGuards(SessionGuard)
  async changePassword(
    @SessionDeviceId() deviceId: string,
    @Body() body: ChangePasswordDto,
  ) {
    const session = await this.usersService.changePassword(
      deviceId,
      body.currentPassword,
      body.newPassword,
    );
    // Toutes les sessions existantes sont revoquees, puis de nouveaux
    // jetons sont emis pour l'appareil qui vient de changer le mot de passe.
    await this.authService.revokeAllSessions(session.profile.id);
    return this.authService.issueTokens(session);
  }

  @Post('forgot-password')
  @Throttle(STRICT_THROTTLE)
  async forgotPassword(@Body() body: ForgotPasswordDto) {
    const reset = await this.usersService.createPasswordResetCode(body.email);

    if (reset) {
      // L'envoi du code par email (SMTP) reste a brancher : en attendant,
      // le code est trace cote serveur pour les tests.
      this.logger.log(
        `Code de reinitialisation pour ${body.email}: ${reset.code}`,
      );
    }

    const isDevelopment =
      this.config.get<string>('NODE_ENV') !== 'production';

    // Reponse identique que l'email existe ou non (anti-enumeration).
    return {
      message:
        'Si un compte existe avec cet email, un code de reinitialisation a ete genere.',
      ...(isDevelopment && reset ? { devCode: reset.code } : {}),
    };
  }

  @Post('reset-password')
  @Throttle(STRICT_THROTTLE)
  async resetPassword(@Body() body: ResetPasswordDto) {
    const userId = await this.usersService.resetPassword(
      body.email,
      body.code,
      body.newPassword,
    );
    await this.authService.revokeAllSessions(userId);
    return { message: 'Mot de passe reinitialise, connectez-vous.' };
  }
}
