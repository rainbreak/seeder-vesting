// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.0;

contract TestToken  {
    // --- Auth ---
    mapping (address => bool) public wards;
    function rely(address guy) external auth { wards[guy] = true; }
    function deny(address guy) external auth { wards[guy] = false; }
    modifier auth {
        require(wards[msg.sender], "Token/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string  public constant name     = "Token";
    string  public constant symbol   = "GEM";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    constructor() {
        wards[msg.sender] = true;
    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad)
        public returns (bool)
    {
        require(balanceOf[src] >= wad, "Token/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
            require(allowance[src][msg.sender] >= wad, "Token/insufficient-allowance");
            allowance[src][msg.sender] = allowance[src][msg.sender] - wad;
        }
        balanceOf[src] = balanceOf[src] - wad;
        balanceOf[dst] = balanceOf[dst] + wad;
        emit Transfer(src, dst, wad);
        return true;
    }
    function mint(address usr, uint wad) external auth {
        balanceOf[usr] = balanceOf[usr] + wad;
        totalSupply    = totalSupply    + wad;
        emit Transfer(address(0), usr, wad);
    }
    function burn(address usr, uint wad) external {
        require(balanceOf[usr] >= wad, "Token/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != type(uint).max) {
            require(allowance[usr][msg.sender] >= wad, "Token/insufficient-allowance");
            allowance[usr][msg.sender] = allowance[usr][msg.sender] - wad;
        }
        balanceOf[usr] = balanceOf[usr] - wad;
        totalSupply    = totalSupply    - wad;
        emit Transfer(usr, address(0), wad);
    }
    function approve(address usr, uint wad) external returns (bool) {
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
        return true;
    }
}
