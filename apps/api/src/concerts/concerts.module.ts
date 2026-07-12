import { Module } from '@nestjs/common';

import { ConcertsController } from './concerts.controller';
import { ConcertsService } from './concerts.service';
import { TicketmasterClient } from './ticketmaster.client';

@Module({
  controllers: [ConcertsController],
  providers: [ConcertsService, TicketmasterClient],
})
export class ConcertsModule {}
