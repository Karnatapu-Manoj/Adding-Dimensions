type Envelope = { encryptedData?: string; salt?: string; nonce?: string; tag?: string; isSuccess?: boolean; statusCode?: number; returnMessage?: string; data?: unknown };
export const apiBase = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:5100').replace(/\/$/, '');
const tokenKey = 'teacher-training-api-token';
export const accessToken = () => sessionStorage.getItem(tokenKey);
export const setAccessToken = (token: string | null) => token ? sessionStorage.setItem(tokenKey, token) : sessionStorage.removeItem(tokenKey);
const encode = (bytes: Uint8Array) => btoa(Array.from(bytes, value => String.fromCharCode(value)).join(''));
const decode = (value: string) => Uint8Array.from(atob(value), character => character.charCodeAt(0));

async function key(salt: Uint8Array) {
  const password = import.meta.env.VITE_AES_PASSWORD;
  if (!password) throw new Error('The local API encryption configuration is missing. Run Start-Local.ps1 from the backend.');
  const material = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveKey']);
  return crypto.subtle.deriveKey({ name: 'PBKDF2', salt: salt as BufferSource, iterations: 1000, hash: 'SHA-256' }, material, { name: 'AES-GCM', length: 256 }, false, ['encrypt', 'decrypt']);
}

export async function encryptPayload(body: unknown) {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const nonce = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce, tagLength: 128 }, await key(salt), new TextEncoder().encode(JSON.stringify(body))));
  return { data: encode(encrypted.slice(0, -16)), tag: encode(encrypted.slice(-16)), salt: encode(salt), nonce: encode(nonce) };
}

async function decryptEnvelope(envelope: Envelope): Promise<Envelope> {
  const ciphertext = decode(envelope.encryptedData!); const tag = decode(envelope.tag!);
  const combined = new Uint8Array(ciphertext.length + tag.length); combined.set(ciphertext); combined.set(tag, ciphertext.length);
  const plain = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: decode(envelope.nonce!) as BufferSource, tagLength: 128 }, await key(decode(envelope.salt!)), combined);
  return JSON.parse(new TextDecoder().decode(plain)) as Envelope;
}

export async function apiPost<T>(path: string, body: unknown = {}): Promise<T> {
  const encrypted = await encryptPayload(body);
  const token = accessToken();
  const response = await fetch(`${apiBase}/api/${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify(encrypted), signal: AbortSignal.timeout(30000) });
  let message = await response.json() as Envelope;
  if (message.encryptedData) message = await decryptEnvelope(message);
  if (!response.ok || message.isSuccess === false) {
    if (response.status === 401 && path !== 'Account/Login') setAccessToken(null);
    throw new Error(message.returnMessage || `The API request failed (${response.status}).`);
  }
  return message.data as T;
}
