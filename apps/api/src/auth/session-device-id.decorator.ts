import { createParamDecorator, ExecutionContext } from '@nestjs/common';

import { SessionRequest } from './session.guard';

export const SessionDeviceId = createParamDecorator(
  (_data: unknown, context: ExecutionContext): string | undefined => {
    const request = context.switchToHttp().getRequest<SessionRequest>();
    return request.sessionDeviceId;
  },
);
