import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaService } from '../prisma/prisma.service';
import { PublicController } from './public.controller';
import { PublicService } from './public.service';

@Module({
  imports: [
    // `ThrottlerModule` é `@Global()`: em produção este `forRoot` compete
    // com o de `ProjectsModule`/`MediaModule` pelo mesmo token, e qualquer
    // um deles pode vencer o registro do throttler 'default' — por isso o
    // valor aqui é o mesmo boilerplate dos outros dois módulos, nunca o
    // limite real. O limite que vale é sempre o de `@Throttle()` no
    // controller (`PUBLIC_THROTTLE`), que sobrescreve por rota
    // independente de quem ganhou o `forRoot`. Este import só garante que
    // `PublicModule` continua carregável sozinho (import isolado em teste).
    ThrottlerModule.forRoot({ throttlers: [{ ttl: 60_000, limit: 60 }] }),
  ],
  controllers: [PublicController],
  providers: [PublicService, PrismaService],
})
export class PublicModule {}
