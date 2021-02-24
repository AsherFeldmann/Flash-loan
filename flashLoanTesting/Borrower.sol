pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import {  IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILendingPoolAddressesProvider } from "https://github.com/aave/aave-protocol/blob/master/contracts/configuration/LendingPoolAddressesProvider.sol";
import { ILendingPool } from "https://github.com/aave/aave-protocol/blob/master/contracts/lendingpool/LendingPool.sol";
import { FlashLoanReceiverBase } from "https://github.com/aave/aave-protocol/blob/master/contracts/flashloan/base/FlashLoanReceiverBase.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/UniswapV2Router02.sol";
import "https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2Factory.sol";

interface IKyberNetworkProxy {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes  hint) external payable returns(uint);
    function swapEtherToToken(ERC20 token, uint minRate) external payable returns (uint);
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external returns (uint);
}


interface OrFeedInterface {
  function getExchangeRate ( string calldata fromSymbol, string calldata  toSymbol, string calldata venue, uint256 amount ) external view returns ( uint256 );
  function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
  function getTokenAddress ( string calldata  symbol ) external view returns ( address );
  function getSynthBytes32 ( string calldata  symbol ) external view returns ( bytes32 );
  function getForexAddress ( string calldata symbol ) external view returns ( address );
  function arb(address  fundsReturnToAddress,  address liquidityProviderContractAddress, string[] calldata   tokens,  uint256 amount, string[] calldata  exchanges) external payable returns (bool);
}



contract Borrower is FlashLoanReceiverBase{
	address dai;
	ILendingPoolAddressesProvider provider;
	constructor(address _dai, address _provider) FlashLoanReceiverBase(_provider){
		//OrFeedInterface orfeed = OrFeedInterface(0x8316b082621cfedab95bf4a44a1d4b64a6ffc336);
		provider = ILendingPoolAddressesProvider(_provider);
		_dai = (0x6b175474e89094c44da98b954eedeac495271d0f);
		dai = _dai;
	}
	function executeOperation(
		address[] calldata _assets,
		uint256[] calldata _amounts,
		uint256[] calldata _premiums,
		address _initiator,
		bytes calldata params
		) external override returns(bool) {
		// DO WHAT I WANT WITH FUNDS
		// MAKE SURE THAT I HAVE ENOUGH TO PAY BACK(_AMOUNTS + _PREMIUMS) + PROFIT FOR ME

		//APPROVE LENDINGPOOL CONTRACT
		for (uint i = 0; i < _assets.length; i++) {
			uint amountOwing = _amounts[i].add(_premiums[i]);
			IERC20(_assets[i]).approve(address(provider), amountOwing);
	}
	return true;
 }
 	function myFlashLoanCall() public {
 		address receiver = address(this);
 		
 		OrFeedInterface orfeed = OrFeedInterface(0x8316b082621cfedab95bf4a44a1d4b64a6ffc336);
 		uint amount = orfeed.getExchangeRate("ETH", "DAI", "BUY-UNISWAP-EXCHANGE", daiDecimals);
 		
 		address asset = address(dai);

 		uint256 mode = 0;

 		uint16 referralCode = 0;

 		provider.flashloan(receiver, asset, amount, mode, params, referralCode);

 	}

 	function detectArbitrage() public view returns(bool){
 		ArbitrageDetected = false;
 		OrFeedInterface orfeed = OrFeedInterface(0x8316b082621cfedab95bf4a44a1d4b64a6ffc336);
 		daiDecimals = getTokenDecimalCount(dai);
 		uniswapBuyRate = orfeed.getExchangeRate("ETH", "DAI", "BUY-UNISWAP-EXCHANGE", daiDecimals);
 		kyberSellRate = orfeed.getExchangeRate("ETH", "DAI", "SELL-KYBER-EXCHANGE", daiDecimals);
 		if ((uniswapBuyRate) * 1.02 <= kyberSellRate) {
 			return true;
 		}
 		return false;
 	}

 	function executeArbitrage() public {
  		OrFeedInterface orfeed = OrFeedInterface(0x8316b082621cfedab95bf4a44a1d4b64a6ffc336);
  		orfeed.arb(this, this, )
 	}

}