import { createPrivateKey, sign, type KeyObject } from "node:crypto";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";
import { app } from "electron";

/** Apple accepts up to six months; a fresh token is minted at every launch anyway. */
const lifetimeSeconds = 60 * 60 * 24 * 30;

/**
 * Mints a MusicKit developer token (an ES256 JWT) from the key configured in
 * `.env.local`. This runs in the main process so the private key never
 * reaches the page; the token itself is public, MusicKit JS sends it to Apple.
 */
export function mintDeveloperToken(): string {
  const { MUSICKIT_TEAM_ID: teamId, MUSICKIT_KEY_ID: keyId, MUSICKIT_KEY_PATH: keyPath } = process.env;
  if (!teamId || !keyId || !keyPath) {
    throw new Error(
      "No MusicKit key is configured. Set MUSICKIT_TEAM_ID, MUSICKIT_KEY_ID and MUSICKIT_KEY_PATH in apps/desktop/.env.local, then restart.",
    );
  }

  const path = resolve(app.getAppPath(), keyPath.replace(/^~(?=\/|$)/, homedir()));
  let key: KeyObject;
  try {
    key = createPrivateKey(readFileSync(path));
  } catch (error) {
    throw new Error(`Couldn't read the MusicKit key at ${path}: ${(error as Error).message}`);
  }

  const now = Math.floor(Date.now() / 1000);
  const encode = (part: object) => Buffer.from(JSON.stringify(part)).toString("base64url");
  const unsigned = `${encode({ alg: "ES256", kid: keyId })}.${encode({ iss: teamId, iat: now, exp: now + lifetimeSeconds })}`;
  const signature = sign("sha256", Buffer.from(unsigned), { key, dsaEncoding: "ieee-p1363" });
  return `${unsigned}.${signature.toString("base64url")}`;
}
