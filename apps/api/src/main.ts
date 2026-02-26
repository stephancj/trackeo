import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

process.env.TZ = 'UTC';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  app.enableCors();

  // Validation globale des DTOs (class-validator)
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Supprime les champs non déclarés
      forbidNonWhitelisted: false,
      transform: true, // Auto-cast (string → number, etc.)
    }),
  );

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`Trackeo API running on http://localhost:${port}/api`);
}
bootstrap().catch((err) => console.error(err));
