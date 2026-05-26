// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ServiceProviderRegistry
/// @notice Manages the list of approved mechanics/service providers for AutoTrace.
/// @dev This contract acts as the trust gatekeeper. Other contracts can call
///      isAuthorised() to check whether a wallet is allowed to add maintenance records.
contract ServiceProviderRegistry {
    // The wallet that deployed this contract becomes the system admin.
    // Only this address can approve or revoke service providers.
    address public admin;

    // Stores basic information about a mechanic or service centre.
    struct ServiceProvider {
        string name;
        string licenceNumber;
        bool authorised;
    }

    // Maps a service provider wallet address to its provider details.
    mapping(address => ServiceProvider) public providers;

    /// @notice Restricts selected functions so only the admin can call them.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    /// @notice Sets the contract deployer as the admin.
    constructor() {
        admin = msg.sender;
    }

    /// @notice Registers or re-approves a mechanic/service provider.
    /// @dev Only the admin can call this function.
    /// @param providerAddress Wallet address of the mechanic or service centre.
    /// @param name Business or provider name.
    /// @param licenceNumber Licence or registration number for display/audit purposes.
    function registerServiceProvider(
        address providerAddress,
        string memory name,
        string memory licenceNumber
    ) public onlyAdmin {
        require(providerAddress != address(0), "Invalid provider address");

        // Store the provider details and mark the provider as authorised.
        providers[providerAddress] = ServiceProvider({
            name: name,
            licenceNumber: licenceNumber,
            authorised: true
        });
    }

    /// @notice Revokes an existing service provider's permission to write records.
    /// @dev Once revoked, MaintenanceRecordContract checks will fail for this provider.
    /// @param providerAddress Wallet address of the provider to revoke.
    function revokeServiceProvider(address providerAddress) public onlyAdmin {
        require(providers[providerAddress].authorised, "Provider not authorised");
        providers[providerAddress].authorised = false;
    }

    /// @notice Checks whether a provider is currently authorised.
    /// @dev This is the key function called by MaintenanceRecordContract before writes.
    /// @param providerAddress Wallet address to check.
    /// @return True if the provider is authorised, false otherwise.
    function isAuthorised(address providerAddress) public view returns (bool) {
        return providers[providerAddress].authorised;
    }

    /// @notice Returns the stored details for a service provider.
    /// @param providerAddress Wallet address of the provider.
    /// @return Provider name, licence number, and authorisation status.
    function getProviderDetails(address providerAddress)
        public
        view
        returns (string memory, string memory, bool)
    {
        ServiceProvider memory provider = providers[providerAddress];
        return (provider.name, provider.licenceNumber, provider.authorised);
    }
}
