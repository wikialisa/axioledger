import jwt from "jsonwebtoken";

function requireEnv(name: string): string {
  const val = process.env[name];
  if (!val) throw new Error(`Missing required environment variable: ${name}`);
  return val;
}

const ACCESS_SECRET  = requireEnv("JWT_SECRET");
const REFRESH_SECRET = requireEnv("REFRESH_TOKEN_SECRET");
const ACCESS_EXPIRE  = process.env.JWT_EXPIRE ?? "15m";
const REFRESH_EXPIRE = process.env.REFRESH_TOKEN_EXPIRE ?? "7d";

export interface JWTPayload {
  sub: string;      // userId
  role: "user" | "admin" | "compliance";
  iat?: number;
  exp?: number;
}

export function signAccessToken(payload: Omit<JWTPayload, "iat" | "exp">): string {
  return jwt.sign(payload, ACCESS_SECRET, { expiresIn: ACCESS_EXPIRE } as jwt.SignOptions);
}

export function signRefreshToken(payload: Omit<JWTPayload, "iat" | "exp">): string {
  return jwt.sign(payload, REFRESH_SECRET, { expiresIn: REFRESH_EXPIRE } as jwt.SignOptions);
}

export function verifyAccessToken(token: string): JWTPayload {
  return jwt.verify(token, ACCESS_SECRET) as JWTPayload;
}

export function verifyRefreshToken(token: string): JWTPayload {
  return jwt.verify(token, REFRESH_SECRET) as JWTPayload;
}
