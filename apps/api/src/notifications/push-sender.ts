import { Injectable, Logger } from '@nestjs/common';

export interface PushNotificationPayload {
  userId: string;
  concertId: string;
  title: string;
  body: string;
}

/**
 * Point de branchement Firebase Cloud Messaging.
 *
 * Les alertes sont deja calculees, dedupliquees et persistees dans
 * user_notifications (consultables in-app via GET /users/me/notifications).
 * Pour activer le push reel :
 * 1. creer un projet Firebase et telecharger un service account ;
 * 2. enregistrer les jetons d'appareil FCM cote mobile (table a ajouter) ;
 * 3. remplacer InAppPushSender par une implementation firebase-admin
 *    (messaging().send) dans notifications.module.ts.
 */
export abstract class PushSender {
  abstract send(payload: PushNotificationPayload): Promise<void>;
}

@Injectable()
export class InAppPushSender extends PushSender {
  private readonly logger = new Logger(InAppPushSender.name);

  async send(payload: PushNotificationPayload): Promise<void> {
    // Pas d'envoi distant : l'alerte reste disponible in-app. Le log sert de
    // trace pour verifier le pipeline en developpement.
    this.logger.log(
      `Alerte in-app pour ${payload.userId}: ${payload.title} — ${payload.body}`,
    );
  }
}
