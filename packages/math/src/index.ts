/**
 * @axioledger/math
 *
 * Vector/Matrix math, fixed-point calculation, computational geometry.
 * Depends on: @axioledger/core
 */

// ── Vec2 ──────────────────────────────────────────────────────────────────────

export interface Vec2 { x: number; y: number }

export const vec2 = {
  add:   (a: Vec2, b: Vec2): Vec2 => ({ x: a.x + b.x, y: a.y + b.y }),
  sub:   (a: Vec2, b: Vec2): Vec2 => ({ x: a.x - b.x, y: a.y - b.y }),
  scale: (v: Vec2, s: number): Vec2 => ({ x: v.x * s, y: v.y * s }),
  dot:   (a: Vec2, b: Vec2): number => a.x * b.x + a.y * b.y,
  len:   (v: Vec2): number => Math.sqrt(v.x ** 2 + v.y ** 2),
  norm:  (v: Vec2): Vec2 => { const l = vec2.len(v); return { x: v.x / l, y: v.y / l }; },
};

// ── Vec3 ──────────────────────────────────────────────────────────────────────

export interface Vec3 { x: number; y: number; z: number }

export const vec3 = {
  add:    (a: Vec3, b: Vec3): Vec3 => ({ x: a.x + b.x, y: a.y + b.y, z: a.z + b.z }),
  sub:    (a: Vec3, b: Vec3): Vec3 => ({ x: a.x - b.x, y: a.y - b.y, z: a.z - b.z }),
  scale:  (v: Vec3, s: number): Vec3 => ({ x: v.x * s, y: v.y * s, z: v.z * s }),
  dot:    (a: Vec3, b: Vec3): number => a.x * b.x + a.y * b.y + a.z * b.z,
  cross:  (a: Vec3, b: Vec3): Vec3 => ({
    x: a.y * b.z - a.z * b.y,
    y: a.z * b.x - a.x * b.z,
    z: a.x * b.y - a.y * b.x,
  }),
  len:    (v: Vec3): number => Math.sqrt(v.x ** 2 + v.y ** 2 + v.z ** 2),
  norm:   (v: Vec3): Vec3 => { const l = vec3.len(v); return { x: v.x / l, y: v.y / l, z: v.z / l }; },
};

// ── Mat4 (column-major, WebGL-compatible) ─────────────────────────────────────

export type Mat4 = readonly [
  number, number, number, number,
  number, number, number, number,
  number, number, number, number,
  number, number, number, number,
];

export function mat4Identity(): Mat4 {
  return [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1];
}

// ── Fixed-point helpers ────────────────────────────────────────────────────────

/** Scale factor for 18-decimal fixed-point (matches EVM standard). */
export const FIXED_18 = BigInt('1000000000000000000');

export const fixed18 = {
  fromNumber: (n: number): bigint => BigInt(Math.round(n * 1e18)),
  toNumber:   (fp: bigint): number => Number(fp) / 1e18,
  mul:        (a: bigint, b: bigint): bigint => (a * b) / FIXED_18,
};
