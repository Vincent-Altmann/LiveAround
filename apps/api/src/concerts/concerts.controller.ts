import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';

import { SessionDeviceId } from '../auth/session-device-id.decorator';
import { OptionalSessionGuard, SessionGuard } from '../auth/session.guard';
import { ConcertsService } from './concerts.service';
import { FindConcertsDto } from './dto/find-concerts.dto';
import { ReportConcertDto } from './dto/report-concert.dto';

@Controller('concerts')
export class ConcertsController {
  constructor(private readonly concertsService: ConcertsService) {}

  @Get()
  @UseGuards(OptionalSessionGuard)
  findNearby(
    @Query() query: FindConcertsDto,
    @SessionDeviceId() deviceId?: string,
  ) {
    return this.concertsService.findNearby(query, deviceId);
  }

  @Get(':id')
  @UseGuards(OptionalSessionGuard)
  async findOne(
    @Param('id') id: string,
    @SessionDeviceId() deviceId?: string,
  ) {
    const concert = await this.concertsService.findOne(id, deviceId);
    if (!concert) {
      throw new NotFoundException('Concert introuvable');
    }
    return concert;
  }

  @Post(':id/favorite')
  @UseGuards(SessionGuard)
  async toggleFavorite(
    @Param('id') id: string,
    @SessionDeviceId() deviceId: string,
  ) {
    return this.concertsService.toggleFavorite(id, deviceId);
  }

  @Post(':id/report')
  @UseGuards(SessionGuard)
  async report(
    @Param('id') id: string,
    @Body() body: ReportConcertDto,
    @SessionDeviceId() deviceId: string,
  ) {
    return this.concertsService.report(id, body.reason, deviceId);
  }
}
