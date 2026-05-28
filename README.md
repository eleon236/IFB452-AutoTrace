# AutoTrace

AutoTrace is a blockchain-based vehicle maintenance history system designed to make vehicle service records more transparent, tamper-resistant, and easier to verify.

The system allows approved mechanics to record maintenance and repair history on-chain, while vehicle owners control who can view their vehicle’s history. Buyers, dealers, and inspectors can then verify records before resale, inspection, or trade-in.

---

# Project Purpose

Used vehicle service histories can be incomplete, altered, or difficult to verify. AutoTrace addresses this by using Ethereum smart contracts to create a shared record of vehicle maintenance events across multiple stakeholders.

The project demonstrates:

- Multi-stakeholder blockchain interaction
- Role-based permissions
- Cross-contract communication
- Tamper-resistant maintenance records
- Owner-controlled access to vehicle history
- Blockchain-based verification of vehicle servicing

---

# Why Blockchain?

AutoTrace was specifically designed as a blockchain application because the system:

- Requires shared state across multiple independent stakeholders
- Has multiple writers (mechanics, administrators, owners)
- Cannot rely on a single trusted central authority
- Requires tamper-resistant records
- Benefits from transparent verification and auditability

Traditional centralised databases would require all stakeholders to trust a single organisation. AutoTrace instead uses Ethereum smart contracts to provide decentralised verification and immutable maintenance records.

---

# Stakeholders

| Stakeholder | Role |
|---|---|
| Admin / Manufacturer | Registers vehicles and approves service providers |
| Vehicle Owner | Owns the vehicle and controls access to its history |
| Mechanic / Service Centre | Adds service and repair records if approved |
| Buyer / Dealer / Inspector | Views and verifies vehicle history when granted access |

---

# Smart Contracts

The project uses three Solidity smart contracts.

---

## 1. ServiceProviderRegistry

This contract manages approved mechanics and service providers.

### Responsibilities

- Register approved mechanics
- Revoke mechanic authorisation
- Verify whether a mechanic is authorised

### Main Functions

- `registerServiceProvider()`
- `revokeServiceProvider()`
- `isAuthorised()`
- `getProviderDetails()`

---

## 2. VehicleRegistryContract

This contract manages vehicle identities and ownership.

### Responsibilities

- Register vehicles
- Store ownership information
- Transfer vehicle ownership
- Validate vehicle existence

### Main Functions

- `registerVehicle()`
- `updateOwner()`
- `getVehicleDetails()`
- `isRegistered()`
- `getOwner()`

---

## 3. MaintenanceRecordContract

This contract stores service and repair records.

### Responsibilities

- Add service records
- Add repair records
- Manage viewing permissions
- Verify maintenance history
- Handle access updates during ownership transfer

### Main Functions

- `addServiceRecord()`
- `addRepairRecord()`
- `grantAccess()`
- `revokeAccess()`
- `viewMaintenanceHistory()`
- `verifyRecord()`
- `getRecordCount()`
- `onOwnershipTransfer()`

---

# Smart Contract Interaction

AutoTrace uses direct smart contract interaction to enforce system rules and permissions.

---

## Mechanic Verification

Before allowing a mechanic to create a service or repair record, `MaintenanceRecordContract` checks `ServiceProviderRegistry` to confirm the mechanic is authorised.

```text
MaintenanceRecordContract
→ ServiceProviderRegistry.isAuthorised()
```

This prevents unauthorised users from writing maintenance records.

---

## Vehicle Validation

Before maintenance records are added, the maintenance contract verifies that the vehicle exists through `VehicleRegistryContract`.

```text
MaintenanceRecordContract
→ VehicleRegistryContract.isRegistered()
```

---

## Ownership Verification

When access permissions are checked, the maintenance contract retrieves the current vehicle owner from `VehicleRegistryContract`.

```text
MaintenanceRecordContract
→ VehicleRegistryContract.getOwner()
```

---

## Ownership Transfer

When ownership changes, `VehicleRegistryContract` communicates directly with `MaintenanceRecordContract` to update viewing permissions.

```text
VehicleRegistryContract
→ MaintenanceRecordContract.onOwnershipTransfer()
```

This demonstrates cross-contract communication between smart contracts.

---

# Project Structure

```text
AutoTrace/
├── contracts/
│   ├── interfaces/
│   │   ├── IServiceProviderRegistry.sol
│   │   ├── IVehicleRegistryContract.sol
│   │   └── IMaintenanceRecordContract.sol
│   ├── ServiceProviderRegistry.sol
│   ├── VehicleRegistryContract.sol
│   └── MaintenanceRecordContract.sol
├── frontend/
│   └── index.html
├── diagrams/
├── README.md
```

---

# Technologies Used

- Solidity
- Ethereum
- Sepolia Testnet
- Remix IDE
- MetaMask
- ethers.js
- HTML
- CSS
- JavaScript
- GitHub

---

# Smart Contract Deployment Process

The AutoTrace smart contracts are deployed using Remix IDE and MetaMask on the Ethereum Sepolia test network.

---

## Prerequisites

Before deployment:

- Install MetaMask
- Connect MetaMask to the Sepolia testnet
- Obtain Sepolia ETH from a faucet
- Open the contracts in Remix IDE

---

# Deployment Order

