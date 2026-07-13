import { Module } from '@nestjs/common';

import { DatabaseModule } from '../database/database.module';
import { UsersModule } from '../users/users.module';
import { ConcertsController } from './concerts.controller';
import { ConcertsService } from './concerts.service';
import { TicketmasterClient } from './ticketmaster.client';

@Module({
  imports: [DatabaseModule, UsersModule],
  controllers: [ConcertsController],
  providers: [ConcertsService, TicketmasterClient],
})
export class ConcertsModule {}
