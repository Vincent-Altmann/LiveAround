import { Body, Controller, Get, Patch, Post, UseGuards } from '@nestjs/common';

import { SessionDeviceId } from '../auth/session-device-id.decorator';
import { SessionGuard } from '../auth/session.guard';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';
import { UpsertCurrentUserDto } from './dto/upsert-current-user.dto';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(SessionGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('me')
  upsertCurrentUser(
    @SessionDeviceId() deviceId: string,
    @Body() body: UpsertCurrentUserDto,
  ) {
    return this.usersService.getOrCreateCurrentUser(deviceId, {
      email: body.email,
      displayName: body.displayName,
    });
  }

  @Get('me')
  getCurrentUser(@SessionDeviceId() deviceId: string) {
    return this.usersService.getOrCreateCurrentUser(deviceId);
  }

  @Patch('me/preferences')
  updatePreferences(
    @SessionDeviceId() deviceId: string,
    @Body() body: UpdatePreferencesDto,
  ) {
    return this.usersService.updatePreferences(deviceId, body);
  }

  @Get('me/favorites')
  findFavorites(@SessionDeviceId() deviceId: string) {
    return this.usersService.findFavoriteConcerts(deviceId);
  }
}
