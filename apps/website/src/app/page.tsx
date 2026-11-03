import type { Metadata } from 'next';
import Header from '@/components/Header/Header';
import Footer from '@/components/Footer/Footer';
import styles from './page.module.css';

export const metadata: Metadata = {
  title: 'AXIOLEDGER ($AXQ) — Web3 Financial Infrastructure',
};

// ── Data ─────────────────────────────────────────────────────────────────────

const PILLARS = [
  {
    token: '$VPX',
    org: 'VALIPRECISION',
    role: 'Oracle Network',
    color: 'var(--axq-teal)',
    description:
      'Multi-client Rust + C++ oracle node providing price consensus with RAMDISK-optimised I/O and NVMe-partitioned storage.',
    items: ['ZK-OBFT consensus', 'RAMDISK I/O', 'NVMe partitioned', 'Price feed daemon'],
  },
  {
    token: '$SQX',
    org: 'SEQUENTICHAIN',
    role: 'L2 Scaling',
    color: 'var(--axq-purple)',
    description:
      'High-speed L2 execution layer using SVM Rollup + AF_XDP NIC bypass for sub-3-minute finality and 600K+ TPS throughput.',
    items: ['SVM Rollup', 'AF_XDP NIC Bypass', '600K+ TPS target', 'ZK-Rollup settlement'],
  },
  {
    token: '$KPX',
    org: 'KINETOPROTOCOL',
    role: 'DeFi Liquidity',
    color: 'var(--axq-green)',
    description:
      'AMM pools, cross-chain bridge, RWA treasury, dark-pool LP markets and gasless swap routing — the full DeFi engine.',
    items: ['AMM Router', 'Cross-chain bridge', 'RWA Treasury', 'Dark Pool LP'],
  },
  {
    token: '$VRQ',
    org: 'VERACIPHERS',
    role: 'ZK-Security',
    color: 'var(--axq-orange)',
    description:
      'Zero-knowledge proofs, decentralised identity (ZK-DID), passkey-native smart wallet, regulator gateway and supply-chain scanner.',
    items: ['ZK-Proof', 'DID / KYC', 'Regulator Gateway', 'Confidential Transfers'],
  },
];

const PRODUCTS = [
  {
    name: 'Axiopass Wallet',
    type: 'PWA · Smart Wallet',
    description: 'Passkey-native smart wallet. FaceID / TouchID replaces seed phrase. VRQPasskeyValidator deployed on Sepolia.',
    href: 'https://github.com/axioledger/axioledger/tree/main/apps/axiopass-wallet',
    status: 'v1 on Sepolia',
  },
  {
    name: 'Governance UI',
    type: 'DAO Dashboard',
    description: 'On-chain DAO voting, proposal lifecycle and treasury dashboard wired to AXQGovernance contracts.',
    href: 'https://github.com/axioledger/axioledger/tree/main/apps/axq-governance-ui',
    status: 'v1 live',
  },
  {
    name: 'KPX DEX',
    type: 'Decentralised Exchange',
    description: 'Gasless swap UI on KPX AMM router. Liquidity pool management and cross-chain routing interface.',
    href: 'https://github.com/axioledger/axioledger/tree/main/apps/kpx-dex-frontend',
    status: 'Scaffold',
  },
  {
    name: 'AXQ SDK',
    type: 'TypeScript SDK',
    description: 'Client library for on-chain interactions: AXQToken, ANSRegistry, and wagmi hook factories for EVM.',
    href: 'https://github.com/axioledger/axioledger/tree/main/packages/axq-sdk',
    status: 'v0.2.0',
  },
  {
    name: 'ANS Resolver',
    type: 'Domain SDK',
    description: 'Resolve and register .axq / .vpx / .sqx / .kpx / .vrq domains. 15 tests, 85.7% coverage.',
    href: 'https://github.com/axioledger/axioledger/tree/main/packages/ans-resolver',
    status: 'v1',
  },
  {
    name: 'Design System',
    type: 'Component Library',
    description: '@veraciphers/axio-design-system v4.0.0 — tokens, components and guidelines for all AXIOLEDGER apps.',
    href: 'https://github.com/axioledger/axioledger/tree/main/design-system',
    status: 'v4.0.0',
  },
];

