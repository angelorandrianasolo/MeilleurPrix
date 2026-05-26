import AsyncStorage from '@react-native-async-storage/async-storage';
import { SyncAPI } from './api';

const QUEUE_KEY = 'mp_offline_queue';

export async function getQueue() {
  const raw = await AsyncStorage.getItem(QUEUE_KEY);
  return raw ? JSON.parse(raw) : [];
}

export async function addToQueue(saisie) {
  const queue = await getQueue();
  queue.push({
    ...saisie,
    id: saisie.id || `${Date.now()}-${Math.random().toString(36).slice(2)}`,
    date_saisie: new Date().toISOString()
  });
  await AsyncStorage.setItem(QUEUE_KEY, JSON.stringify(queue));
  return queue.length;
}

export async function syncQueue() {
  const queue = await getQueue();
  if (queue.length === 0) return { synchronisees: 0 };

  const res = await SyncAPI.push(queue);
  await AsyncStorage.setItem(QUEUE_KEY, JSON.stringify([]));
  return res;
}

export async function getQueueCount() {
  const q = await getQueue();
  return q.length;
}
