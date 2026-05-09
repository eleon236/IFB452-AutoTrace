// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMaintenanceRecordContract {
    function onOwnershipTransfer(
        uint256 vehicleId,
        address oldOwner,
        address newOwner
    ) external;
}