/**
 * webauthn.ts — browser WebAuthn helper for Axiopass Wallet.
 *
 * Creates a passkey credential, extracts the P256 public key (X, Y),
 * and encodes a WebAuthn assertion signature into the ABI format expected
 * by VRQPasskeyValidator._verifyWebAuthnSignature().
 *
 * Only the `create` and `get` browser APIs are used — no native node modules.
 */

'use client';

// ── Passkey registration ──────────────────────────────────────────────────────

export interface PasskeyCredential {
  id:      string;
  pubKeyX: bigint;
  pubKeyY: bigint;
  rawId:   Uint8Array;
}

/**
 * Create a new passkey and extract the secp256r1 (P-256) public key.
 *
 * @param userId   - unique user identifier (Uint8Array)
 * @param userName - display name shown in the authenticator dialog
 */
export async function createPasskey(
  userId:   Uint8Array,
  userName: string,
): Promise<PasskeyCredential> {
  const credential = await navigator.credentials.create({
    publicKey: {
      challenge:  crypto.getRandomValues(new Uint8Array(32)),
      rp:         { name: 'Axiopass Wallet', id: window.location.hostname },
      user:       { id: userId.buffer as ArrayBuffer, name: userName, displayName: userName },
      pubKeyCredParams: [{ alg: -7, type: 'public-key' }], // ES256 (P-256)
      authenticatorSelection: {
        userVerification:    'required',
        residentKey:         'preferred',
        authenticatorAttachment: 'platform',
      },
      timeout: 60000,
    },
  }) as PublicKeyCredential;

  const response = credential.response as AuthenticatorAttestationResponse;
  const { x, y } = await extractP256PublicKey(response);

  return {
    id:      credential.id,
    pubKeyX: x,
    pubKeyY: y,
    rawId:   new Uint8Array(credential.rawId),
  };
}

/**
 * Extract the raw P-256 (x, y) coordinates from a WebAuthn attestation response.
 * The public key is CBOR-encoded inside the attestedCredentialData.
 */
async function extractP256PublicKey(
  response: AuthenticatorAttestationResponse,
): Promise<{ x: bigint; y: bigint }> {
  // getPublicKey() returns an SPKI-encoded P-256 key (65 bytes uncompressed point)
  const spki    = response.getPublicKey();
  if (!spki) throw new Error('Authenticator did not return a public key');

  const key = await crypto.subtle.importKey(
    'spki', spki, { name: 'ECDSA', namedCurve: 'P-256' }, true, ['verify'],
  );

  const jwk = await crypto.subtle.exportKey('jwk', key);
  if (!jwk.x || !jwk.y) throw new Error('Failed to extract JWK coordinates');

  const x = BigInt('0x' + Buffer.from(jwk.x, 'base64url').toString('hex'));
  const y = BigInt('0x' + Buffer.from(jwk.y, 'base64url').toString('hex'));

  return { x, y };
}

// ── Passkey assertion (signature for tx) ──────────────────────────────────────

export interface PasskeyAssertion {
  /** ABI-encoded signature ready for VRQPasskeyValidator.validateUserOp */
  encodedSignature: `0x${string}`;
  clientDataJSON:   string;
}

/**
 * Sign a 32-byte challenge (e.g. userOpHash) using an existing passkey.
 * Returns the signature encoded as VRQPasskeyValidator expects.
 *
 * Encoding: abi.encode(
 *   authenticatorData, requireUserVerification, clientDataJSON,
 *   challengeLocation, responseTypeLocation, r, s
 * )
 */
