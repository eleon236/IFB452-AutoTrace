// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface imports allow this contract to call functions from the other AutoTrace contracts
// without needing to include their full source code here.
import "./Interfaces/IServiceProviderRegistry.sol";
import "./Interfaces/IVehicleRegistryContract.sol";

// This contract stores and controls access to vehicle service and repair history.
contract MaintenanceRecordContract {
    // Admin is the account that deployed this contract.
    address public admin;

    // Address of the ServiceProviderRegistry contract, used to check whether mechanics are authorised.
    address public serviceProviderRegistryAddress;

    // Address of the VehicleRegistryContract, used to check vehicle existence and ownership.
    address public vehicleRegistryAddress;

    // Represents one service or repair entry attached to a vehicle.
    struct MaintenanceRecord {
        string recordType;
        string description;
        uint256 mileage;
        string date;
        string evidenceHash;
        address addedBy;
        uint256 timestamp;
    }

    // Stores all maintenance records for each vehicle ID.
    mapping(uint256 => MaintenanceRecord[]) private maintenanceRecords;

    // Tracks which external addresses have been granted permission to view a vehicle's history.
    mapping(uint256 => mapping(address => bool)) public accessGranted;

    // Restricts a function so only the contract admin can call it.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Restricts a function so only the linked VehicleRegistryContract can call it.
    modifier onlyVehicleRegistry() {
        require(msg.sender == vehicleRegistryAddress, "Only VehicleRegistry can call this");
        _;
    }

    // Checks the ServiceProviderRegistry contract to confirm the caller is an approved mechanic/service provider.
    modifier onlyAuthorisedProvider() {
        require(
            IServiceProviderRegistry(serviceProviderRegistryAddress).isAuthorised(msg.sender),
            "Mechanic is not authorised"
        );
        _;
    }

    // Confirms the vehicle exists in the VehicleRegistryContract before allowing records/actions.
    modifier vehicleMustExist(uint256 vehicleId) {
        require(
            IVehicleRegistryContract(vehicleRegistryAddress).isRegistered(vehicleId),
            "Vehicle is not registered"
        );
        _;
    }

    // Restricts a function so only the current vehicle owner can call it.
    modifier onlyOwner(uint256 vehicleId) {
        require(
            msg.sender == IVehicleRegistryContract(vehicleRegistryAddress).getOwner(vehicleId),
            "Only vehicle owner can perform this action"
        );
        _;
    }

    // Allows viewing only by the current owner, granted viewers, or authorised service providers.
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

    // Constructor links this contract to the already deployed ServiceProviderRegistry contract.
    constructor(address _serviceProviderRegistryAddress) {
        require(_serviceProviderRegistryAddress != address(0), "Invalid provider registry address");

        admin = msg.sender;
        serviceProviderRegistryAddress = _serviceProviderRegistryAddress;
    }

    // Links this contract to the VehicleRegistryContract after both contracts are deployed.
    function setVehicleRegistry(address _vehicleRegistryAddress) public onlyAdmin {
        require(_vehicleRegistryAddress != address(0), "Invalid vehicle registry address");
        vehicleRegistryAddress = _vehicleRegistryAddress;
    }

    // Adds a normal service record, such as an oil change or scheduled maintenance.
    // The caller must be an authorised service provider and the vehicle must already exist.
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

    // Adds a repair record, such as replacement parts or major repair work.
    // The repair description and replaced parts are combined into one stored description.
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

    // Allows the current vehicle owner to grant another wallet permission to view the vehicle history.
    function grantAccess(uint256 vehicleId, address viewer)
        public
        vehicleMustExist(vehicleId)
        onlyOwner(vehicleId)
    {
        require(viewer != address(0), "Invalid viewer address");
        accessGranted[vehicleId][viewer] = true;
    }

    // Allows the current vehicle owner to remove a viewer's permission.
    function revokeAccess(uint256 vehicleId, address viewer)
        public
        vehicleMustExist(vehicleId)
        onlyOwner(vehicleId)
    {
        accessGranted[vehicleId][viewer] = false;
    }

    // Returns all maintenance records for a vehicle if the caller has viewing permission.
    function viewMaintenanceHistory(uint256 vehicleId)
        public
        view
        vehicleMustExist(vehicleId)
        canViewHistory(vehicleId)
        returns (MaintenanceRecord[] memory)
    {
        return maintenanceRecords[vehicleId];
    }

    // Returns the stored evidence hash for a specific record so it can be compared with a provided document hash.
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

    // Returns how many service/repair records are stored for a vehicle.
    function getRecordCount(uint256 vehicleId)
        public
        view
        vehicleMustExist(vehicleId)
        returns (uint256)
    {
        return maintenanceRecords[vehicleId].length;
    }

    // Called by VehicleRegistryContract when ownership changes.
    // It removes access from the old owner and grants access to the new owner.
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
