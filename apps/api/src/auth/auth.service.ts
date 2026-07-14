import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

import { AuthSessionModel } from '../users/user.model';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

export interface AuthTokenPayload {
  sub: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async register(body: RegisterDto) {
    return this.withAccessToken(await this.usersService.registerAccount(body));
  }

  async login(body: LoginDto) {
    return this.withAccessToken(await this.usersService.login(body));
  }

  private async withAccessToken(session: AuthSessionModel) {
    const payload: AuthTokenPayload = { sub: session.deviceId };
    return {
      ...session,
      accessToken: await this.jwtService.signAsync(payload),
    };
  }
}
