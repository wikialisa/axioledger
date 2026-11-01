/**
 * WalletHome v3 — iOS-standard Onboarding → Home flow.
 *
 * Screens (finite state machine):
 *   splash → onboarding → register → home
 *
 * Design tokens: --axq-* (primitive / semantic / component layers)
 * Font: Work Sans (loaded via layout.tsx Google Fonts)
 * iOS UI reference: docs/archive/idead/iOS-UI-screens/
 */

'use client';

import { useState } from 'react';
import { useAccount, useConnect, useDisconnect, useReadContract } from 'wagmi';
import { injected } from 'wagmi/connectors';
import {
  Button,
  PasskeyButton,
  AddressDisplay,
  BalanceDisplay,
  Alert,
  useToast,
  type QuickAction,
} from '@axioledger/axio-design-system';
import { AXQ_TOKEN_ABI }        from '../../../../packages/evm-interop/src/abis';
import { ValidatorStatus }       from './ValidatorStatus';
import { InstallValidatorPanel } from './InstallValidatorPanel';
import { CONTRACT_ADDRESSES }    from '../lib/config';

// ── Screen state machine ──────────────────────────────────────────────────────

type Screen = 'splash' | 'onboarding' | 'register' | 'home';

// ── SCREEN: Splash ────────────────────────────────────────────────────────────

function SplashScreen({ onDone }: { onDone: () => void }) {
  return (
    <div style={s.splash}>
      <div style={s.splashInner}>
        {/* Logo mark */}
        <div style={s.splashLogo}>
          <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
            <rect width="64" height="64" rx="20" fill="#000" />
            <path d="M16 48 L32 16 L48 48 M22 36 H42" stroke="#BEFF6C" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <h1 style={s.splashTitle}>Axiopass</h1>
        <p style={s.splashSub}>Web3 Banking · Powered by AXQ</p>
      </div>
      {/* Auto-advance after brief mount — simulated with button for demo */}
      <div style={s.splashBottom}>
        <div style={s.splashLoader}>
          <div style={s.splashLoaderBar} />
        </div>
        <Button variant="ghost" color="black" size="small" onClick={onDone}>
          Skip
        </Button>
      </div>
    </div>
  );
}

// ── SCREEN: Onboarding (3 slides) ─────────────────────────────────────────────

const SLIDES = [
  {
    emoji: '🔑',
    title: 'Your Face IS Your Key',
    body: 'No seed phrase. No MetaMask. Sign every transaction with Face ID or Touch ID — secured by P-256 on-device cryptography.',
    accent: 'var(--axq-p-brand-green)',
  },
  {
    emoji: '💸',
    title: 'Gasless Banking',
    body: 'Send, receive and swap $AXQ tokens without paying gas. KPX paymaster covers fees — you just confirm with your fingerprint.',
    accent: 'var(--axq-p-brand-teal)',
  },
  {
    emoji: '🛡️',
    title: 'ZK Compliance Built-in',
    body: 'VRQ ZK-proof verifies AML compliance without exposing your identity. Stay private while remaining fully compliant.',
    accent: 'var(--axq-p-brand-purple)',
  },
];

function OnboardingScreen({ onDone }: { onDone: () => void }) {
  const [slide, setSlide] = useState(0);
  const current = SLIDES[slide];

  return (
    <div style={s.onboardingPage}>
      {/* Slide content */}
      <div style={s.onboardingSlide}>
        <div style={{ ...s.onboardingEmoji, background: current.accent + '22' }}>
          <span style={{ fontSize: 56 }}>{current.emoji}</span>
        </div>
        <h2 style={s.onboardingTitle}>{current.title}</h2>
        <p style={s.onboardingBody}>{current.body}</p>
      </div>

      {/* Dot indicators */}
      <div style={s.dots}>
        {SLIDES.map((_, i) => (
          <button
            key={i}
            onClick={() => setSlide(i)}
            style={{ ...s.dot, ...(i === slide ? s.dotActive : {}) }}
            aria-label={`Slide ${i + 1}`}
          />
        ))}
      </div>

      {/* Navigation */}
      <div style={s.onboardingActions}>
        {slide < SLIDES.length - 1 ? (
          <>
            <Button variant="filled" color="black" size="giant" fullWidth onClick={() => setSlide(s => s + 1)}>
              Next
            </Button>
            <Button variant="ghost" color="black" size="medium" onClick={onDone}>
              Skip
            </Button>
          </>
        ) : (
          <Button variant="filled" color="black" size="giant" fullWidth onClick={onDone}>
            Get Started
          </Button>
        )}
      </div>
    </div>
  );
}

