import {applicationDefault, initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore, FieldValue, Timestamp} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {createAdminApp} from './app.mjs';

if (process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Remove emulator overrides for live Firebase.');
if (!process.env.GOOGLE_CLOUD_PROJECT || !process.env.GOOGLE_APPLICATION_CREDENTIALS) throw new Error('Configure functions/.env.local first.');
initializeApp({projectId:process.env.GOOGLE_CLOUD_PROJECT, credential:applicationDefault()});
const allowedOrigins = (process.env.ADMIN_ALLOWED_ORIGINS || 'http://127.0.0.1:5173').split(',').map(value=>value.trim());
const app = createAdminApp({auth:getAuth(), db:getFirestore(), FieldValue, Timestamp,
  bucket:process.env.ADMIN_STORAGE_BUCKET ? getStorage().bucket(process.env.ADMIN_STORAGE_BUCKET) : null,
  messaging:{send:async()=>{throw new Error('Local admin does not send FCM. Use the deployed API for delivery.');}}, allowedOrigins});
const port = Number(process.env.ADMIN_PORT || 8788);
if (!Number.isInteger(port) || port < 1024 || port > 65535) throw new Error('Invalid ADMIN_PORT.');
const server = app.listen(port, '127.0.0.1', ()=>console.log(`Live Firebase Admin API: http://127.0.0.1:${port}; project=${process.env.GOOGLE_CLOUD_PROJECT}`));
process.on('SIGTERM',()=>server.close());
process.on('SIGINT',()=>server.close());
