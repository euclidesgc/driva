import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaService } from '../prisma/prisma.service';
import { PUBLIC_THROTTLE } from './public.constants';
import { PublicController } from './public.controller';
import { PublicService } from './public.service';

@Module({
  imports: [ThrottlerModule.forRoot({ throttlers: [PUBLIC_THROTTLE] })],
  controllers: [PublicController],
  providers: [PublicService, PrismaService],
})
export class PublicModule {}
