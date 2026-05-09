// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ServiceProviderRegistry {
    address public admin;

    struct ServiceProvider {
        string name;
        string licenceNumber;
        bool authorised;
    }

    mapping(address => ServiceProvider) public providers;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerServiceProvider(
        address providerAddress,
        string memory name,
        string memory licenceNumber
    ) public onlyAdmin {
        require(providerAddress != address(0), "Invalid provider address");

        providers[providerAddress] = ServiceProvider({
            name: name,
            licenceNumber: licenceNumber,
            authorised: true
        });
    }

    function revokeServiceProvider(address providerAddress) public onlyAdmin {
        require(providers[providerAddress].authorised, "Provider not authorised");
        providers[providerAddress].authorised = false;
    }

    function isAuthorised(address providerAddress) public view returns (bool) {
        return providers[providerAddress].authorised;
    }

    function getProviderDetails(address providerAddress)
        public
        view
        returns (string memory, string memory, bool)
    {
        ServiceProvider memory provider = providers[providerAddress];
        return (provider.name, provider.licenceNumber, provider.authorised);
    }
}