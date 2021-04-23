// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

/*

  This vesting contract allows an `admin` to `grant` multiple `awards`
  to `users` at given `start` times, from which there is straight-line
  vesting over a global `period` with an optional `cliff`. Users can
  `claim` their vested tokens at any time and the admin can `revoke`
  un-vested tokens.

*/

interface ERC20 {
    function transfer(address,uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
}

contract SeederVesting {
    address public admin;
    ERC20   public coin;
    uint256 public period;  // timestamp difference
    uint256 public cliff;   // timestamp difference

    // awards[user][start] = Award
    mapping (address => mapping (uint256 => Award)) public awards;

    struct Award {
        uint256 amount;     // erc20 quantity
        uint256 claimed;    // erc20 quantity
    }

    constructor(address admin_, address coin_, uint256 period_, uint256 cliff_) {
        require(admin_  != address(0));
        require(coin_   != address(0));
        require(period_ != 0);

        admin  = admin_;
        coin   = ERC20(coin_);
        period = period_;
        cliff  = cliff_;
    }

    function setAdmin(address admin_) external {
        require(msg.sender == admin);
        admin = admin_;
    }
    function setPeriod(uint256 period_) external {
        require(msg.sender == admin);
        require(period_ < period);
        period = period_;
    }
    function setCliff(uint256 cliff_) external {
        require(msg.sender == admin);
        require(cliff_ < cliff);
        cliff = cliff_;
    }

    function vested(address user, uint256 start) public view returns (uint256) {
        Award storage award = awards[user][start];

        // fully vested
        if (block.timestamp >= start + period) {
            return award.amount;
        // vesting didn't start
        } else if (block.timestamp < start + cliff) {
            return 0;
        // straight line vesting
        } else {
            return award.amount * (block.timestamp - start) / period;
        }
        // TODO: what if period == 0?
    }

    function revoke(address user, uint256 start) public {
        require(msg.sender == admin);
        require(coin.transfer(msg.sender, awards[user][start].amount - vested(user, start)));
        awards[user][start].amount = vested(user, start);
    }

    function grant(address user, uint256 start, uint256 amount) external {
        require(msg.sender == admin);
        awards[user][start].amount += amount;
        require(coin.transferFrom(msg.sender, address(this), amount));
    }
    function grant(address[] calldata users, uint256 start, uint256[] calldata amounts) external {
        require(msg.sender == admin);
        uint256 total;
        for (uint i=0; i<users.length; i++) {
            awards[users[i]][start].amount += amounts[i];
            total += amounts[i];
        }
        require(coin.transferFrom(msg.sender, address(this), uint256(total)));
    }

    function _claim(address user, uint256 start, address destination) internal {
        uint256 claimable = vested(user, start) - awards[user][start].claimed;
        awards[user][start].claimed += claimable;
        require(coin.transfer(destination, claimable));
    }
    function claim(uint256 start, address destination) public {
        _claim(msg.sender, start, destination);
    }

    // EIP-712 implementation, allowing claims to an arbitrary destination
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(address user,address start,address destination)");
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    string public constant NAME =
        "Radicle Seeder Vesting v1";
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId; assembly { chainId := chainid() }
        return keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), chainId, address(this))
        );
    }
    function claim(address user, uint256 start, address destination, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, user, start, destination));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash));
        require(user == ecrecover(digest, v, r, s));
        require(user != address(0));
        _claim(user, start, destination);
    }
}
