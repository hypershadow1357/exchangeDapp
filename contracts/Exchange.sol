pragma solidity ^0.5.0;

import "./Reserve.sol";

contract Exchange{
    address public owner;
    address[] public reserves;
    mapping(address => address) public tokenWithReserve;
    uint public destAmount;
    
    constructor() public{
        owner = msg.sender;
    }
    
    function addReserve(address _reserve) public returns(bool){
        Reserve temp = Reserve(_reserve);
        address supportedToken = temp.supportedToken();
        
        reserves.push(_reserve);
        tokenWithReserve[supportedToken]=_reserve;
        return true;
    }
    
    function removeReserve(address _reserve) public{
        Reserve temp = Reserve(_reserve);
        address supportedToken = temp.supportedToken();
        delete tokenWithReserve[supportedToken];
        delete reserves[0];
    }
    
    function getExchangeRate(address _srcToken, address _destToken, uint _srcAmount) public returns(uint){
        
        
        if(_srcToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            Reserve dest = Reserve(tokenWithReserve[_destToken]);
            uint destRate = dest.getExchangeRate(true, _srcAmount);
            destAmount = destRate;
            return(destRate);
        }
        else if(_srcToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE && _destToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            Reserve src = Reserve(tokenWithReserve[_srcToken]);
            Reserve dest = Reserve(tokenWithReserve[_destToken]);
            if(!checkIfReserveAdded(tokenWithReserve[_srcToken]) || !checkIfReserveAdded(tokenWithReserve[_destToken])){
                revert();
            }
            uint srcRate = src.getExchangeRate(false, _srcAmount);
            uint destRate = dest.getExchangeRate(true, srcRate);
            destAmount = destRate;
            return(destRate);
        }
        else if(_destToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            Reserve src = Reserve(tokenWithReserve[_srcToken]);
            uint srcRate = src.getExchangeRate(false, _srcAmount);
            destAmount = srcRate;
            return(srcRate);
        }
        
    }
    
    function exchange(address _srcToken, address _destToken, uint _srcAmount)public payable returns(bool){
        
        
        
        require(getExchangeRate(_srcToken, _destToken, _srcAmount) >0);
        
        if(_srcToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE && msg.value == _srcAmount *(10**8)){
            Reserve dest = Reserve(tokenWithReserve[_destToken]);
            dest.exchange.value(_srcAmount*(10**8))(msg.sender, true, _srcAmount);
            return true;
        }
        else if(_srcToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE && _destToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            uint ETHAmount = getExchangeRate(_srcToken,0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, _srcAmount);
            if(msg.value != ETHAmount *(10**8)){
                revert();
            }
            Reserve src = Reserve(tokenWithReserve[_srcToken]);
            Reserve dest = Reserve(tokenWithReserve[_destToken]);
            if(!checkIfReserveAdded(tokenWithReserve[_srcToken]) || !checkIfReserveAdded(tokenWithReserve[_destToken])){
                revert();
            }
            // address payable addr =address(uint160(address(this)));
            // transferFrom(_srcToken, msg.sender, address(this), _srcAmount);
            // src.exchange(addr, false, _srcAmount);
            // dest.exchange.value(ETHAmount*(10**8))(addr, true, ETHAmount);
            // transferFrom(_destToken, address(this), msg.sender, _srcAmount);
            
            
            // exchange token made by this contract
            src.exchange(msg.sender, false, _srcAmount);
            dest.exchange.value(msg.value)(msg.sender, true, ETHAmount);
            return true;
        }
        else if(_destToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            Reserve src = Reserve(tokenWithReserve[_srcToken]);
            src.exchange(msg.sender, false, _srcAmount);
            return true;
        }
        revert();
    }
    
    function transferFrom(address _token, address _from, address _to, uint _srcAmount) private{
        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _srcAmount);
        (bool success, bytes memory result) = _token.call(payload);
        //bool success = supportedToken.call(bytes4(keccak256("transferFrom(address, address, uint)")), _from, _to, _srcAmount);
        require(success);
    }
    
    function checkIfReserveAdded(address _reserve) private view returns(bool){
        for (uint i = 0; i<reserves.length; i++){
            if(reserves[i]==_reserve){
                return true;
            }
        }
        return false;
    }
}