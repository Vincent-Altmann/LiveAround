import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from './auth/auth.module';
import { ConcertsModule } from './concerts/concerts.module';
import { HealthController } from './health/health.controller';
import { NotificationsModule } from './notifications/notifications.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    AuthModule,
    UsersModule,
    ConcertsModule,
    NotificationsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
