// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER ($AXQ) - Tokenomics Allocation Contract
//
// Supply: 500,000,000,000 $AXQ (500 Billion)
//
// Allocation:
//   VPX Validator Subsidy  25%  125B
//   R&D & Protocol Treasury 30% 150B
//   RWA Backing Reserve    15%   75B
//   Core Team (4-yr vest)  12%   60B
//   Strategic Partners     13%   65B
//   TGE / Public Liquidity  5%   25B
//
// Changelog v0.2.0:
//   - Added ERC20Votes + EIP-712 (ERC20Permit) so governance can use
//     getPastVotes() at a fixed block snapshot instead of live balanceOf().
//     This closes the Flash Loan attack vector on quadratic voting.
//
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title AXQToken - AXIOLEDGER Native Token (v0.2.0)
/// @notice 500B fixed supply, allocated at genesis via mint-and-lock.
///         Implements ERC20Votes so AXQGovernance can snapshot voting power
///         at proposal creation, preventing Flash Loan manipulation.
contract AXQToken is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, Ownable2Step {

    uint256 public constant TOTAL_SUPPLY = 500_000_000_000e18;

    // Allocation addresses (set at construction, can be updated by DAO)
    address public vpxSubsidyVault;
    address public rdTreasuryVault;
    address public rwaReserveVault;
    address public teamVestingVault;
    address public strategicVault;
    address public tgeVault;

    event VaultUpdated(string indexed vaultName, address newVault);

    error AXQ_ZeroAddress();
    error AXQ_AlreadyMinted();

    bool private _minted;

    constructor(
        address _vpxSubsidy,
        address _rdTreasury,
        address _rwaReserve,
        address _teamVesting,
        address _strategic,
        address _tge,
        address _dao
    ) ERC20("AXIOLEDGER", "AXQ") ERC20Permit("AXIOLEDGER") Ownable(_dao) {
        if (_vpxSubsidy  == address(0)) revert AXQ_ZeroAddress();
        if (_rdTreasury  == address(0)) revert AXQ_ZeroAddress();
        if (_rwaReserve  == address(0)) revert AXQ_ZeroAddress();
        if (_teamVesting == address(0)) revert AXQ_ZeroAddress();
        if (_strategic   == address(0)) revert AXQ_ZeroAddress();
        if (_tge         == address(0)) revert AXQ_ZeroAddress();

        vpxSubsidyVault  = _vpxSubsidy;
        rdTreasuryVault  = _rdTreasury;
        rwaReserveVault  = _rwaReserve;
        teamVestingVault = _teamVesting;
        strategicVault   = _strategic;
        tgeVault         = _tge;
    }

    /// @notice Mint the entire supply once at genesis. Cannot be called again.
    function genesisAllocate() external onlyOwner {
        if (_minted) revert AXQ_AlreadyMinted();
        _minted = true;

        // 25% -> VPX Validator Subsidy
        _mint(vpxSubsidyVault,  125_000_000_000e18);
        // 30% -> R&D Treasury
        _mint(rdTreasuryVault,  150_000_000_000e18);
        // 15% -> RWA Backing Reserve
        _mint(rwaReserveVault,   75_000_000_000e18);
        // 12% -> Core Team (4-year vesting contract)
        _mint(teamVestingVault,  60_000_000_000e18);
        // 13% -> Strategic Partners
        _mint(strategicVault,    65_000_000_000e18);
        // 5%  -> TGE / Public Liquidity
        _mint(tgeVault,          25_000_000_000e18);
    }

    function decimals() public pure override returns (uint8) { return 18; }

    // -- ERC20Votes overrides (required by OZ v5 multiple-inheritance) ---------

    /// @dev Hook called on every mint/burn/transfer to update vote checkpoints.
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    /// @dev EIP-712 nonces - required by both ERC20Permit and ERC20Votes.
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
