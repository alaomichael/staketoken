// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;


import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "./DappToken.sol";
import "./DaiToken.sol";

contract TokenFarm {	
	 using SafeMath for uint256;

	string public name = "Dapp Token Farm";
	address public owner;
	DappToken public dappToken;
	DaiToken public daiToken;	

	address[] public stakers;
	mapping(address => uint) public stakingBalance;
	mapping(address => bool) public hasStaked;
	mapping(address => bool) public isStaking;


    /**
     * @notice We usually require to know who are all the stakers.
     */
    // address[] internal stakers;

    /**
     * @notice The stakes for each staker.
     */
    mapping(address => uint256) internal stakes;


	   /**
     * @notice The accumulated rewards for each staker.
     */
    mapping(address => uint256) internal rewards;

	constructor(DappToken _dappToken, DaiToken _daiToken) public {
		dappToken = _dappToken;
		daiToken = _daiToken;
		owner = msg.sender;
	}

	/* Stakes Tokens (Deposit): An investor will deposit the DAI into the smart contracts
	to starting earning rewards.
		
	Core Thing: Transfer the DAI tokens from the investor's wallet to this smart contract. */
	function stakeTokens(uint _amount) public {				
		// transfer Mock DAI tokens to this contract for staking
		daiToken.transferFrom(msg.sender, address(this), _amount);

		// update staking balance
		stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;		

		// add user to stakers array *only* if they haven't staked already
		if(!hasStaked[msg.sender]) {
			stakers.push(msg.sender);
		}

		// update stakng status
		isStaking[msg.sender] = true;
		hasStaked[msg.sender] = true;
	}

	// Unstaking Tokens (Withdraw): Withdraw money from DApp.
	function unstakeTokens() public {
		// fetch staking balance
		uint balance = stakingBalance[msg.sender];

		// require amount greter than 0
		require(balance > 0, "staking balance cannot be 0");

		// transfer Mock Dai tokens to this contract for staking
		daiToken.transfer(msg.sender, balance);

		// reset staking balance
		stakingBalance[msg.sender] = 0;

		// update staking status
		isStaking[msg.sender] = false;
	}
	
	/* Issuing Tokens: Earning interest which is issuing tokens for people who stake them.

	Core Thing: Distribute DApp tokens as interest and also allow the investor to unstake their tokens
	from the app so give them interest using the app. */
	function issueTokens() public {
		// only owner can call this function
		require(msg.sender == owner, "caller must be the owner");

		// issue tokens to all stakers
		for (uint i=0; i<stakers.length; i++) {
			address recipient = stakers[i];
			uint balance = stakingBalance[recipient];
			uint reward = (1/100)* balance;
			if(balance > 0) {
				dappToken.transfer(recipient, reward);
			}			
		}
	}

	function requestReward() public {
		// only stake holders owner can call this function
		uint i = stakers.indexOf(msg.sender);
		require(i !== -1 , "caller must be a stake holder");

			address recipient = stakers[i];
			uint balance = stakingBalance[recipient];
			uint reward = (1/100)* balance;
			if(balance > 0) {
				dappToken.transfer(recipient, reward);
			}			
		
	}

	
    // ---------- STAKES ----------

    /**
     * @notice A method for a staker to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public
    {
        _burn(msg.sender, _stake);
        if(stakes[msg.sender] == 0) addStaker(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }

    /**
     * @notice A method for a staker to remove a stake.
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake)
        public
    {
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if(stakes[msg.sender] == 0) removeStaker(msg.sender);
        _mint(msg.sender, _stake);
    }

    /**
     * @notice A method to retrieve the stake for a staker.
     * @param _staker The staker to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _staker)
        public
        view
        returns(uint256)
    {
        return stakes[_staker];
    }

    /**
     * @notice A method to the aggregated stakes from all stakers.
     * @return uint256 The aggregated stakes from all stakers.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakers.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakers[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a staker.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a staker, 
     * and if so its position in the stakers array.
     */
    function isStaker(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakers.length; s += 1){
            if (_address == stakers[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a staker.
     * @param _staker The staker to add.
     */
    function addStaker(address _staker)
        public
    {
        (bool _isStaker, ) = isStaker(_staker);
        if(!_isStaker) stakers.push(_staker);
    }

    /**
     * @notice A method to remove a staker.
     * @param _staker The staker to remove.
     */
    function removeStaker(address _staker)
        public
    {
        (bool _isStaker, uint256 s) = isStaker(_staker);
        if(_isStaker){
            stakers[s] = stakers[stakers.length - 1];
            stakers.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a staker to check his rewards.
     * @param _staker The staker to check rewards for.
     */
    function rewardOf(address _staker) 
        public
        view
        returns(uint256)
    {
        return rewards[_staker];
    }

    /**
     * @notice A method to the aggregated rewards from all stakers.
     * @return uint256 The aggregated rewards from all stakers.
     */
    function totalRewards()
        public
        view
        returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakers.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakers[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each staker.
     * @param _staker The staker to calculate rewards for.
     */
    function calculateReward(address _staker)
        public
        view
        returns(uint256)
    {
        return stakes[_staker] / 100;
    }

    /**
     * @notice A method to distribute rewards to all stakers.
     */
    function distributeRewards() 
        public
        onlyOwner
    {
        for (uint256 s = 0; s < stakers.length; s += 1){
            address staker = stakers[s];
            uint256 reward = calculateReward(staker);
            rewards[staker] = rewards[staker].add(reward);
        }
    }

    /**
     * @notice A method to allow a staker to withdraw his rewards.
     */
    function withdrawReward() 
        public
    {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _mint(msg.sender, reward);
    }

}