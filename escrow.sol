// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.19;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
contract Escrow {
    
    address public dev ;
    address public USDT ;
    address public client ;
    uint256 public endTime ;
    uint256 public amount ;
    uint256 public startTime;
    uint256 public duration ;
    uint256 public totalReleasedAmount;

    event depositMade(string eventName, uint256 _amount,  uint256 _timestamp, uint256 _endTime);
    event releaseMade(string eventName, uint256 _amount, uint256 _timestamp, uint256 _endTime);
    event addAmountMade(string eventName, uint256 _amount, uint256 _timestamp, uint256 _endTime);
    event addTimeMade(string eventName, uint256 _period, uint256 _timestamp, uint256 _endTime);
    event refundMade(string eventName, uint256 _amount, uint256 _timestamp, uint256 _endTime);

    bool private isExecuted = false;

    modifier onlyClient() {
        require(msg.sender == client, "Only client can call this function.") ;
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp > endTime, "Contract is still active.") ;
        _;
    }
    
    modifier onlyOnce() {
        require(!isExecuted, "Deposit has already been made.");
        isExecuted = true;
        _;
    }
    modifier onlyAfterDeposit() {
        require(isExecuted, "Deposit has not made yet.");
        _;
    }
    modifier onlyAfterExpiry() {
        require(block.timestamp > endTime, "Contract is not expired yet.");
        _;
    }
    modifier nonZeroBalance() {
        require(IERC20(USDT).balanceOf(address(this))> 0, "Contract balance is zero.");
        _;
    }
    constructor(address _dev, address _USDT) {
        dev = _dev ;
        client = msg.sender ;
        USDT = _USDT ;
    }

    function deposit(uint256 _amount, uint256 _period) public onlyClient onlyOnce {
        require(_amount > 0, "Deposit amount must be greater than 0");
        require(_period > 0, "Duration must bjje greater than 0");
        IERC20(USDT).transferFrom(msg.sender, address(this), _amount);
        amount += _amount;
        startTime = block.timestamp;
        endTime = block.timestamp + _period;        
        duration = _period ;

        emit depositMade("Initialize Escrow", _amount, block.timestamp, endTime);
    }

    function release(uint256 _amount) public onlyClient onlyAfterDeposit nonZeroBalance {
        require(_amount > 0, "Release amount must be greater than 0");
        require(_amount <= amount, "Invalid amount");
        amount -= _amount ;
        IERC20(USDT).approve(address(this), _amount);
        IERC20(USDT).transferFrom(address(this), dev, _amount);
        totalReleasedAmount += _amount; 

        emit releaseMade("Release Fund", _amount, block.timestamp, endTime);
    }

    function refund() public onlyClient onlyAfterEnd onlyAfterDeposit nonZeroBalance {
        uint256 _amount = amount ;
        amount = 0 ;
        IERC20(USDT).approve(address(this), _amount);
        IERC20(USDT).transferFrom(address(this), client, _amount);
        emit refundMade("Withdraw Funds", _amount, block.timestamp, endTime);
    }

    function addTime(uint256 _period) public onlyClient onlyAfterDeposit {
        if (block.timestamp > endTime) {
            endTime = block.timestamp + _period;
            duration += _period;
        }
        else{
            endTime += _period;
            duration += _period;
        }

        emit addTimeMade("Increase Expiry", _period, block.timestamp, endTime);
    }

    function addAmount(uint256 _amount) public onlyClient onlyAfterDeposit {
        require(_amount > 0, "Deposit amount must be greater than 0");
        IERC20(USDT).transferFrom(msg.sender, address(this), _amount);
        amount += _amount;

        emit addAmountMade("Add Funds", _amount, block.timestamp, endTime);
    }
    function getContractAddress() external view returns(address) {
        return address(this);
    }
    function getChainID() public view returns (uint256) {
        return block.chainid;
    }
    function getTokenBalance() public view returns(uint256) {
        return IERC20(USDT).balanceOf(address(this));
    }
    function isDepositExecuted() public view returns (bool) {
        return isExecuted;
    }
}
