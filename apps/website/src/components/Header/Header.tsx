import styles from './Header.module.css';

const BASE = process.env.NEXT_PUBLIC_BASE_PATH ?? '/axioledger';

const NAV_LINKS = [
  { href: '#ecosystem', label: 'Ecosystem' },
  { href: '#products',  label: 'Products'  },
  { href: '#docs',      label: 'Docs'      },
  { href: '#community', label: 'Community' },
];

export default function Header() {
  return (
    <header className={styles.header} role="banner">
      <div className={`container ${styles.inner}`}>
        {/* Logo */}
        <a href={`${BASE}/`} className={styles.logo} aria-label="AXIOLEDGER home">
          <LogoMark />
          <span className={styles.logoText}>AXIOLEDGER</span>
          <span className={styles.ticker}>$AXQ</span>
        </a>

        {/* Nav */}
        <nav aria-label="Main navigation">
          <ul className={styles.navList}>
            {NAV_LINKS.map(({ href, label }) => (
              <li key={href}>
                <a href={href} className={styles.navLink}>{label}</a>
              </li>
            ))}
          </ul>
        </nav>

        {/* CTA */}
        <a
          href="https://github.com/axioledger/axioledger"
          target="_blank"
          rel="noopener noreferrer"
          className={styles.ctaButton}
        >
          GitHub ↗
        </a>
      </div>
    </header>
  );
}

/** Inline SVG — no external asset required */
function LogoMark() {
  return (
    <svg
      width="28"
      height="28"
      viewBox="0 0 28 28"
      fill="none"
      aria-hidden="true"
      xmlns="http://www.w3.org/2000/svg"
    >
      <polygon
        points="14,2 26,21 2,21"
        stroke="#49DBC8"
        strokeWidth="2"
        fill="none"
        strokeLinejoin="round"
      />
      <polygon
        points="14,8 22,21 6,21"
        fill="#49DBC8"
        opacity="0.25"
      />
      <line x1="14" y1="2" x2="14" y2="21" stroke="#BEFF6C" strokeWidth="1.5" opacity="0.7" />
    </svg>
  );
}
