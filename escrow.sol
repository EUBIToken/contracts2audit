pragma solidity ^0.8.0;

//OpenZeppelin Ownable Smart Contracts

contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract AccessController is Ownable {
    mapping(address => uint) private _managers;

    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);


    modifier onlyManager() {
        require(_managers[msg.sender] == 1, "AccessController: caller is not a manager");
        _;
    }

    function removeManager(address addr) external onlyOwner{
        require(_managers[msg.sender] == 1, "AccessController: target is not a manager");
        _managers[addr] = 0;
        emit ManagerRemoved(addr);
    }
    function renounceManagerRole() external onlyManager{
        _managers[msg.sender] = 0;
        emit ManagerRemoved(msg.sender);
    }
    function addManager(address addr) external onlyOwner{
        require(_managers[addr] == 0, "AccessController: target is already a manager");
        _managers[addr] = 1;
        emit ManagerAdded(addr);
    }
    modifier onlyOwnerOrManager() {
        require(_owner == msg.sender || _managers[msg.sender] == 1, "AccessController: caller is not the owner or a manager");
        _;
    }

}


//prss escrow contract v7
//[Jessie Lesbian] use external functions and OpenZeppelin-approved require-revert convention
contract Escrow is AccessController {
    function paySender(uint256 value) private{
        (bool stat, ) = msg.sender.call{value: value}("");
        require(stat);
    }
    //object for escrow data 
    struct EscrowData {
        uint econtract;
        address msend;
        address receiver;
        uint amount;
        uint fee;
        bool a_approved;
        bool b_approved;
        bool deposited;
        bool payed;
        bool cancelled;
        string terms;
    }
    
    //[Jessie Lesbian]I rewrote your code to use better practices
    //EscrowData[1000000000] _all_contracts;
    mapping(uint => EscrowData) private _all_contracts;
    mapping(address => uint) private current_contract;
    
    uint _contract_number   = 0;
    uint _fee_collected     = 0;
    uint _service_fee       = 10000000000000000000;
    
    //constructor
    constructor() {
        _transferOwnership(0x69946523bEc693f9d4D8169D43ADE2DF0Aa51074);
        //_managers[0] = msg.sender; - no need for this
    }
    
    //
    //contract count
    //
    
    //returns contract count
    function getAllContractsCount() external view returns (uint Amount) {
        return _contract_number;
    }
    
    //ups the count, sets the default contract to use for interactions
    function _getNewContract() private returns (uint) {
        if(current_contract[msg.sender] == 0) {
            _contract_number = _contract_number + 1;
            current_contract[msg.sender] = _contract_number;
            return _contract_number;
        } else {
            return 0;
        }
    }
    
    //
    //contract start and information
    //
    
    //sets the contract information and begins the contract
    function beginContract(address _rec, uint _amt, string calldata _trms) external returns (uint Contract) {
        if(_getNewContract() != 0) {
            current_contract[_rec]                      = current_contract[msg.sender];
            _all_contracts[_contract_number].econtract  = current_contract[msg.sender];
            _all_contracts[_contract_number].msend      = msg.sender;
            _all_contracts[_contract_number].receiver   = _rec;
            _all_contracts[_contract_number].amount     = _amt;
            _all_contracts[_contract_number].fee        = _service_fee;
            _all_contracts[_contract_number].terms      = _trms;
            _all_contracts[_contract_number].a_approved = false;
            _all_contracts[_contract_number].b_approved = false;
            _all_contracts[_contract_number].deposited  = false;
            _all_contracts[_contract_number].payed      = false;
            _all_contracts[_contract_number].cancelled  = false;
            return _contract_number;
        } else {
            return 0;
        }
    }
    
    //sets the contract information, approves contract, and begins the contract
    function beginContractandApprove(address _rec, uint _amt, string calldata _trms) external returns (uint Contract) {
        if(_getNewContract() != 0) {
            current_contract[_rec]                      = current_contract[msg.sender];
            _all_contracts[_contract_number].econtract  = current_contract[msg.sender];
            _all_contracts[_contract_number].msend      = msg.sender;
            _all_contracts[_contract_number].receiver   = _rec;
            _all_contracts[_contract_number].amount     = _amt;
            _all_contracts[_contract_number].fee        = _service_fee;
            _all_contracts[_contract_number].terms      = _trms;
            _all_contracts[_contract_number].a_approved = true;
            _all_contracts[_contract_number].b_approved = false;
            _all_contracts[_contract_number].deposited  = false;
            _all_contracts[_contract_number].payed      = false;
            _all_contracts[_contract_number].cancelled  = false;
            return _contract_number;
        } else {
            return 0;
        }
    }
    
    //returns the contract infromtion
    function getContractInfo() external view returns (uint Number, address Sender, address Receiver, uint Amount, uint Fee, bool A_Approved, bool B_Approved, bool Deposited, bool Payed, bool Cancelled, string memory Terms) {
        EscrowData memory temp = _all_contracts[current_contract[msg.sender]];
        return (temp.econtract, temp.msend, temp.receiver, temp.amount, temp.fee, temp.a_approved, temp.b_approved, temp.deposited, temp.payed, temp.cancelled, temp.terms);
    }
    
    //
    //update contract
    //
    
    //sender aproves terms
    function updateAApproved() external {
        require(msg.sender == _all_contracts[current_contract[msg.sender]].msend);
        _all_contracts[current_contract[msg.sender]].a_approved = true;
    }
    
    //receiver approves terms
    function updateBApproved() external {
        require(msg.sender == _all_contracts[current_contract[msg.sender]].receiver);
        _all_contracts[current_contract[msg.sender]].b_approved = true;
    }
    
    //cancels the current contract
    function cancelContract() external {
        require(msg.sender == _all_contracts[current_contract[msg.sender]].msend && _all_contracts[current_contract[msg.sender]].payed != true);
        _all_contracts[current_contract[msg.sender]].cancelled = true;
        current_contract[_all_contracts[current_contract[msg.sender]].receiver] = 0;
        current_contract[msg.sender] = 0;
    }
    
    //sets contract to pay out
    function payContract() external {
        require(msg.sender == _all_contracts[current_contract[msg.sender]].msend 
        && _all_contracts[current_contract[msg.sender]].a_approved == true 
        && _all_contracts[current_contract[msg.sender]].b_approved == true 
        && _all_contracts[current_contract[msg.sender]].cancelled != true);
        _all_contracts[current_contract[msg.sender]].payed = true;
    }
    
    //updates contract ammount, only if terms are not agreed upon.
    function updateContractAmount(uint _amt) external {
        require(msg.sender == _all_contracts[current_contract[msg.sender]].msend 
        && _all_contracts[current_contract[msg.sender]].b_approved != true);
            _all_contracts[current_contract[msg.sender]].amount = _amt;
    }
    
    //updates contract terms, only if terms are not agreed upon
    function updateContractTerms(string calldata _trms) external {
        require(msg.sender == _all_contracts[current_contract[msg.sender]].msend 
        && _all_contracts[current_contract[msg.sender]].b_approved != true);
        _all_contracts[current_contract[msg.sender]].terms = _trms;
    }
    
    //
    //money money money
    //
    
    //[Jessie Lesbian]
    //deposit money for contract
    function depositContractAmount() payable external {
        require(msg.value >= _all_contracts[current_contract[msg.sender]].amount + _service_fee);
        _all_contracts[current_contract[msg.sender]].deposited = true;
        _fee_collected = _fee_collected + _service_fee;
    }
    

    
    //[Jessie Lesbian] Jones, what a badly-written smart contract
    //deposit money for contract
    function collectContractAmount() external {
        //[Jessie Lesbian] Jones, your duplicate state reads use too much gas!
        //If you are using a state variable multiple times
        //Read it into a memory variable and use it from there first
        uint256 temp2 = current_contract[msg.sender];
        if(_all_contracts[temp2].receiver == msg.sender 
        && _all_contracts[temp2].deposited == true 
        && _all_contracts[temp2].a_approved == true 
        && _all_contracts[temp2].b_approved == true 
        && _all_contracts[temp2].payed == true 
        && _all_contracts[temp2].cancelled != true) {
            uint256 value = _all_contracts[temp2].amount;
            //[Jessie Lesbian] Jones, make your state changes first
            //AND THEN SEND MINTME, not the other way around
            current_contract[_all_contracts[temp2].msend] = 0;
            current_contract[msg.sender] = 0;
            paySender(value);
            //[Jessie Lesbian] This is not how you send MintME in Solidity
            //msg.sender.transfer(_all_contracts[current_contract[msg.sender]].amount);
            //This practice is not encouraged
        } else if(_all_contracts[temp2].msend == msg.sender 
        && _all_contracts[temp2].deposited == true) {
            _all_contracts[temp2].deposited = false;
            paySender(_all_contracts[temp2].amount);
        }
    }
    
    //
    //arbitration
    //
    
    //cancels contract
    function cancelArbitration(uint _number) external onlyOwnerOrManager{
        _all_contracts[_number].cancelled = true;
        current_contract[_all_contracts[_number].msend] = 0;
        current_contract[_all_contracts[_number].receiver] = 0;
    }
    
    //
    // other managment stuff
    //
    
    //change fee
    function changeFee(uint _new) external onlyOwnerOrManager{
        _service_fee = _new;
    }
    
    //returns the fee balance in the contract to the owner wallet
    function returnFeeBalance() external onlyOwner{
        uint256 temp = _fee_collected;
        require(address(this).balance >= temp);
        //[Jessie Lesbian] Use better programming practices Jones
        //msg.sender.transfer(_fee_collected);
        _fee_collected = 0;
        paySender(temp);
    }
    //emergency, never use, returns the entire dapp balance to the owner wallet
    function emergencyReturnMintBalance() external onlyOwner {
        //[Jessie Lesbian] Jones, you forgot this
        _fee_collected = 0;
        paySender(address(this).balance);
    }
    
    //amounts
    function feeBalanceAllBalance() external view returns (uint Fee, uint Balance) {
        return (_fee_collected, address(this).balance);
    }
    
}
