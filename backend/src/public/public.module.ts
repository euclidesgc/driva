import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';
import { PrismaService } from '../prisma/prisma.service';
import { PUBLIC_THROTTLE } from './public.constants';
import { PublicController } from './public.controller';
import { PublicService } from './public.service';

@Module({
  imports: [
    // `ThrottlerModule` é `@Global()`: este `forRoot` compete com o de
    // `ProjectsModule`/`MediaModule` pelo mesmo token, e qualquer um deles
    // pode vencer o registro do throttler 'default'. Foi essa disputa que
    // já fez a rota pública aplicar 60/min em vez de 120. O que garante o
    // limite hoje é o `@Throttle(PUBLIC_THROTTLE)` do controller, que
    // sobrescreve por rota independente de quem ganhou o `forRoot`; este
    // import existe para `PublicModule` continuar carregável sozinho, e
    // reusa a mesma constante para não haver um segundo número de limite
    // no módulo dizendo outra coisa.
    ThrottlerModule.forRoot({ throttlers: [PUBLIC_THROTTLE.default] }),
  ],
  controllers: [PublicController],
  providers: [PublicService, PrismaService],
})
export class PublicModule {}