export async function signWithPasskey(
  credentialId: string,
  challenge:    Uint8Array,
): Promise<PasskeyAssertion> {
  const assertion = await navigator.credentials.get({
    publicKey: {
      challenge: challenge.buffer as ArrayBuffer,
      allowCredentials: [{ type: 'public-key', id: base64urlDecode(credentialId) }],
      userVerification: 'required',
      timeout: 60000,
    },
  }) as PublicKeyCredential;

  const response     = assertion.response as AuthenticatorAssertionResponse;
  const authData     = new Uint8Array(response.authenticatorData);
  const clientJSON   = new TextDecoder().decode(response.clientDataJSON);
  const sigDER       = new Uint8Array(response.signature);

  // Parse DER-encoded (r, s) from the signature
  const { r, s } = parseDERSignature(sigDER);

  // Locate "challenge" and "type" keys in the clientDataJSON string
  const challengeLocation    = BigInt(clientJSON.indexOf('"challenge"'));
  const responseTypeLocation = BigInt(clientJSON.indexOf('"type"'));

  // ABI-encode the full signature bundle
  // We use a manual hex encoding here to avoid importing the whole viem abi module
  // in a hot path — the on-chain decoder expects this exact layout.
  const encodedSignature = abiEncodeSignature(
    authData,
    true,          // requireUserVerification = true (UP+UV flags required)
    clientJSON,
    challengeLocation,
    responseTypeLocation,
    r,
    s,
  );

  return { encodedSignature, clientDataJSON: clientJSON };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Parse DER-encoded ECDSA signature into (r, s) bigints. */
function parseDERSignature(der: Uint8Array): { r: bigint; s: bigint } {
  // DER: 0x30 [len] 0x02 [rLen] [r] 0x02 [sLen] [s]
  let offset = 2; // skip 0x30, total length
  if (der[offset] !== 0x02) throw new Error('Invalid DER signature');
  const rLen = der[offset + 1];
  offset += 2;
  const rBytes = der.slice(offset, offset + rLen);
  offset += rLen;
  if (der[offset] !== 0x02) throw new Error('Invalid DER signature');
  const sLen = der[offset + 1];
  offset += 2;
  const sBytes = der.slice(offset, offset + sLen);

  const r = BigInt('0x' + bytesToHex(rBytes.slice(rBytes[0] === 0 ? 1 : 0)));
  const s = BigInt('0x' + bytesToHex(sBytes.slice(sBytes[0] === 0 ? 1 : 0)));
  return { r, s };
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

function base64urlDecode(b64: string): ArrayBuffer {
  const bin = atob(b64.replace(/-/g, '+').replace(/_/g, '/'));
  return Uint8Array.from(bin, c => c.charCodeAt(0)).buffer;
}

/**
 * Minimal ABI encoder for the VRQPasskeyValidator signature tuple.
 * Avoids importing viem in a hot passkey path.
 *
 * Layout (dynamic types use standard head/tail ABI encoding):
 *   [0]  offset → authenticatorData
 *   [1]  requireUserVerification (bool → uint256)
 *   [2]  offset → clientDataJSON
 *   [3]  challengeLocation    (uint256)
 *   [4]  responseTypeLocation (uint256)
 *   [5]  r (uint256)
 *   [6]  s (uint256)
 *   then tails for bytes + string
 */
function abiEncodeSignature(
  authData:             Uint8Array,
  requireUV:            boolean,
  clientDataJSON:       string,
  challengeLocation:    bigint,
  responseTypeLocation: bigint,
  r: bigint,
  s: bigint,
): `0x${string}` {
  const clientBytes = new TextEncoder().encode(clientDataJSON);

  // Each head slot = 32 bytes.  7 slots = 7 * 32 = 224 bytes of head.
  const HEAD_BYTES = 7 * 32;

  // Tail: authData length + data (padded) + clientJSON length + data (padded)
  const authPadded   = padTo32(authData.length);
  const authPad      = Math.ceil(authData.length  / 32) * 32;
  const clientPad    = Math.ceil(clientBytes.length / 32) * 32;

  const HEAD_OFFSET_AUTH   = HEAD_BYTES;                                     // after 7 head slots
  const HEAD_OFFSET_CLIENT = HEAD_BYTES + 32 + authPad;                      // after authData tail

  const parts: string[] = [
    // head
    uint256Hex(BigInt(HEAD_OFFSET_AUTH)),                                     // [0] offset authData
    uint256Hex(requireUV ? 1n : 0n),                                          // [1] requireUV
    uint256Hex(BigInt(HEAD_OFFSET_CLIENT)),                                   // [2] offset clientJSON
    uint256Hex(challengeLocation),                                            // [3]
    uint256Hex(responseTypeLocation),                                         // [4]
    uint256Hex(r),                                                            // [5]
    uint256Hex(s),                                                            // [6]
    // tail: authData
    uint256Hex(BigInt(authData.length)),
    bytesToHex(authData).padEnd(authPad * 2, '0'),
    // tail: clientDataJSON
    uint256Hex(BigInt(clientBytes.length)),
    bytesToHex(clientBytes).padEnd(clientPad * 2, '0'),
  ];

  // suppress unused var warning
  void authPadded;

  return ('0x' + parts.join('')) as `0x${string}`;
}

function uint256Hex(n: bigint): string {
  return n.toString(16).padStart(64, '0');
}

function padTo32(n: number): string {
  return n.toString(16).padStart(64, '0');
}
