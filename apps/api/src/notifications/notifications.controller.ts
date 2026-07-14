import { Controller, Get, Param, ParseUUIDPipe, Post, UseGuards } from '@nestjs/common';

import { SessionDeviceId } from '../auth/session-device-id.decorator';
import { SessionGuard } from '../auth/session.guard';
import { NotificationsService } from './notifications.service';

@Controller('users/me/notifications')
@UseGuards(SessionGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  findMine(@SessionDeviceId() deviceId: string) {
    return this.notificationsService.findForDevice(deviceId);
  }

  @Post(':id/click')
  markClicked(
    @SessionDeviceId() deviceId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notificationsService.markClicked(deviceId, id);
  }
}