// ── SCREEN: Register / Connect ─────────────────────────────────────────────────

function RegisterScreen({ onConnected }: { onConnected: () => void }) {
  const { connect } = useConnect();
  const { toast }   = useToast();

  const MOCK_CHALLENGE = 'Y2hhbGxlbmdlX2J5dGVzX2hlcmVfMzI=';

  const handleConnect = () => {
    connect({ connector: injected() });
    onConnected();
  };

  return (
    <div style={s.registerPage}>
      <div style={s.registerTop}>
        <div style={s.registerLogoSmall}>
          <svg width="40" height="40" viewBox="0 0 64 64" fill="none">
            <rect width="64" height="64" rx="20" fill="#000" />
            <path d="M16 48 L32 16 L48 48 M22 36 H42" stroke="#BEFF6C" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <h2 style={s.registerTitle}>Welcome to Axiopass</h2>
        <p style={s.registerSub}>Create or restore your smart wallet</p>
      </div>

      <div style={s.registerCard}>
        {/* Passkey — primary CTA */}
        <div style={s.registerSection}>
          <p style={s.registerLabel}>CREATE NEW WALLET</p>
          <PasskeyButton
            action="register"
            challenge={MOCK_CHALLENGE}
            userName="Axiopass User"
            userId="QXhpb3Bhc3NVc2Vy"
            onSuccess={(cred) => {
              toast.success(`Passkey registered — ID: ${cred.id.slice(0, 12)}…`);
              handleConnect();
            }}
            onError={(msg) => toast.error(`Passkey failed: ${msg}`)}
            label="Create with Face ID / Touch ID"
          />
        </div>

        <div style={s.dividerRow}>
          <div style={s.dividerLine} />
          <span style={s.dividerText}>or</span>
          <div style={s.dividerLine} />
        </div>

        {/* Existing wallet connect */}
        <div style={s.registerSection}>
          <p style={s.registerLabel}>CONNECT EXISTING WALLET</p>
          <Button variant="outlined" color="black" size="large" fullWidth onClick={handleConnect}>
            Connect with MetaMask / Injected
          </Button>
        </div>
      </div>

      <p style={s.registerDisclaimer}>
        By continuing you agree to the{' '}
        <a href="#" style={s.link}>Terms of Service</a> and{' '}
        <a href="#" style={s.link}>Privacy Policy</a>.
      </p>
    </div>
  );
}

// ── SCREEN: Home ──────────────────────────────────────────────────────────────

