// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

error onlyOwner();
error Casnic__DepositeAmmountInvalid();
error Casnic__BetAmmountInvalid();
error Casnic__YouAreNotWInner();
error Casnic__DelayTimeNotPassed();
error Casnic__WithdrawFailed();
error Casnic__WithdrawRequestFailed();

contract Casinc {
    uint private s_betAmmountStorage;
    uint private constant DELAY = 5 minutes;
    address private immutable i_owner;
    mapping(address => uint) private s_userAmmount;
    mapping(address => bool) private s_userExists;
    mapping(address => uint) private s_winnerData;
    mapping(address => bool) private s_winnerExists;
    mapping(address => uint) private s_winnerTimeStamp;
    mapping(address => uint) private s_InitiateWithdraw_Request;
    mapping(address => bool) private s_Withdraw_Request_check;

    address[] private s_users;
    enum multiplier {
        x2,
        x3,
        x4,
        x5
    }
    enum color {
        red,
        black
    }
    enum withdrawRequest {
        pending,
        approve,
        rejected
    }
    struct betParameters {
        uint betAmmount;
        multiplier betMultiplier;
        color betColor;
    }

    event UserDeposite(uint indexed ammount);
    event BetPlaced(betParameters indexed betData, address indexed user);
    event WinnerAnnounced(
        address indexed winner,
        uint indexed winningAmmount,
        uint indexed timeStamp
    );
    event withdrawRequested(
        address indexed winner,
        uint indexed winningAmmount,
        withdrawRequest indexed status
    );
    event withdrawApproved(
        address indexed winner,
        uint indexed winningAmmount,
        withdrawRequest indexed status
    );
    modifier onlyAdmin() {
        if (msg.sender != i_owner) {
            revert onlyOwner();
        }
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function DepositeAmount() external payable {
        if (msg.value < 0.01 ether) {
            revert Casnic__DepositeAmmountInvalid();
        }
        s_userAmmount[msg.sender] += msg.value;
        if (s_userExists[msg.sender] == false) {
            s_users.push(msg.sender);
            s_userExists[msg.sender] = true;
        }
        emit UserDeposite(msg.value);
    }

    function placeBet(betParameters memory betData) external {
        if (betData.betAmmount > s_userAmmount[msg.sender]) {
            revert Casnic__BetAmmountInvalid();
        }
        s_userAmmount[msg.sender] -= betData.betAmmount;
        s_betAmmountStorage += betData.betAmmount;
        emit BetPlaced(betData, msg.sender);
        //further processing happen Off chain
    }

    function updateWinner(
        address _winner_address,
        uint _winning_ammount
    ) external {
        s_winnerData[_winner_address] = _winning_ammount;
        s_winnerTimeStamp[_winner_address] = block.timestamp;
        s_winnerExists[_winner_address] = true;

        emit WinnerAnnounced(
            _winner_address,
            _winning_ammount,
            block.timestamp
        );
        //further processing happens off chain
    }

    function userWithdraw() public {
        //check only winner can access
        if (!s_winnerExists[msg.sender]) {
            revert Casnic__YouAreNotWInner();
        }
        //check Delay time has passed
        if (block.timestamp < s_winnerTimeStamp[msg.sender] + DELAY) {
            revert Casnic__DelayTimeNotPassed();
        }
        uint winningAmmount = s_winnerData[msg.sender];

        s_InitiateWithdraw_Request[msg.sender] = winningAmmount;
        s_Withdraw_Request_check[msg.sender] = true;

        s_winnerData[msg.sender] = 0;
        s_winnerTimeStamp[msg.sender] = 0;
        s_winnerExists[msg.sender] = false;

        emit withdrawRequested(
            msg.sender,
            winningAmmount,
            withdrawRequest.pending
        );
    }

    function approveWithdraw(address _withdraw_request) external onlyAdmin {
        if (!s_Withdraw_Request_check[_withdraw_request]) {
            revert Casnic__WithdrawRequestFailed();
        }
        uint withdrawAmmount = s_InitiateWithdraw_Request[_withdraw_request];

        (bool success, ) = payable(_withdraw_request).call{
            value: withdrawAmmount
        }("");
        if (!success) {
            revert Casnic__WithdrawRequestFailed();
        }
        s_InitiateWithdraw_Request[_withdraw_request] = 0;
        s_Withdraw_Request_check[_withdraw_request] = false;

        emit withdrawApproved(
            _withdraw_request,
            withdrawAmmount,
            withdrawRequest.approve
        );
    }

    //getters

    function getBetStorageAmmount() public view returns (uint) {
        return s_betAmmountStorage;
    }

    function getUserAmmount(address _address) public view returns (uint) {
        return s_userAmmount[_address];
    }

    function getUserAddress(uint _index) public view returns (address) {
        return s_users[_index];
    }

    function getUserExists(address _address) public view returns (bool) {
        return s_userExists[_address];
    }

    function getWinnerData(address _address) public view returns (uint) {
        return s_winnerData[_address];
    }

    function getWinnerExists(address _address) public view returns (bool) {
        return s_winnerExists[_address];
    }

    function getWinnerTimeStamp(address _address) public view returns (uint) {
        return s_winnerTimeStamp[_address];
    }

    function getInitiateWithdrawRequest(
        address _address
    ) public view returns (uint) {
        return s_InitiateWithdraw_Request[_address];
    }

    function getWithdrawRequestCheck(
        address _address
    ) public view returns (bool) {
        return s_Withdraw_Request_check[_address];
    }
}
