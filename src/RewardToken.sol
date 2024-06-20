// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title Reward Token Contract
 *
 * @dev This is an ERC20 token with some voting features.
 *
 * Also this is a non transferable token so that proper governance votes could
 * be assured. Only to/from staking transfers are allowed.
 *
 * One get this token after staking the main token i.e. blob and get this sBlob
 * as a reward.
 */
contract RewardToken is Ownable, ERC20, ERC20Permit, ERC20Votes {
    address public staking;

    string private _name = "Reward Token";
    string private constant _symbol = "sBlob";
    uint private constant _numTokens = 10_000_000_000;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor()
        Ownable(msg.sender)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {}

    /**
     * @dev Setting the staking address and minting sBlob as much as there
     * are blob.
     */
    function initialize(address _staking) external onlyOwner {
        staking = _staking;
        _mint(_staking, _numTokens * 10 ** decimals());
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        require(from == staking || to == staking, "Can't transfer sBlob");
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        super.nonces(owner);
    }
}
