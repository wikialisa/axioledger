import styles from './Footer.module.css';

const YEAR = new Date().getFullYear();

const FOOTER_LINKS = [
  {
    heading: 'Protocol',
    links: [
      { label: 'GitHub',      href: 'https://github.com/axioledger/axioledger' },
      { label: 'Whitepaper',  href: 'https://github.com/axioledger/axioledger/blob/main/docs/Whitepaper%20AXIOLEDGER%20(%24AXQ).md' },
      { label: 'Charter',     href: 'https://github.com/axioledger/axioledger/blob/main/docs/AXIOLEDGER-OFFICIAL-CHARTER.md' },
      { label: 'Blueprint',   href: 'https://github.com/axioledger/axioledger/blob/main/docs/AXIOLEDGER_TECHNICAL_BLUEPRINT.md' },
    ],
  },
  {
    heading: 'Applications',
    links: [
      { label: 'Axiopass Wallet',  href: 'https://github.com/axioledger/axioledger/tree/main/apps/axiopass-wallet' },
      { label: 'Governance UI',    href: 'https://github.com/axioledger/axioledger/tree/main/apps/axq-governance-ui' },
      { label: 'KPX DEX',         href: 'https://github.com/axioledger/axioledger/tree/main/apps/kpx-dex-frontend' },
    ],
  },
  {
    heading: 'Project',
    links: [
      { label: 'Contributing',    href: 'https://github.com/axioledger/axioledger/blob/main/CONTRIBUTING.md' },
      { label: 'Security Policy', href: 'https://github.com/axioledger/axioledger/blob/main/SECURITY.md' },
      { label: 'License (BSL 1.1)', href: 'https://github.com/axioledger/axioledger/blob/main/LICENSE' },
      { label: 'Code of Conduct', href: 'https://github.com/axioledger/axioledger/blob/main/CODE_OF_CONDUCT.md' },
    ],
  },
];

export default function Footer() {
  return (
    <footer className={styles.footer} role="contentinfo">
      <div className={`container ${styles.inner}`}>
        {/* Link columns */}
        <div className={styles.columns}>
          {FOOTER_LINKS.map(({ heading, links }) => (
            <div key={heading} className={styles.column}>
              <h3 className={styles.columnHeading}>{heading}</h3>
              <ul className={styles.linkList}>
                {links.map(({ label, href }) => (
                  <li key={label}>
                    <a
                      href={href}
                      target={href.startsWith('http') ? '_blank' : undefined}
                      rel={href.startsWith('http') ? 'noopener noreferrer' : undefined}
                      className={styles.link}
                    >
                      {label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Bottom bar */}
        <div className={styles.bottom}>
          <p className={styles.copyright}>
            © {YEAR} AXIOLEDGER contributors. Core licensed under{' '}
            <a
              href="https://github.com/axioledger/axioledger/blob/main/LICENSE"
              target="_blank"
              rel="noopener noreferrer"
            >
              BSL 1.1
            </a>
            . SDKs: MIT / Apache-2.0.
          </p>
          <p className={styles.disclaimer}>
            This website is maintained by the Wikialisa fork for documentation purposes.
            Content is provided as-is and may not reflect the latest upstream changes.
          </p>
        </div>
      </div>
    </footer>
  );
}
