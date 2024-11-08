// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./interfaces/IUniswapV3PoolDeployer.sol";
import "./StratoSwapPool.sol";

contract StratoSwapFactory is IUniswapV3PoolDeployer {
    error PoolAlreadyExists();
    error ZeroAddressNotAllowed();
    error TokensMustBeDifferent();
    error UnsupportedFee();

    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        address pool
    );

    PoolParameters public parameters;

    mapping(uint24 => uint24) public fees;
    mapping(address => mapping(address => mapping(uint24 => address)))
        public pools;

    constructor() {
        fees[100] = 1;
        fees[500] = 10;
        fees[3000] = 60;
        fees[10000] = 200;
    }


    function getPoolAddress(
        address tokenX,
        address tokenY,
        uint24 fee
    ) public view returns (address) {
        (tokenX, tokenY) = tokenX < tokenY
            ? (tokenX, tokenY)
            : (tokenY, tokenX);

        return pools[tokenX][tokenY][fee];
    }

    function createPool(
        address tokenX,
        address tokenY,
        uint24 fee
    ) public returns (address pool) {
        if (tokenX == tokenY) revert TokensMustBeDifferent();
        if (fees[fee] == 0) revert UnsupportedFee();

        (tokenX, tokenY) = tokenX < tokenY
            ? (tokenX, tokenY)
            : (tokenY, tokenX);

        if (tokenX == address(0)) revert ZeroAddressNotAllowed();
        if (pools[tokenX][tokenY][fee] != address(0))
            revert PoolAlreadyExists();

        parameters = PoolParameters({
            factory: address(this),
            token0: tokenX,
            token1: tokenY,
            tickSpacing: fees[fee],
            fee: fee
        });

        pool = address(
            new StratoSwapPool{
                salt: keccak256(abi.encodePacked(tokenX, tokenY, fee))
            }()
        );

        delete parameters;

        pools[tokenX][tokenY][fee] = pool;
        pools[tokenY][tokenX][fee] = pool;

        emit PoolCreated(tokenX, tokenY, fee, pool);
    }
}
