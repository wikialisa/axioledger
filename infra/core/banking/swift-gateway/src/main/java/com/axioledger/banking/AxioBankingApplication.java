package com.axioledger.banking;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * AXIO Banking Translator Service — entry point.
 *
 * <p>Must run co-located with the SWIFT Microgateway on the dedicated banking server
 * ({@code /mnt/q/core/banking/}) to satisfy PCI DSS isolation (DP-4 equivalent for
 * the banking partition).
 *
 * <p>Active profile selection:
 * <ul>
 *   <li>{@code sandbox} — SWIFT Sandbox (v0.1.0 / v0.2.0 auth testing)</li>
 *   <li>{@code production} — Locked until v1.1.0 Mainnet Gate G3 (TVL ≥ $10B)</li>
 * </ul>
 */
@SpringBootApplication
public class AxioBankingApplication {

    public static void main(String[] args) {
        SpringApplication.run(AxioBankingApplication.class, args);
    }
}
