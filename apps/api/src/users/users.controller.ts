import { Body, Controller, Get, Headers, Patch, Post } from '@nestjs/common';

import { UpdatePreferencesDto } from './dto/update-preferences.dto';
import { UpsertCurrentUserDto } from './dto/upsert-current-user.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('me')
  upsertCurrentUser(@Body() body: UpsertCurrentUserDto) {
    return this.usersService.getOrCreateCurrentUser(body.deviceId, {
      email: body.email,
      displayName: body.displayName,
    });
  }

  @Get('me')
  getCurrentUser(@Headers('x-livearound-device-id') deviceId?: string) {
    return this.usersService.getOrCreateCurrentUser(deviceId);
  }

  @Patch('me/preferences')
  updatePreferences(
    @Headers('x-livearound-device-id') deviceId: string | undefined,
    @Body() body: UpdatePreferencesDto,
  ) {
    return this.usersService.updatePreferences(deviceId, body);
  }

  @Get('me/favorites')
  findFavorites(@Headers('x-livearound-device-id') deviceId?: string) {
    return this.usersService.findFavoriteConcerts(deviceId);
  }
}
