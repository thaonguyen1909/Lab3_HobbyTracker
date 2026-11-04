import { getApp, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { onCall, HttpsError, type CallableRequest } from 'firebase-functions/v2/https';
import { error as logError } from 'firebase-functions/logger';
import { MomentError } from './domain.js';
import { MomentMediaStore } from './media.js';
import { MomentService } from './moments.js';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { MomentDelivery } from './moment_delivery.js';
import { MomentCleanup } from './moment_cleanup.js';
import { MomentCleanupMedia } from './moment_cleanup_media.js';

initializeApp();

function service() {
  const bucket = process.env.MOMENTS_STORAGE_BUCKET ?? getApp().options.storageBucket ??
    (process.env.FUNCTIONS_EMULATOR === 'true' ? `${process.env.GCLOUD_PROJECT}.appspot.com` : undefined);
  if (!bucket) throw new HttpsError('failed-precondition', 'The moments storage bucket has not been configured.');
  return new MomentService(getFirestore(), new MomentMediaStore(bucket));
}

function callable(operation: 'begin' | 'publish' | 'list' | 'get' | 'image' | 'retract') {
  return onCall({ region: 'asia-southeast1', memory: '512MiB', timeoutSeconds: 120,
    maxInstances: 2, concurrency: 4 }, async (request: CallableRequest<unknown>) => {
    request.rawRequest.res?.setHeader('Cache-Control', 'private, no-store, max-age=0');
    try {
      return await service()[operation](request.auth?.uid, request.data);
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      if (error instanceof MomentError) throw new HttpsError(error.code, error.message);
      // Do not log tokens, caption, URLs, source bytes or arbitrary SDK error payloads.
      logError('Moment operation failed', { operation, errorType: error instanceof Error ? error.name : 'Unknown' });
      throw new HttpsError('unavailable', 'The operation could not be completed. Please retry.');
    }
  });
}

export const beginGroupMomentUpload = callable('begin');
export const publishGroupMoment = callable('publish');
export const listGroupMoments = callable('list');
export const getGroupMoment = callable('get');
export const getGroupMomentImage = callable('image');
export const retractGroupMoment = callable('retract');

function delivery() {
  // Emulators cannot emulate FCM. Never fall through to real delivery locally.
  return new MomentDelivery(getFirestore(), process.env.FUNCTIONS_EMULATOR === 'true' ? null : getMessaging());
}
export const deliverGroupMoment = onDocumentCreated({ document: 'momentOutbox/{momentId}',
  region: 'asia-southeast1', timeoutSeconds: 120, maxInstances: 2, retry: true },
async event => { await delivery().process(event.params.momentId); });
export const retryMomentDeliveries = onSchedule({ schedule: 'every 1 minutes', region: 'asia-southeast1',
  timeoutSeconds: 120, maxInstances: 1 }, async () => { await delivery().retryDue(); });

export const cleanupExpiredMoments = onSchedule({ schedule: 'every 5 minutes', region: 'asia-southeast1',
  timeoutSeconds: 120, maxInstances: 1, memory: '512MiB' }, async () => {
  const bucket = process.env.MOMENTS_STORAGE_BUCKET ?? getApp().options.storageBucket;
  if (!bucket) throw new Error('Moment cleanup bucket is not configured.');
  await new MomentCleanup(getFirestore(), new MomentCleanupMedia(bucket)).run();
});