The contracts must be deployed in the following order because they depend on each other’s addresses for cross-contract communication.

---

## 1. Deploy ServiceProviderRegistry

Deploy:

```text
ServiceProviderRegistry
```

This contract manages approved mechanics and service providers.

After deployment, copy the deployed contract address.

---

## 2. Deploy MaintenanceRecordContract

Deploy:

```text
MaintenanceRecordContract
```

Constructor input:

```text
_serviceProviderRegistryAddress
```

Paste the deployed `ServiceProviderRegistry` address before deployment.

This contract stores maintenance records and validates mechanics through the provider registry.

After deployment, copy the deployed contract address.

---

## 3. Deploy VehicleRegistryContract

Deploy:

```text
VehicleRegistryContract
```

This contract manages vehicle registration and ownership.

After deployment, copy the deployed contract address.

---

## 4. Link MaintenanceRecordContract to VehicleRegistryContract

In the deployed `MaintenanceRecordContract`, call:

```text
setVehicleRegistry(vehicleRegistryAddress)
```

Paste the deployed `VehicleRegistryContract` address.

This allows the maintenance contract to:
- verify vehicles
- retrieve ownership
- manage permissions

---

## 5. Link VehicleRegistryContract to MaintenanceRecordContract

In the deployed `VehicleRegistryContract`, call:

```text
setMaintenanceContract(maintenanceRecordAddress)
```

Paste the deployed `MaintenanceRecordContract` address.

This enables ownership transfer communication between contracts.

---

# Why Deployment Order Matters

The contracts interact directly with one another using deployed contract addresses.

For example:

```text
MaintenanceRecordContract
→ checks ServiceProviderRegistry for authorised mechanics

VehicleRegistryContract
→ communicates with MaintenanceRecordContract during ownership transfer
```

Because smart contracts cannot automatically discover each other, they must be manually linked after deployment.

---

# Frontend Setup

The frontend provides a user interface for interacting with the deployed smart contracts.

The frontend connects to:
- MetaMask
- Ethereum Sepolia
- deployed contract addresses
- smart contract ABIs using ethers.js

---

## Running the Frontend

Inside the frontend folder:

unzip downloaded github code

```bash
cd Front End
```
Then:

```text
lite-server
```

or

```bash
npx.cmd http-server
```

Then open:

```text
http://127.0.0.1:8080
```

---

# Connecting the Frontend

After deployment:

1. Connect MetaMask
2. Ensure MetaMask is on Sepolia
3. Paste deployed contract addresses into the frontend
4. Click `Load Contracts`

The frontend will then communicate with the deployed smart contracts.

---

# MetaMask Stakeholder Simulation

Different MetaMask accounts simulate different stakeholders.

Example setup:

| MetaMask Account | Stakeholder |
|---|---|
| Account 1 | Admin |
| Account 2 | Mechanic |
| Account 3 | Vehicle Owner |
| Account 4 | Buyer / Inspector |

The currently connected MetaMask account determines the permissions available in the application.

---

# Demo Workflow

The AutoTrace demo demonstrates:

---

## 1. Admin Approves Mechanic

Admin authorises a mechanic through `ServiceProviderRegistry`.

---

## 2. Admin Registers Vehicle

A vehicle is registered and linked to an owner wallet.

---

## 3. Mechanic Adds Maintenance Record

An approved mechanic adds a service or repair record.

The maintenance contract verifies:
- mechanic authorisation
- vehicle existence

before accepting the transaction.

---

## 4. Unauthorised User Fails

An unauthorised account attempts to add a maintenance record and is rejected by the smart contract.

This demonstrates smart contract permission enforcement.

---

## 5. Owner Grants Access

The vehicle owner grants viewing access to a buyer or inspector.

---

## 6. Buyer Views Maintenance History

The buyer can now retrieve maintenance records from the blockchain.

---

## 7. Record Verification

The buyer verifies the authenticity of maintenance records using hashes stored on-chain.

---

## 8. Ownership Transfer

Ownership is transferred to a new wallet address.

This triggers cross-contract communication between:
- VehicleRegistryContract
- MaintenanceRecordContract

---

# Hash Verification

Instead of storing full invoices or files directly on-chain, AutoTrace stores hashes representing supporting documents.

Benefits:
- lower blockchain storage cost
- improved privacy
- tamper detection

If a document changes, its hash also changes.

This allows buyers and inspectors to verify document integrity.

---

# Security Features

AutoTrace includes:

- Role-based access control
- Ownership verification
- Mechanic authorisation
- Smart contract enforced permissions
- Immutable maintenance records
- Tamper-resistant verification

---

# Limitations

While AutoTrace improves record integrity after data is written to the blockchain, it cannot fully guarantee that mechanics always enter truthful information.

The system also stores document hashes rather than full documents to reduce storage cost and improve efficiency.

---

# Future Improvements

Potential future improvements include:

- IPFS document storage
- QR code verification
- Insurance integration
- Manufacturer integration
- Roadworthy certificate support
- Improved frontend dashboard
- Advanced analytics and reporting
- Mobile application support

---

# GitHub Repository

This project is maintained using GitHub for:
- version control
- collaborative development
- deployment management
- project documentation

---

# Authors

AutoTrace – Blockchain Vehicle Maintenance Verification System

Bohan Yang & Emily Leonard
