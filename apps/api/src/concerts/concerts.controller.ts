import {
  Body,
  Controller,
  Get,
  Headers,
  NotFoundException,
  Param,
  Post,
  Query,
} from '@nestjs/common';

import { ConcertsService } from './concerts.service';
import { FindConcertsDto } from './dto/find-concerts.dto';
import { ReportConcertDto } from './dto/report-concert.dto';

@Controller('concerts')
export class ConcertsController {
  constructor(private readonly concertsService: ConcertsService) {}

  @Get()
  findNearby(
    @Query() query: FindConcertsDto,
    @Headers('x-livearound-device-id') deviceId?: string,
  ) {
    return this.concertsService.findNearby(query, deviceId);
  }

  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @Headers('x-livearound-device-id') deviceId?: string,
  ) {
    const concert = await this.concertsService.findOne(id, deviceId);
    if (!concert) {
      throw new NotFoundException('Concert introuvable');
    }
    return concert;
  }

  @Post(':id/favorite')
  async toggleFavorite(
    @Param('id') id: string,
    @Headers('x-livearound-device-id') deviceId?: string,
  ) {
    return this.concertsService.toggleFavorite(id, deviceId);
  }

  @Post(':id/report')
  async report(
    @Param('id') id: string,
    @Body() body: ReportConcertDto,
    @Headers('x-livearound-device-id') deviceId?: string,
  ) {
    return this.concertsService.report(id, body.reason, deviceId);
  }
}