function HomeScreen() {
  const { address, isConnected } = useAccount();
  const { disconnect }           = useDisconnect();
  const { toast }                = useToast();

  const vrqConfigured = CONTRACT_ADDRESSES.vrqValidator.length > 2;
  const axqConfigured = CONTRACT_ADDRESSES.axqToken.length > 2;

  const { data: balanceRaw } = useReadContract({
    address:      CONTRACT_ADDRESSES.axqToken,
    abi:          AXQ_TOKEN_ABI,
    functionName: 'balanceOf',
    args:         [address ?? '0x0000000000000000000000000000000000000000'],
    query:        { enabled: axqConfigured && isConnected && !!address },
  });

  const balanceFormatted = balanceRaw !== undefined
    ? (Number(balanceRaw) / 1e18).toLocaleString(undefined, { maximumFractionDigits: 4 })
    : '—';

  const quickActions: QuickAction[] = [
    { label: 'Send',    icon: <ArrowUp />,    onClick: () => toast.info('Send — Phase 5') },
    { label: 'Receive', icon: <ArrowDown />,  onClick: () => toast.info('Receive — Phase 5') },
    { label: 'Swap',    icon: <SwapIcon />,   onClick: () => toast.info('Swap — Phase 5') },
    { label: 'Buy',     icon: <PlusIcon />,   onClick: () => toast.info('Buy — Phase 5') },
  ];

  return (
    <div style={s.homePage}>

      {/* ── Top bar ── */}
      <header style={s.homeHeader}>
        <div style={s.homeHeaderLeft}>
          <div style={s.homeAvatar}>A</div>
          <div>
            <p style={s.homeGreeting}>Good morning 👋</p>
            {address && <AddressDisplay address={address} showBadge showCopy />}
          </div>
        </div>
        <button
          style={s.homeNotif}
          onClick={() => toast.info('Notifications — Phase 5')}
          aria-label="Notifications"
        >
          <BellIcon />
        </button>
      </header>

      {/* ── Config notice ── */}
      {!axqConfigured && (
        <div style={{ marginBottom: 16 }}>
          <Alert variant="info" title="Localnet mode">
            Running without live contracts. Set <code>NEXT_PUBLIC_AXQ_TOKEN</code> to enable balance.
          </Alert>
        </div>
      )}

      {/* ── Balance tile ── */}
      <div style={s.balanceTile}>
        <BalanceDisplay
          fiatAmount={`${balanceFormatted} AXQ`}
          balanceLabel="Total Balance"
          actions={quickActions}
        />
      </div>

      {/* ── Quick stats ── */}
      <div style={s.statsRow}>
        {[
          { label: 'Portfolio', value: '—', icon: '📈' },
          { label: 'Staking',   value: '—', icon: '🔒' },
          { label: 'Cashback',  value: '—', icon: '🎁' },
        ].map(({ label, value, icon }) => (
          <div key={label} style={s.statChip}>
            <span style={s.statChipIcon}>{icon}</span>
            <span style={s.statChipLabel}>{label}</span>
            <span style={s.statChipValue}>{value}</span>
          </div>
        ))}
      </div>

      {/* ── VRQ Validator section ── */}
      {isConnected && vrqConfigured && address && (
        <div style={s.section}>
          <p style={s.sectionTitle}>ZK Compliance Module</p>
          <ValidatorStatus
            validatorAddress={CONTRACT_ADDRESSES.vrqValidator}
            smartAccount={address}
          />
          <InstallValidatorPanel
            validatorAddress={CONTRACT_ADDRESSES.vrqValidator}
            onInstalled={() =>
              toast.success('VRQPasskeyValidator installed ✓')
            }
          />
        </div>
      )}

      {/* ── Protocol cards ── */}
      <div style={s.section}>
        <p style={s.sectionTitle}>Protocol Features</p>
        <div style={s.protoGrid}>
          {PROTO_CARDS.map(({ title, body, accent, emoji }) => (
            <div key={title} style={{ ...s.protoCard, borderTopColor: accent }}>
              <span style={{ fontSize: 20, marginBottom: 8, display: 'block' }}>{emoji}</span>
              <p style={s.protoCardTitle}>{title}</p>
              <p style={s.protoCardBody}>{body}</p>
            </div>
          ))}
        </div>
      </div>

      {/* ── Disconnect ── */}
      <div style={{ textAlign: 'center', marginTop: 24 }}>
        <Button
          variant="ghost"
          color="black"
          size="small"
          onClick={() => { disconnect(); toast.info('Wallet disconnected'); }}
        >
          Disconnect Wallet
        </Button>
      </div>
    </div>
  );
}

// ── Root: WalletHome (state machine) ─────────────────────────────────────────

export function WalletHome() {
  const { isConnected } = useAccount();
  const [screen, setScreen] = useState<Screen>('splash');

  // Auto-advance to home if already connected
  if (isConnected && screen !== 'home') {
    return <HomeScreen />;
  }

  if (screen === 'splash')      return <SplashScreen    onDone={() => setScreen('onboarding')} />;
  if (screen === 'onboarding')  return <OnboardingScreen onDone={() => setScreen('register')} />;
  if (screen === 'register')    return <RegisterScreen   onConnected={() => setScreen('home')} />;
  return <HomeScreen />;
}

// ── Icons (inline SVG — no external dep) ─────────────────────────────────────

const ArrowUp  = () => <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 14V6m0 0L6 10m4-4 4 4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/></svg>;
const ArrowDown= () => <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 6v8m0 0-4-4m4 4 4-4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/></svg>;
const SwapIcon = () => <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M13 4l3 3-3 3M7 16l-3-3 3-3M16 7H8M4 13h8" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/></svg>;
const PlusIcon = () => <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 4v12M4 10h12" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/></svg>;
const BellIcon = () => <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6 6 0 10-12 0v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></svg>;

// ── Static content ────────────────────────────────────────────────────────────

