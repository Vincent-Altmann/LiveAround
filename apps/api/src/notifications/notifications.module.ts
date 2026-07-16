import { Module } from '@nestjs/common';

import { DatabaseModule } from '../database/database.module';
import { UsersModule } from '../users/users.module';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { InAppPushSender, PushSender } from './push-sender';

@Module({
  imports: [DatabaseModule, UsersModule],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    // Pour activer FCM : remplacer InAppPushSender par une implementation
    // firebase-admin (voir push-sender.ts).
    { provide: PushSender, useClass: InAppPushSender },
  ],
})
export class NotificationsModule {}