const DOCS = [
  {
    title: 'Official Charter',
    description: 'Founding principles, 1 Hub & 4 Pillars architecture, governance structure and roadmap.',
    href: 'https://github.com/axioledger/axioledger/blob/main/docs/AXIOLEDGER-OFFICIAL-CHARTER.md',
  },
  {
    title: 'Whitepaper ($AXQ)',
    description: 'Economic model, tokenomics (500B $AXQ), validator incentives and deflationary mechanics.',
    href: 'https://github.com/axioledger/axioledger/blob/main/docs/Whitepaper%20AXIOLEDGER%20(%24AXQ).md',
  },
  {
    title: 'Technical Blueprint',
    description: 'Deep dive into ZK-OBFT consensus, SVM rollup design, AF_XDP bypass and smart contract architecture.',
    href: 'https://github.com/axioledger/axioledger/blob/main/docs/AXIOLEDGER_TECHNICAL_BLUEPRINT.md',
  },
  {
    title: 'Software Technical Spec',
    description: 'Interface specs, API contracts, ABI catalogue and cross-package dependency map.',
    href: 'https://github.com/axioledger/axioledger/blob/main/docs/SOFTWARE-TECHNICAL-SPEC.md',
  },
];

// ── Page ──────────────────────────────────────────────────────────────────────

