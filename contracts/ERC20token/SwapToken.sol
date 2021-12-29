// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AntiBotBlacklist is Ownable {
    event AddSuspect(address suspect);
    event RemoveSuspect(address suspect);
    uint256 public blacklistLength;
    mapping(address=>uint256) blacklist;
    
    
    function blacklistCheck(address suspect) public view returns(bool){
        return blacklist[suspect] < block.timestamp;
    }
    
    function blacklistCheckExpirationTime(address suspect) external view returns(uint256){
        return blacklist[suspect];
    }
    
    function addSuspect(address _suspect,uint256 _expirationTime) external onlyOwner {
        _addSuspectToBlackList(_suspect,_expirationTime);
    }
    
    function removeSuspect(address suspect) external onlyOwner{
        _removeSuspectToBlackList(suspect);
    }
    
    function addSuspectBatch(address[] memory _addresses,uint256 _expirationTime) external onlyOwner{
        require(_addresses.length>0,"addresses is empty");
        for(uint i=0;i<_addresses.length;i++){
            _addSuspectToBlackList(_addresses[i],_expirationTime);
            emit AddSuspect(_addresses[i]);
        }
    }
    
    function removeSuspectBatch(address[] memory _addresses) external onlyOwner{
        require(_addresses.length>0,"addresses is empty");
        for(uint i=0;i<_addresses.length;i++){
            _removeSuspectToBlackList(_addresses[i]);
            emit RemoveSuspect(_addresses[i]);
        }
    }
    
    function _addSuspectToBlackList(address _suspect,uint256 _expirationTime) internal{
        require(_suspect != owner(),"the suspect cannot be owner");
        require(blacklist[_suspect]==0,"the suspect already exist");
        blacklist[_suspect] = _expirationTime;
        blacklistLength = blacklistLength + 1;
        emit AddSuspect(_suspect);
    }
    
    function _removeSuspectToBlackList(address _suspect) internal{
        require(blacklist[_suspect]>0,"suspect is not in blacklist");
        delete blacklist[_suspect];
        blacklistLength = blacklistLength - 1;
        emit RemoveSuspect(_suspect);
    }
}

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

contract TokenSwap is Context, Ownable, AntiBotBlacklist{
    // address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn) external {

        require(
            blacklistCheck(msg.sender), "Swap token: Account is in the blacklist"
        );
        uint rate = 2;
        IERC20(_tokenIn).approve(address(this), _amountIn*rate);
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        
        IERC20(_tokenOut).transfer(msg.sender, _amountIn*rate);



        // address[] memory path;
        // path[0]=_tokenIn;
        // path[1]=_tokenOut;
        // IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
    
    // function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

    //     address[] memory path;
    //     path[0]=_tokenIn;
    //     path[1]=_tokenOut;
        
    //     uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
    //     return amountOutMins[path.length -1];
    
    // }

}