
pragma solidity ^0.8.20;

// Imports the interface used to call the MaintenanceRecordContract during ownership transfers.
import  "./Interfaces/IMaintenanceRecordContract.sol";

// VehicleRegistryContract is responsible for registering vehicles and tracking current ownership.
contract VehicleRegistryContract {
    // The admin account is the wallet that deployed this contract.
    // Only this address can register vehicles and set linked contract addresses.
    address public admin;

    // Stores the deployed MaintenanceRecordContract address so this contract can notify it when ownership changes.
    address public maintenanceContractAddress;

    // Counts the number of registered vehicles and is also used to generate vehicle IDs.
    uint256 public vehicleCount;

    // Stores the main vehicle identity and ownership information.
    struct Vehicle {
        string vin;
        string make;
        string model;
        uint256 year;
        address owner;
        bool registered;
    }

    // Maps a vehicle ID to its vehicle information.
    mapping(uint256 => Vehicle) public vehicles;

    // Tracks which VINs have already been registered to prevent duplicate vehicle registration.
    mapping(string => bool) public vinExists;

    // Restricts certain functions so only the admin/deployer can call them.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Restricts certain functions so only the current owner of a registered vehicle can call them.
    modifier onlyVehicleOwner(uint256 vehicleId) {
        require(vehicles[vehicleId].registered, "Vehicle does not exist");
        require(msg.sender == vehicles[vehicleId].owner, "Only current owner can perform this action");
        _;
    }

    // Sets the contract deployer as the admin.
    constructor() {
        admin = msg.sender;
    }

    // Links this registry contract to the MaintenanceRecordContract.
    // This is required so ownership transfers can automatically update access permissions in the maintenance contract.
    function setMaintenanceContract(address _maintenanceContractAddress) public onlyAdmin {
        require(_maintenanceContractAddress != address(0), "Invalid maintenance contract address");
        maintenanceContractAddress = _maintenanceContractAddress;
    }

    // Registers a new vehicle on-chain.
    // Only the admin can register vehicles, and each VIN can only be registered once.
    function registerVehicle(
        string memory vin,
        string memory make,
        string memory model,
        uint256 year,
        address ownerAddress
    ) public onlyAdmin returns (uint256) {
        require(ownerAddress != address(0), "Invalid owner address");
        require(!vinExists[vin], "VIN already registered");

        // Increment vehicleCount to create a new unique vehicle ID.
        vehicleCount++;

        // Store the vehicle details under the new vehicle ID.
        vehicles[vehicleCount] = Vehicle({
            vin: vin,
            make: make,
            model: model,
            year: year,
            owner: ownerAddress,
            registered: true
        });

        // Mark this VIN as used so it cannot be registered again.
        vinExists[vin] = true;

        // Return the newly created vehicle ID.
        return vehicleCount;
    }

    // Transfers vehicle ownership from the current owner to a new owner.
    // This function also notifies the MaintenanceRecordContract so access control can stay in sync.
    function updateOwner(uint256 vehicleId, address newOwnerAddress)
        public
        onlyVehicleOwner(vehicleId)
    {
        require(newOwnerAddress != address(0), "Invalid new owner address");

        // Save the old owner before updating the vehicle record.
        address oldOwner = vehicles[vehicleId].owner;

        // Update the vehicle's owner address.
        vehicles[vehicleId].owner = newOwnerAddress;

        // If the maintenance contract has been linked, notify it that ownership has changed.
        if (maintenanceContractAddress != address(0)) {
            IMaintenanceRecordContract(maintenanceContractAddress)
                .onOwnershipTransfer(vehicleId, oldOwner, newOwnerAddress);
        }
    }

    // Returns the basic details of a registered vehicle.
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

    // Checks whether a vehicle ID exists in the registry.
    // This is used by MaintenanceRecordContract before adding service or repair records.
    function isRegistered(uint256 vehicleId) public view returns (bool) {
        return vehicles[vehicleId].registered;
    }

    // Returns the current owner of a registered vehicle.
    // This is used by MaintenanceRecordContract for access control checks.
    function getOwner(uint256 vehicleId) public view returns (address) {
        require(vehicles[vehicleId].registered, "Vehicle does not exist");
        return vehicles[vehicleId].owner;
    }
}
