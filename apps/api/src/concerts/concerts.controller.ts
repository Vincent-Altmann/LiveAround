import {
  Body,
  Controller,
  Get,
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
  findNearby(@Query() query: FindConcertsDto) {
    return this.concertsService.findNearby(query);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const concert = await this.concertsService.findOne(id);
    if (!concert) {
      throw new NotFoundException('Concert introuvable');
    }
    return concert;
  }

  @Post(':id/favorite')
  async toggleFavorite(@Param('id') id: string) {
    return this.concertsService.toggleFavorite(id);
  }

  @Post(':id/report')
  async report(@Param('id') id: string, @Body() body: ReportConcertDto) {
    return this.concertsService.report(id, body.reason);
  }
}
