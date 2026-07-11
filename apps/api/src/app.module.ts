import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { ConcertsModule } from './concerts/concerts.module';
import { HealthController } from './health/health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    ConcertsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}

