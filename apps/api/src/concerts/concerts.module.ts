import { Module } from '@nestjs/common';

import { UsersModule } from '../users/users.module';
import { ConcertsController } from './concerts.controller';
import { ConcertsService } from './concerts.service';
import { TicketmasterClient } from './ticketmaster.client';

@Module({
  imports: [UsersModule],
  controllers: [ConcertsController],
  providers: [ConcertsService, TicketmasterClient],
})
export class ConcertsModule {}
