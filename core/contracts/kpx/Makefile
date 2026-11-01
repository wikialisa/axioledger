# AXIOLEDGER KPX Router — Foundry Test Runner
# Usage: make test | make fuzz | make snapshot | make coverage

FOUNDRY_PROFILE ?= default

.PHONY: install test fuzz snapshot coverage clean slither

install:
	forge install OpenZeppelin/openzeppelin-contracts --no-commit
	forge install foundry-rs/forge-std --no-commit
	@echo "[✓] Dependencies installed"

test:
	forge test --match-path "test/KPXRouterGateway.t.sol" -vvvv
	@echo "[✓] All tests complete"

fuzz:
	forge test --match-path "test/KPXRouterGateway.t.sol" \
	           --fuzz-runs 10000 \
	           --match-test "testFuzz" -vvv
	@echo "[✓] Fuzz complete — 10,000 runs"

reentrancy:
	forge test --match-path "test/KPXRouterGateway.t.sol" \
	           --match-test "test_T3" -vvvv
	@echo "[✓] Reentrancy tests complete"

snapshot:
	forge snapshot --match-path "test/KPXRouterGateway.t.sol"

coverage:
	forge coverage --match-path "test/KPXRouterGateway.t.sol" \
	               --report lcov
	@echo "[✓] Coverage report: lcov.info"

clean:
	forge clean

# Static analysis — yêu cầu slither
slither:
	slither KPXRouterGateway.sol \
	        --exclude-dependencies \
	        --filter-paths "test/" \
	        --checkers reentrancy,arbitrary-send,controlled-delegatecall
	@echo "[✓] Slither analysis complete"

# Full pre-deploy checklist
pre-deploy: test fuzz coverage slither
	@echo ""
	@echo "══════════════════════════════════════════════"
	@echo "  PRE-DEPLOY CHECKS COMPLETE"
	@echo "  Verify: All 30 items in KPXRouter-security-review.md"
	@echo "  Next:   External audit → DAO vote → 48h timelock"
	@echo "══════════════════════════════════════════════"