const PROTO_CARDS = [
  { emoji: '🔑', accent: 'var(--axq-p-brand-green)',  title: 'ERC-7579 Validator',  body: 'Biometric passkeys replace seed phrases via Daimo P256Verifier.' },
  { emoji: '⚡', accent: 'var(--axq-p-brand-teal)',   title: 'Gasless via KPX',     body: 'KPXRouterGateway paymaster covers all Sepolia gas fees.' },
  { emoji: '🛡️', accent: 'var(--axq-p-brand-purple)', title: 'VRQ ZK Gate',         body: 'AML-compliant ZK proof — privacy preserved on every tx.' },
  { emoji: '🏛️', accent: 'var(--axq-p-brand-orange)', title: 'DAO Governed',        body: 'AXQ governance controls upgrades via 7-day timelock.' },
];

// ── Design token styles ───────────────────────────────────────────────────────

const s: Record<string, React.CSSProperties> = {

  // ── Splash
  splash: {
    minHeight: '100dvh',
    display: 'flex', flexDirection: 'column', justifyContent: 'space-between',
    alignItems: 'center',
    background: 'var(--axq-p-grey-900)',
    padding: '0 24px 40px',
  },
  splashInner: {
    flex: 1, display: 'flex', flexDirection: 'column',
    alignItems: 'center', justifyContent: 'center', gap: 16,
  },
  splashLogo:  { filter: 'drop-shadow(0 0 32px rgba(190,255,108,0.35))' },
  splashTitle: {
    margin: 0, color: '#fff',
    fontSize: 'var(--axq-p-size-34)', fontWeight: 'var(--axq-p-weight-semibold)' as any,
    letterSpacing: '-0.5px',
  },
  splashSub: { margin: 0, color: 'var(--axq-p-dark-text-2)', fontSize: 'var(--axq-p-size-14)' },
  splashBottom:   { display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16, width: '100%' },
  splashLoader:   { width: '100%', maxWidth: 200, height: 4, borderRadius: 99, background: 'rgba(255,255,255,0.1)', overflow: 'hidden' },
  splashLoaderBar:{ height: '100%', width: '60%', background: 'var(--axq-p-brand-green)', borderRadius: 99, animation: 'none' },

  // ── Onboarding
  onboardingPage: {
    minHeight: '100dvh', display: 'flex', flexDirection: 'column',
    padding: '64px 24px 40px',
    background: 'var(--axq-color-bg-surface)',
  },
  onboardingSlide: { flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 24 },
  onboardingEmoji: { width: 120, height: 120, borderRadius: 40, display: 'flex', alignItems: 'center', justifyContent: 'center' },
  onboardingTitle: {
    margin: 0, fontSize: 'var(--axq-p-size-24)',
    fontWeight: 'var(--axq-p-weight-semibold)' as any,
    color: 'var(--axq-color-text-primary)', letterSpacing: '-0.3px',
  },
  onboardingBody: {
    margin: 0, fontSize: 'var(--axq-p-size-16)',
    color: 'var(--axq-color-text-secondary)', lineHeight: 1.6, maxWidth: 320,
  },
  dots: { display: 'flex', justifyContent: 'center', gap: 8, margin: '32px 0' },
  dot: {
    width: 8, height: 8, borderRadius: 99, border: 'none', cursor: 'pointer', padding: 0,
    background: 'var(--axq-color-border-strong)', transition: 'all 0.2s',
  },
  dotActive: { width: 24, background: 'var(--axq-p-grey-900)' },
  onboardingActions: { display: 'flex', flexDirection: 'column', gap: 12 },

  // ── Register
  registerPage: {
    minHeight: '100dvh', display: 'flex', flexDirection: 'column',
    padding: '56px 24px 40px',
    background: 'var(--axq-color-bg-surface)',
  },
  registerTop:       { display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12, marginBottom: 32 },
  registerLogoSmall: {},
  registerTitle: {
    margin: 0, fontSize: 'var(--axq-p-size-24)',
    fontWeight: 'var(--axq-p-weight-semibold)' as any,
    color: 'var(--axq-color-text-primary)', textAlign: 'center',
  },
  registerSub:  { margin: 0, fontSize: 'var(--axq-p-size-14)', color: 'var(--axq-color-text-secondary)', textAlign: 'center' },
  registerCard: {
    background: 'var(--axq-color-surface-raised)',
    border: '1px solid var(--axq-color-border-default)',
    borderRadius: 'var(--axq-p-radius-2xl)',
    padding: '24px 20px', display: 'flex', flexDirection: 'column', gap: 20,
  },
  registerSection:     { display: 'flex', flexDirection: 'column', gap: 12 },
  registerLabel: {
    margin: 0, fontSize: 'var(--axq-p-size-10)',
    fontWeight: 'var(--axq-p-weight-medium)' as any,
    color: 'var(--axq-color-text-secondary)', letterSpacing: '1px',
  },
  dividerRow:  { display: 'flex', alignItems: 'center', gap: 12 },
  dividerLine: { flex: 1, height: 1, background: 'var(--axq-color-border-default)' },
  dividerText: { fontSize: 'var(--axq-p-size-12)', color: 'var(--axq-color-text-secondary)' },
  registerDisclaimer: {
    marginTop: 24, textAlign: 'center',
    fontSize: 'var(--axq-p-size-12)', color: 'var(--axq-color-text-secondary)', lineHeight: 1.6,
  },
  link: { color: 'var(--axq-color-text-link)', textDecoration: 'none' },

  // ── Home
  homePage: {
    maxWidth: 480, margin: '0 auto',
    padding: '20px 20px 48px',
    fontFamily: 'var(--axq-font-family)',
    background: 'var(--axq-color-bg-surface)',
    minHeight: '100dvh',
  },
  homeHeader: {
    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    marginBottom: 20,
  },
  homeHeaderLeft: { display: 'flex', alignItems: 'center', gap: 12 },
  homeAvatar: {
    width: 44, height: 44, borderRadius: 99,
    background: 'var(--axq-p-grey-900)',
    color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: 'var(--axq-p-size-16)', fontWeight: 'var(--axq-p-weight-semibold)' as any,
    flexShrink: 0,
  },
  homeGreeting: { margin: '0 0 2px', fontSize: 'var(--axq-p-size-12)', color: 'var(--axq-color-text-secondary)' },
  homeNotif: {
    width: 44, height: 44, borderRadius: 99,
    border: '1px solid var(--axq-color-border-default)',
    background: 'var(--axq-color-surface-raised)',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    cursor: 'pointer', color: 'var(--axq-color-text-primary)',
  },
  balanceTile: {
    borderRadius: 'var(--axq-p-radius-2xl)',
    overflow: 'hidden', marginBottom: 16,
    boxShadow: '0 4px 24px rgba(0,0,0,0.08)',
  },
  statsRow: { display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 10, marginBottom: 24 },
  statChip: {
    display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
    background: 'var(--axq-color-surface-raised)',
    border: '1px solid var(--axq-color-border-default)',
    borderRadius: 'var(--axq-p-radius-xl)',
    padding: '14px 8px', textAlign: 'center',
  },
  statChipIcon:  { fontSize: 20 },
  statChipLabel: { fontSize: 'var(--axq-p-size-10)', color: 'var(--axq-color-text-secondary)', fontWeight: 'var(--axq-p-weight-medium)' as any, letterSpacing: '0.5px' },
  statChipValue: { fontSize: 'var(--axq-p-size-14)', fontWeight: 'var(--axq-p-weight-semibold)' as any, color: 'var(--axq-color-text-primary)' },
  section:      { marginBottom: 24 },
  sectionTitle: { margin: '0 0 12px', fontSize: 'var(--axq-p-size-12)', fontWeight: 'var(--axq-p-weight-semibold)' as any, color: 'var(--axq-color-text-secondary)', letterSpacing: '0.8px', textTransform: 'uppercase' },
  protoGrid: { display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 12 },
  protoCard: {
    background: 'var(--axq-color-surface-raised)',
    border: '1px solid var(--axq-color-border-default)',
    borderTop: '3px solid', borderRadius: 'var(--axq-p-radius-xl)',
    padding: '16px 14px',
  },
  protoCardTitle: { margin: '0 0 6px', fontSize: 'var(--axq-p-size-12)', fontWeight: 'var(--axq-p-weight-semibold)' as any, color: 'var(--axq-color-text-primary)' },
  protoCardBody:  { margin: 0, fontSize: 'var(--axq-p-size-12)', color: 'var(--axq-color-text-secondary)', lineHeight: 1.5 },
};
