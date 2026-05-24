# AutoTrace

AutoTrace is a blockchain-based vehicle maintenance history system designed to make vehicle service records more transparent, tamper-resistant, and easier to verify.

The system allows approved mechanics to record maintenance and repair history on-chain, while vehicle owners control who can view their vehicle’s history. Buyers, dealers, and inspectors can then verify records before resale, inspection, or trade-in.

## Project Purpose

Used vehicle service histories can be incomplete, altered, or difficult to verify. AutoTrace addresses this by using Ethereum smart contracts to create a shared record of vehicle maintenance events across multiple stakeholders.

The project demonstrates:

- Multi-stakeholder blockchain interaction
- Role-based permissions
- Cross-contract communication
- Tamper-resistant maintenance records
- Owner-controlled access to vehicle history

## Stakeholders

| Stakeholder | Role |
|---|---|
| Admin / Manufacturer | Registers vehicles and approves service providers |
| Vehicle Owner | Owns the vehicle and controls access to its history |
| Mechanic / Service Centre | Adds service and repair records if approved |
| Buyer / Dealer / Inspector | Views and verifies vehicle history when granted access |

## Smart Contracts

The project uses three smart contracts:

### 1. ServiceProviderRegistry

Manages approved mechanics and service centres.

Main functions:

- `registerServiceProvider()`
- `revokeServiceProvider()`
- `isAuthorised()`
- `getProviderDetails()`

### 2. VehicleRegistryContract

Manages vehicle identities and ownership.

Main functions:

- `registerVehicle()`
- `updateOwner()`
- `getVehicleDetails()`
- `isRegistered()`
- `getOwner()`

### 3. MaintenanceRecordContract

Stores vehicle service and repair records.

Main functions:

- `addServiceRecord()`
- `addRepairRecord()`
- `grantAccess()`
- `revokeAccess()`
- `viewMaintenanceHistory()`
- `verifyRecord()`
- `onOwnershipTransfer()`

## Contract Interaction

AutoTrace uses direct smart contract interaction to enforce system rules.

### Mechanic verification

When a mechanic adds a service or repair record, `MaintenanceRecordContract` checks `ServiceProviderRegistry` to confirm the mechanic is authorised.

```text
MaintenanceRecordContract → ServiceProviderRegistry.isAuthorised()