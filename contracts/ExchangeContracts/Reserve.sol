pragma solidity ^0.5.0;

contract Reserve{
    address public owner;
    uint[2] public funds;
    
    bool public isRunning;
    uint buyRate;
    uint sellRate;
    address public supportedToken;
    
    constructor(address _owner, address _supportedToken) public payable{
        owner = _owner;
        supportedToken = _supportedToken;
        isRunning =true;
    }
    
    //buyRate is how many tokens you can buy using 1 ETH, and sellRate is how many tokens you need to sell to get 1 ETH.
    
    function setExchangeRate(uint _buyRate, uint _sellRate) public onlyOwner() isContractRunning(){
        buyRate = _buyRate;
        sellRate = _sellRate;
    }
    
    function getExchangeRate(bool _isBuy, uint _srcAmount) public isContractRunning() returns(uint){
        updateFunds();
        uint result;
        if(_isBuy){
            result = buyRate * _srcAmount;
            if(funds[1] < result){
                return 0;
            }
            return (result);
        }
        else{
            result = _srcAmount/sellRate;
            if(funds[0] < result){
                return 0;
            }
            else{
                return (result);
            }
        }
    }
    
    function transferFrom(address _from, address _to, uint _srcAmount) public{
        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _srcAmount);
        (bool success, bytes memory result) = supportedToken.call(payload);
        //bool success = supportedToken.call(bytes4(keccak256("transferFrom(address, address, uint)")), _from, _to, _srcAmount);
        require(success);
    }
    
    function approve(address _spender, uint _value) private{
        address payable addr = address(uint160(_spender));
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", addr, _value);
        (bool success, bytes memory result) = address(supportedToken).delegatecall(payload);
        require(success);
    }
    
    function transfer(address _to, uint _srcAmount) private{
        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", _to, _srcAmount);
        (bool success, bytes memory result) = supportedToken.call(payload);
        require(success);
    }
    
    function balanceOf(address _owner) private returns(uint){
        bytes memory payload = abi.encodeWithSignature("balanceOf(address)", _owner);
        (bool success, bytes memory result) = supportedToken.call(payload);
        require(success);
        uint number = sliceUint(result, 0);
        return number;
    }
    
    function sliceUint(bytes memory bs, uint start)private pure returns (uint)
    {
        require(bs.length >= start + 32, "slicing out of range");
        uint x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }
    
    function updateFunds()public{
        funds[0] = address(this).balance/(10**8);
        funds[1] = balanceOf(address(this));
    }
    
    function exchange(address payable _userAddr, bool _isBuy, uint _srcAmount) public payable isContractRunning() returns(bool){
        uint valueAfterCal;
        if(_isBuy && msg.value == _srcAmount*(10**8)){
            valueAfterCal = getExchangeRate(true, _srcAmount);
            transfer(_userAddr, valueAfterCal);
            funds[0]+=_srcAmount;
            funds[1]-=valueAfterCal;
            return true;
        }
        else if(!_isBuy){
            valueAfterCal = getExchangeRate(false, _srcAmount);
            _userAddr.transfer(valueAfterCal*(10**8));
            //approve from user
            //approve(address(this), _srcAmount);
            transferFrom(_userAddr, address(this), _srcAmount);
            funds[0]-=valueAfterCal;
            funds[1]+=_srcAmount;
            return true;
        }
        revert();
    }
    
    function withdrawFund(address _token, uint _amount, address payable _destAddress) public onlyOwner() isContractRunning returns(bool){
        if(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE == _token){
            _destAddress.transfer(_amount*(10*8));
            return true;
        }
        else if(supportedToken == _token){
            transfer(_destAddress, _amount);
            return true;
        }
        revert();
    }
    function onDestroy() public{
        isRunning = false;
    }
    
    //modifier of isRunning and user type
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier isContractRunning() {
        require(isRunning == true);
        _;
    }
}