// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract DaiToken {
    string  public name = "My DAI Token";
    string  public symbol = "mDAI";
    uint256 public totalSupply = 1000000000000000000000; // 1000 tokens
    uint8   public decimals = 18;
    uint256 public unitsOneEthCanBuy  = 10;
    address private owner;
    address public tokenOwner;         // the owner of the token

    // event for EVM logging
    event priceSet(uint256 indexed oldPrice, uint256 indexed newPrice);
    

      // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
      
        // require(msg.sender == owner, "Caller is not owner");
         require(msg.sender == tokenOwner, "Caller is not owner");
        _;
    }

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    // this function is called to modify the token buying price
// it is restricted to only the owner
/**
     * @dev Change token buy price
     * @param newTokenBuyPrice value of new price
     */
    function modifyTokenBuyPrice(uint256 newTokenBuyPrice) public isOwner {
        emit priceSet(unitsOneEthCanBuy, newTokenBuyPrice);
        unitsOneEthCanBuy = newTokenBuyPrice;
    }

    //  this function mint new token when called and add to the initial 
// total of the minted token
     function mint(address to, uint256 amount) public isOwner {
        _mint(to, amount);
    }
 // this function is called when you want to sends token  
    // to someone
    function buyToken(address receiver) external payable {
        require(msg.value > 0, "You cannot buy Zero ETH");
        uint256 amount = msg.value * unitsOneEthCanBuy /10**18;
        _mint(receiver,amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}
