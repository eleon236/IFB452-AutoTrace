// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IServiceProviderRegistry.sol";
import "./interfaces/IVehicleRegistryContract.sol";

contract MaintenanceRecordContract {
    address public admin;
    address public serviceProviderRegistryAddress;
    address public vehicleRegistryAddress;

    struct MaintenanceRecord {
        string recordType;
        string description;
        uint256 mileage;
        string date;
        string evidenceHash;
        address addedBy;
        uint256 timestamp;
    }

    mapping(uint256 => MaintenanceRecord[]) private maintenanceRecords;
    mapping(uint256 => mapping(address => bool)) public accessGranted;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyVehicleRegistry() {
        require(msg.sender == vehicleRegistryAddress, "Only VehicleRegistry can call this");
        _;
    }

    modifier onlyAuthorisedProvider() {
        require(
            IServiceProviderRegistry(serviceProviderRegistryAddress).isAuthorised(msg.sender),
            "Mechanic is not authorised"
        );
        _;
    }

    modifier vehicleMustExist(uint256 vehicleId) {
        require(
            IVehicleRegistryContract(vehicleRegistryAddress).isRegistered(vehicleId),
            "Vehicle is not registered"
        );
        _;
    }

    modifier onlyOwner(uint256 vehicleId) {
        require(
            msg.sender == IVehicleRegistryContract(vehicleRegistryAddress).getOwner(vehicleId),
            "Only vehicle owner can perform this action"
        );
        _;
    }

    modifier canViewHistory(uint256 vehicleId) {
        address owner = IVehicleRegistryContract(vehicleRegistryAddress).getOwner(vehicleId);

        require(
            msg.sender == owner ||
            accessGranted[vehicleId][msg.sender] ||
            IServiceProviderRegistry(serviceProviderRegistryAddress).isAuthorised(msg.sender),
            "You do not have access to view this history"
        );
        _;
    }

    constructor(address _serviceProviderRegistryAddress) {
        require(_serviceProviderRegistryAddress != address(0), "Invalid provider registry address");

        admin = msg.sender;
        serviceProviderRegistryAddress = _serviceProviderRegistryAddress;
    }

    function setVehicleRegistry(address _vehicleRegistryAddress) public onlyAdmin {
        require(_vehicleRegistryAddress != address(0), "Invalid vehicle registry address");
        vehicleRegistryAddress = _vehicleRegistryAddress;
    }

    function addServiceRecord(
        uint256 vehicleId,
        string memory serviceType,
        uint256 mileage,
        string memory date,
        string memory notesHash
    )
        public
        onlyAuthorisedProvider
        vehicleMustExist(vehicleId)
    {
        maintenanceRecords[vehicleId].push(
            MaintenanceRecord({
                recordType: "Service",
                description: serviceType,
                mileage: mileage,
                date: date,
                evidenceHash: notesHash,
                addedBy: msg.sender,
                timestamp: block.timestamp
            })
        );
    }

    function addRepairRecord(
        uint256 vehicleId,
        string memory repairDescription,
        string memory partsReplaced,
        uint256 mileage,
        string memory date,
        string memory invoiceHash
    )
        public
        onlyAuthorisedProvider
        vehicleMustExist(vehicleId)
    {
        string memory fullDescription = string(
            abi.encodePacked(repairDescription, " | Parts: ", partsReplaced)
        );

        maintenanceRecords[vehicleId].push(
            MaintenanceRecord({
                recordType: "Repair",
                description: fullDescription,
                mileage: mileage,
                date: date,
                evidenceHash: invoiceHash,
                addedBy: msg.sender,
                timestamp: block.timestamp
            })
        );
    }

    function grantAccess(uint256 vehicleId, address viewer)
        public
        vehicleMustExist(vehicleId)
        onlyOwner(vehicleId)
    {
        require(viewer != address(0), "Invalid viewer address");
        accessGranted[vehicleId][viewer] = true;
    }

    function revokeAccess(uint256 vehicleId, address viewer)
        public
        vehicleMustExist(vehicleId)
        onlyOwner(vehicleId)
    {
        accessGranted[vehicleId][viewer] = false;
    }

    function viewMaintenanceHistory(uint256 vehicleId)
        public
        view
        vehicleMustExist(vehicleId)
        canViewHistory(vehicleId)
        returns (MaintenanceRecord[] memory)
    {
        return maintenanceRecords[vehicleId];
    }

    function verifyRecord(uint256 vehicleId, uint256 recordIndex)
        public
        view
        vehicleMustExist(vehicleId)
        canViewHistory(vehicleId)
        returns (string memory)
    {
        require(recordIndex < maintenanceRecords[vehicleId].length, "Invalid record index");
        return maintenanceRecords[vehicleId][recordIndex].evidenceHash;
    }

    function getRecordCount(uint256 vehicleId)
        public
        view
        vehicleMustExist(vehicleId)
        returns (uint256)
    {
        return maintenanceRecords[vehicleId].length;
    }

    function onOwnershipTransfer(
        uint256 vehicleId,
        address oldOwner,
        address newOwner
    )
        external
        onlyVehicleRegistry
    {
        accessGranted[vehicleId][oldOwner] = false;
        accessGranted[vehicleId][newOwner] = true;
    }
}