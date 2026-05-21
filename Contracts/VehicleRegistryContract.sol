// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import  "./Interfaces/IMaintenanceRecordContract.sol";

contract VehicleRegistryContract {
    address public admin;
    address public maintenanceContractAddress;
    uint256 public vehicleCount;

    struct Vehicle {
        string vin;
        string make;
        string model;
        uint256 year;
        address owner;
        bool registered;
    }

    mapping(uint256 => Vehicle) public vehicles;
    mapping(string => bool) public vinExists;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyVehicleOwner(uint256 vehicleId) {
        require(vehicles[vehicleId].registered, "Vehicle does not exist");
        require(msg.sender == vehicles[vehicleId].owner, "Only current owner can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setMaintenanceContract(address _maintenanceContractAddress) public onlyAdmin {
        require(_maintenanceContractAddress != address(0), "Invalid maintenance contract address");
        maintenanceContractAddress = _maintenanceContractAddress;
    }

    function registerVehicle(
        string memory vin,
        string memory make,
        string memory model,
        uint256 year,
        address ownerAddress
    ) public onlyAdmin returns (uint256) {
        require(ownerAddress != address(0), "Invalid owner address");
        require(!vinExists[vin], "VIN already registered");

        vehicleCount++;

        vehicles[vehicleCount] = Vehicle({
            vin: vin,
            make: make,
            model: model,
            year: year,
            owner: ownerAddress,
            registered: true
        });

        vinExists[vin] = true;

        return vehicleCount;
    }

    function updateOwner(uint256 vehicleId, address newOwnerAddress)
        public
        onlyVehicleOwner(vehicleId)
    {
        require(newOwnerAddress != address(0), "Invalid new owner address");

        address oldOwner = vehicles[vehicleId].owner;
        vehicles[vehicleId].owner = newOwnerAddress;

        if (maintenanceContractAddress != address(0)) {
            IMaintenanceRecordContract(maintenanceContractAddress)
                .onOwnershipTransfer(vehicleId, oldOwner, newOwnerAddress);
        }
    }

    function getVehicleDetails(uint256 vehicleId)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256,
            address
        )
    {
        require(vehicles[vehicleId].registered, "Vehicle does not exist");

        Vehicle memory vehicle = vehicles[vehicleId];

        return (
            vehicle.vin,
            vehicle.make,
            vehicle.model,
            vehicle.year,
            vehicle.owner
        );
    }

    function isRegistered(uint256 vehicleId) public view returns (bool) {
        return vehicles[vehicleId].registered;
    }

    function getOwner(uint256 vehicleId) public view returns (address) {
        require(vehicles[vehicleId].registered, "Vehicle does not exist");
        return vehicles[vehicleId].owner;
    }
}