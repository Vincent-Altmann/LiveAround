import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { ConcertsModule } from './concerts/concerts.module';
import { HealthController } from './health/health.controller';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    UsersModule,
    ConcertsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
