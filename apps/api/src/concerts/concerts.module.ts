import { Module } from '@nestjs/common';

import { DatabaseModule } from '../database/database.module';
import { UsersModule } from '../users/users.module';
import { ConcertStore } from './concert-store.service';
import { ConcertsController } from './concerts.controller';
import { ConcertsService } from './concerts.service';
import { TicketmasterClient } from './ticketmaster.client';

@Module({
  imports: [DatabaseModule, UsersModule],
  controllers: [ConcertsController],
  providers: [ConcertsService, TicketmasterClient, ConcertStore],
  exports: [ConcertStore],
})
export class ConcertsModule {}
