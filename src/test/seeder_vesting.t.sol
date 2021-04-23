// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "./lib.sol";

import "../seeder_vesting.sol";

contract Usr {
    function claim(SeederVesting vesting, uint start) public {
        vesting.claim(start, address(this));
    }
}

contract VestingTest is DSTest {
    SeederVesting vesting;
    TestToken token;

    Usr usr1;

    address[] users;
    uint256[] amounts;

    address[] users_100;
    uint256[] amounts_100;

    function setUp() public {
        token = new TestToken();
        token.mint(address(this), 100e24);
        vesting = new SeederVesting(address(this), address(token), 180 days, 30 days);

        usr1 = new Usr();

        for (uint i=0; i<10; i++) {
            users.push(address(new Usr()));
            amounts.push(i * 100e18);
        }
        for (uint i=0; i<100; i++) {
            users_100.push(address(new Usr()));
            amounts_100.push(i * 100e18);
        }
        token.approve(address(vesting), type(uint).max);
    }

    function testGrant() public {
        vesting.grant(address(usr1), block.timestamp + 30 days, 1000e18);
    }
    function testGrant10() public {
        vesting.grant(users, block.timestamp + 30 days, amounts);
    }
    function testGrant100() public {
        vesting.grant(users_100, block.timestamp + 30 days, amounts_100);
    }
}
