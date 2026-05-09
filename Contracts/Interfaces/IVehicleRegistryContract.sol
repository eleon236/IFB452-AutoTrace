// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVehicleRegistryContract {
    function isRegistered(uint256 vehicleId) external view returns (bool);
    function getOwner(uint256 vehicleId) external view returns (address);
}