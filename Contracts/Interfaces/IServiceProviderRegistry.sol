// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IServiceProviderRegistry {
    function isAuthorised(address providerAddress) external view returns (bool);
}
