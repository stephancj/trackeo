import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

/** Appliqué sur un controller ou une route pour restreindre l'accès par rôle.
 *  Exemple : @Roles('admin') */
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);