export default function HomePage() {
  return (
    <>
      <Header />

      <main>
        {/* ── Hero ─────────────────────────────────────────────────────────── */}
        <section className={styles.hero} aria-labelledby="hero-heading">
          <div className="container">
            <div className={styles.heroBadge}>Hub &amp; 4 Pillars · ZK-OBFT · 600K+ TPS target</div>
            <h1 id="hero-heading" className={styles.heroHeading}>
              Web3 Financial<br />
              <span className={styles.heroAccent}>Operating System</span>
            </h1>
            <p className={styles.heroLead}>
              AXIOLEDGER ($AXQ) is a high-performance, privacy-preserving, multi-chain
              protocol — combining ZK-proof security, decentralised identity and on-chain
              governance into one unified infrastructure layer.
            </p>
            <div className={styles.heroCtas}>
              <a
                href="https://github.com/axioledger/axioledger"
                target="_blank"
                rel="noopener noreferrer"
                className={styles.btnPrimary}
              >
                View on GitHub ↗
              </a>
              <a href="#docs" className={styles.btnSecondary}>
                Read the docs
              </a>
            </div>

            {/* Stats row */}
            <div className={styles.statsRow}>
              {[
                { value: '500k+', label: 'Lines of code' },
                { value: '14',    label: 'Workspaces' },
                { value: '5',     label: 'Organisations' },
                { value: '7',     label: 'Phase roadmap' },
              ].map(({ value, label }) => (
                <div key={label} className={styles.stat}>
                  <span className={styles.statValue}>{value}</span>
                  <span className={styles.statLabel}>{label}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── Ecosystem / Architecture ──────────────────────────────────────── */}
        <section id="ecosystem" className={styles.section} aria-labelledby="ecosystem-heading">
          <div className="container">
            <div className={styles.sectionHeader}>
              <p className={styles.sectionEyebrow}>Architecture</p>
              <h2 id="ecosystem-heading" className={styles.sectionTitle}>
                1 Hub · 4 Pillars
              </h2>
              <p className={styles.sectionLead}>
                AXIOLEDGER is the governance hub. Four specialised pillar organisations
                deliver oracle consensus, L2 scaling, DeFi liquidity and ZK-security —
                each with its own token and codebase, unified under the $AXQ protocol.
              </p>
            </div>

            {/* Hub card */}
            <div className={styles.hubCard}>
              <div className={styles.hubLeft}>
                <span className={styles.hubToken}>$AXQ</span>
                <h3 className={styles.hubTitle}>AXIOLEDGER — Core Hub</h3>
              </div>
              <p className={styles.hubDesc}>
                Immutable settlement ledger · DAO &amp; Treasury · On-chain governance ·
                ANS domain registry · Post-quantum cryptography (Lattice-based)
              </p>
            </div>

            {/* Pillar grid */}
            <div className={styles.pillarGrid}>
              {PILLARS.map((p) => (
                <article key={p.token} className={styles.pillarCard} style={{ '--pillar-color': p.color } as React.CSSProperties}>
                  <div className={styles.pillarHeader}>
                    <span className={styles.pillarToken} style={{ color: p.color }}>{p.token}</span>
                    <span className={styles.pillarOrg}>{p.org}</span>
                    <span className={styles.pillarRole}>{p.role}</span>
                  </div>
                  <p className={styles.pillarDesc}>{p.description}</p>
                  <ul className={styles.pillarItems}>
                    {p.items.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* ── Products ─────────────────────────────────────────────────────── */}
        <section id="products" className={styles.section} aria-labelledby="products-heading">
          <div className="container">
            <div className={styles.sectionHeader}>
              <p className={styles.sectionEyebrow}>Products</p>
              <h2 id="products-heading" className={styles.sectionTitle}>
                Applications &amp; SDKs
              </h2>
              <p className={styles.sectionLead}>
                Each application and SDK is an independent workspace in the monorepo,
                with its own CI pipeline, versioning and deployment target.
              </p>
            </div>

            <div className={styles.productGrid}>
              {PRODUCTS.map((p) => (
                <a
                  key={p.name}
                  href={p.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.productCard}
                >
                  <div className={styles.productTop}>
                    <div>
                      <span className={styles.productType}>{p.type}</span>
                      <h3 className={styles.productName}>{p.name}</h3>
                    </div>
                    <span className={styles.productStatus}>{p.status}</span>
                  </div>
                  <p className={styles.productDesc}>{p.description}</p>
                  <span className={styles.productCta}>View source ↗</span>
                </a>
              ))}
            </div>
          </div>
        </section>

        {/* ── Docs ─────────────────────────────────────────────────────────── */}
        <section id="docs" className={styles.section} aria-labelledby="docs-heading">
          <div className="container">
            <div className={styles.sectionHeader}>
              <p className={styles.sectionEyebrow}>Documentation</p>
              <h2 id="docs-heading" className={styles.sectionTitle}>
                Official Documents
              </h2>
            </div>

            <div className={styles.docsGrid}>
              {DOCS.map((d) => (
                <a
                  key={d.title}
                  href={d.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.docCard}
                >
                  <h3 className={styles.docTitle}>{d.title}</h3>
                  <p className={styles.docDesc}>{d.description}</p>
                  <span className={styles.docCta}>Read on GitHub ↗</span>
                </a>
              ))}
            </div>
          </div>
        </section>

        {/* ── Community ────────────────────────────────────────────────────── */}
        <section id="community" className={styles.section} aria-labelledby="community-heading">
          <div className="container">
            <div className={styles.communityBox}>
              <h2 id="community-heading" className={styles.communityTitle}>
                Build with AXIOLEDGER
              </h2>
              <p className={styles.communityLead}>
                The monorepo is open for contributions. Start by reading the contributing
                guide, then open a pull request against the upstream repository.
              </p>
              <div className={styles.communityLinks}>
                <a
                  href="https://github.com/axioledger/axioledger"
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.btnPrimary}
                >
                  axioledger/axioledger ↗
                </a>
                <a
                  href="https://github.com/axioledger/axioledger/blob/main/CONTRIBUTING.md"
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.btnSecondary}
                >
                  Contributing Guide
                </a>
                <a
                  href="https://github.com/axioledger/axioledger/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                  className={styles.btnSecondary}
                >
                  Open Issues
                </a>
              </div>
            </div>
          </div>
        </section>
      </main>

      <Footer />
    </>
  );
}
