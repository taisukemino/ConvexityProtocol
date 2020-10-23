pragma solidity 0.5.10;

import "./interfaces/CompoundOracleInterface.sol";
import "./interfaces/CTokenInterface.sol";
import "./packages/ERC20Detailed.sol";
import "./packages/ERC20.sol";
import "./packages/Ownable.sol";
import "./packages/SafeMath.sol";


contract Oracle is Ownable {
    using SafeMath for uint256;

    // used ctoken addresses
    address internal cEth;

    mapping(address => bool) public isCtoken;
    mapping(address => address) public assetToCtokens;

    // The Oracle used for the contract
    CompoundOracleInterface public priceOracle;

    constructor(address _oracleAddress) public {
        priceOracle = CompoundOracleInterface(_oracleAddress);
        // Mainnet
        cEth = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
        address cBat = 0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E;
        address cDai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
        address cRep = 0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1;
        address cUsdc = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
        address cWbtc = 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4;
        address cZrx = 0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407;

        address bat = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
        address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address rep = 0x1985365e9f78359a9B6AD760e32412f4a445E862;
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        address zrx = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

        isCtoken[cEth] = true;
        isCtoken[cBat] = true;
        isCtoken[cDai] = true;
        isCtoken[cRep] = true;
        isCtoken[cUsdc] = true;
        isCtoken[cWbtc] = true;
        isCtoken[cZrx] = true;

        assetToCtokens[bat] = cBat;
        assetToCtokens[dai] = cDai;
        assetToCtokens[rep] = cRep;
        assetToCtokens[usdc] = cUsdc;
        assetToCtokens[wbtc] = cWbtc;
        assetToCtokens[zrx] = cZrx;
    }

    event CtokenUpdated(address indexed ctoken, bool isCtoken);
    event AssetToCtokenUpdated(address indexed asset, address ctoken);

    // /**
    //  * @dev get BTC price in USD
    //  * @return Price in USD with 6 decimals.
    //  */
    // function getETHPrice() external view returns (uint256) {
    //     return priceOracle.price("ETH");
    // }

    /**
     * @dev get an asset's price in wei
     * For ETH: return 1e18 because 1 eth = 1e18 wei
     * For other assets: ex: USDC: return 2349016936412111
     *  => 1 USDC = 2349016936412111 wei
     *  => 1 ETH = 1e18 / 2349016936412111 USDC = 425.71 USDC
     * @param asset The address of the token.
     * @return The price in wei.
     */

    function getPrice(address asset) external view returns (uint256) {
        if (asset == address(0)) {
            return (10**18);
        } else {
            uint256 exchangeRate = 1e18;
            uint256 cTokenDecimals = 8;
            address underlying = asset;

            if (isCtoken[asset]) {
                CTokenInterface cToken = CTokenInterface(asset);
                // 1e18 * TOKEN/CTOKEN = exchangeRate * 10 ** (cTokenExp - underlyingExp)
                exchangeRate = cToken.exchangeRateStored().mul(
                    10**(cTokenDecimals)
                );

                if (asset == cEth) {
                    return exchangeRate.div(1e18);
                } else {
                    underlying = cToken.underlying();
                    uint256 underlyingExp = ERC20Detailed(underlying)
                        .decimals();
                    exchangeRate = exchangeRate.div(10**underlyingExp);
                }
            }

            if (assetToCtokens[underlying] != address(0)) {
                // get underlying asset price in USD with 18 decimals
                uint256 underlyingPrice = priceOracle.getUnderlyingPrice(
                    assetToCtokens[underlying]
                );
                // price has 6 degrees of precision
                uint256 ethPrice = priceOracle.price("ETH").mul(1e12);
                // price of underlying token
                uint256 price = underlyingPrice
                    .mul(exchangeRate)
                    .div(ethPrice)
                    .div(1e18);
                return price;
            }
            return 0;
        }
    }

    /**
     * Asset Getters
     */
    function iscEth(address asset) external view returns (bool) {
        return asset == cEth;
    }

    // /**
    //  * Asset Setters
    //  */
    function setPriceOracle(address _oracle) external onlyOwner {
        priceOracle = CompoundOracleInterface(_oracle);
    }

    function setCeth(address _cEth) external onlyOwner {
        cEth = _cEth;
    }

    // }

    function setIsCtoken(address _ctoken, bool _isCtoken) external onlyOwner {
        isCtoken[_ctoken] = _isCtoken;

        emit CtokenUpdated(_ctoken, _isCtoken);
    }

    function setAssetToCtoken(address _asset, address _ctoken)
        external
        onlyOwner
    {
        assetToCtokens[_asset] = _ctoken;

        emit AssetToCtokenUpdated(_asset, _ctoken);
    }
}
