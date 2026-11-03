/**
 * @axioledger/robotics
 *
 * Hardware Abstraction Layer (HAL), trajectory & motor control interfaces.
 * Depends on: @axioledger/math, @axioledger/iot
 */
import type { Vec3 } from '@axioledger/math';

// ── Joint / motor abstraction ─────────────────────────────────────────────────

export interface JointState {
  /** Current angle in radians */
  angle: number;
  /** Angular velocity rad/s */
  velocity: number;
  /** Applied torque Nm */
  torque: number;
}

export interface MotorController {
  id: string;
  setTargetAngle(radians: number): Promise<void>;
  getState(): Promise<JointState>;
}

// ── Kinematic chain ───────────────────────────────────────────────────────────

export interface KinematicChain {
  joints: MotorController[];
  /** Forward-kinematics: compute end-effector position from joint angles */
  forwardKinematics(angles: number[]): Vec3;
}

// ── HAL factory (platform-specific drivers implement this interface) ───────────

export interface HAL {
  motors: MotorController[];
  connect(): Promise<void>;
  disconnect(): Promise<void>;
}
