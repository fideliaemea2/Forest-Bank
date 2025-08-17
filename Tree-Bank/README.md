# Sustainable Forest Asset Tokenization Smart Contract

## Overview

The Sustainable Forest Asset Tokenization Smart Contract is a comprehensive blockchain platform designed to enable fractional ownership of forest assets through tokenization. This smart contract facilitates transparent, sustainable forestry management by allowing investors to purchase tokens representing shares in forest parcels and receive proportional proceeds from timber harvests based on verified sustainability metrics.

## Key Features

### Core Functionality
- **Forest Parcel Registration**: Register forest parcels with detailed geographical and forestry information
- **Token-based Fractional Ownership**: Enable fractional ownership through purchasable tokens
- **Sustainable Harvest Management**: Track and verify sustainable forestry practices
- **Transparent Revenue Distribution**: Distribute harvest proceeds proportionally to token holders
- **Certification System**: Authorize verifiers to confirm parcel authenticity and sustainability

### Platform Management
- **User Profile Management**: Maintain user reputation scores and transaction histories
- **Administrative Controls**: Platform pause/resume functionality and pricing management
- **Verification Network**: Authorized certifier system for harvest validation

## Contract Structure

### Data Models

#### Forest Parcel Registry
Each forest parcel contains:
- Parcel owner information
- Geographical coordinates (latitude/longitude)
- Area in hectares
- Primary tree species
- Estimated timber volume
- Planting and projected harvest dates
- Sustainability certification details
- Token supply and pricing information
- Verification and harvest status
- Optional metadata URI

#### Token Holdings
Tracks token balances for each user per forest parcel, enabling fractional ownership tracking.

#### Transaction History
Records all token purchases and transfers with complete transaction details including parties, amounts, and timestamps.

#### Harvest Reports
Stores official harvest verification reports including actual volume measured, sustainability ratings, and certifier information.

#### User Profiles
Maintains user reputation scores, transaction counts, verification status, and registration dates.

## Public Functions

### User Account Management
- `initialize-user-platform-profile`: Create a new user profile on the platform

### Forest Parcel Management
- `register-new-forest-parcel`: Register a new forest parcel with comprehensive details
- `update-parcel-metadata-uri`: Update metadata references for owned parcels

### Token Trading
- `execute-token-purchase`: Purchase tokens from existing parcel owners
- `transfer-tokens-between-users`: Transfer tokens between platform users

### Verification System
- `confirm-parcel-verification`: Verify parcel authenticity (authorized verifiers only)
- `submit-official-harvest-report`: Submit comprehensive harvest verification reports

### Revenue Distribution
- `claim-proportional-harvest-proceeds`: Claim harvest proceeds based on token ownership percentage

### Administrative Functions
- `authorize-new-verifier`: Add new authorized verifiers to the platform
- `revoke-verifier-authorization`: Remove verifier authorization
- `activate-platform-pause`: Pause all platform operations
- `deactivate-platform-pause`: Resume platform operations
- `update-base-timber-pricing`: Adjust base timber pricing for calculations

## Query Functions

### Information Retrieval
- `retrieve-forest-parcel-details`: Get complete parcel information
- `retrieve-user-token-balance`: Check token holdings for specific parcels
- `retrieve-total-parcels-count`: Get total number of registered parcels
- `retrieve-platform-pause-status`: Check if platform operations are paused
- `retrieve-user-profile-information`: Get user profile details
- `retrieve-harvest-report-details`: Access harvest verification reports
- `check-verifier-authorization-status`: Verify if an address is an authorized certifier

### Calculations
- `calculate-total-token-value`: Calculate total value for a given number of tokens
- `determine-parcel-harvest-readiness`: Check if a parcel is ready for harvest

## Validation and Security

### Input Validation
- Geographical coordinates must be within valid latitude/longitude ranges
- Tree species names must be non-empty
- All monetary amounts and quantities must be positive
- Time periods must be logically consistent
- Metadata URIs must be non-empty when provided

### Access Control
- Only parcel owners can update their parcel metadata
- Only authorized verifiers can confirm parcel verification and submit harvest reports
- Only the contract administrator can manage verifiers and platform settings
- Users cannot purchase tokens from themselves or transfer tokens to themselves

### Business Logic Validation
- Harvest claims require completed harvest reports
- Token purchases cannot exceed available token supply
- Transfers require sufficient token balance
- Harvest reports can only be submitted after projected harvest dates

## Error Handling

The contract implements comprehensive error handling with specific error codes:
- ERR-UNAUTHORIZED-ACCESS (100): Access denied
- ERR-RESOURCE-NOT-FOUND (101): Requested resource doesn't exist
- ERR-RESOURCE-ALREADY-EXISTS (102): Resource already exists
- ERR-INVALID-AMOUNT-SPECIFIED (103): Invalid amount provided
- ERR-INSUFFICIENT-TOKEN-BALANCE (104): Insufficient tokens
- ERR-INVALID-TIME-PERIOD (105): Invalid time period
- ERR-CONTRACT-PERIOD-EXPIRED (106): Contract period has expired
- ERR-HARVEST-NOT-MATURE (107): Harvest not ready
- ERR-INVALID-COORDINATE-VALUES (108): Invalid geographical coordinates
- ERR-INVALID-TREE-SPECIES (109): Invalid tree species
- ERR-TOKEN-TRANSFER-FAILED (110): Token transfer failed
- ERR-INVALID-INPUT-PROVIDED (111): Invalid input provided

## Constants and Configuration

### Geographical Limits
- Latitude range: -90,000,000 to 90,000,000 (representing degrees * 1,000,000)
- Longitude range: -180,000,000 to 180,000,000 (representing degrees * 1,000,000)

### Platform Settings
- Maximum sustainability score: 100
- Minimum reputation score: 100
- Percentage multiplier: 100 (for precise percentage calculations)
- Default base timber token price: 1,000,000 microSTX

## Usage Workflow

### For Forest Owners
1. Initialize user profile
2. Register forest parcel with detailed information
3. Set token supply and pricing
4. Wait for parcel verification by authorized certifiers
5. Sell tokens to investors
6. Submit for harvest verification when ready
7. Distribute proceeds to token holders

### For Investors
1. Initialize user profile
2. Browse available forest parcels
3. Purchase tokens from parcel owners
4. Monitor parcel status and sustainability metrics
5. Claim proportional harvest proceeds after harvest completion

### For Verifiers
1. Receive authorization from contract administrator
2. Verify forest parcel authenticity and documentation
3. Confirm parcel verification status
4. Submit official harvest reports with sustainability ratings

### For Administrators
1. Authorize and manage verifiers
2. Monitor platform operations
3. Pause/resume platform when necessary
4. Adjust pricing and platform parameters

## Technical Requirements

- Built for Stacks blockchain using Clarity smart contract language
- Requires STX for token purchases and transaction fees
- Supports fungible token standard for forest asset representation
- Implements comprehensive data mapping for efficient queries

## Security Considerations

- All functions include appropriate access control checks
- Input validation prevents malicious or erroneous data entry
- Platform pause functionality allows emergency stops
- Token balance tracking prevents double-spending
- Verification system ensures harvest report authenticitys