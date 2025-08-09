# Token Giveaway Distribution Contract

A Stacks blockchain smart contract for managing token giveaways with whitelist-based distribution and administrative controls.

## Overview

This smart contract enables secure and controlled token distribution through a giveaway mechanism. It allows administrators to manage eligible recipients, distribute tokens to whitelisted users, and reclaim unused tokens after a specified period.

## Features

- **Whitelist Management**: Add/remove eligible users for token rewards
- **Batch Operations**: Efficiently whitelist multiple users at once
- **Configurable Rewards**: Adjustable token amounts per recipient
- **Claim Prevention**: Users can only claim rewards once
- **Time-based Reclaim**: Unused tokens can be withdrawn after a set period
- **Event Logging**: Track all contract interactions
- **Access Control**: Admin-only functions for contract management

## Contract Details

- **Token Name**: `token-giveaway-distribution`
- **Initial Supply**: 1,000,000,000 tokens
- **Default Reward**: 100 tokens per user
- **Default Withdrawal Period**: 10,000 blocks

## Core Functions

### Admin Functions

#### `whitelist-user(user-principal)`
Adds a single user to the whitelist.
- **Access**: Admin only
- **Parameters**: `user-principal` - The principal address to whitelist
- **Returns**: Success confirmation

#### `batch-whitelist-users(user-addresses)`
Adds multiple users to the whitelist in a single transaction.
- **Access**: Admin only
- **Parameters**: `user-addresses` - List of up to 200 principal addresses
- **Returns**: Success confirmation

#### `remove-whitelisted-user(user-principal)`
Removes a user from the whitelist.
- **Access**: Admin only
- **Parameters**: `user-principal` - The principal address to remove
- **Returns**: Success confirmation

#### `set-reward-amount(updated-amount)`
Updates the token reward amount per user.
- **Access**: Admin only
- **Parameters**: `updated-amount` - New reward amount (must be > 0)
- **Returns**: New reward amount

#### `set-withdrawal-period(updated-period)`
Updates the withdrawal period for unused tokens.
- **Access**: Admin only
- **Parameters**: `updated-period` - New period in blocks (must be > 0)
- **Returns**: New withdrawal period

### User Functions

#### `collect-reward-tokens()`
Allows whitelisted users to claim their token rewards.
- **Access**: Any whitelisted user
- **Requirements**: 
  - User must be whitelisted
  - User hasn't already claimed
  - Giveaway must be active
  - Sufficient contract balance
- **Returns**: Amount of tokens claimed

### Administrative Functions

#### `withdraw-unused-tokens()`
Burns unused tokens after the withdrawal period ends.
- **Access**: Admin only
- **Requirements**: Withdrawal period must have elapsed
- **Returns**: Amount of tokens burned

## Read-Only Functions

- `get-giveaway-status()` - Check if giveaway is active
- `check-user-whitelist-status(user-principal)` - Verify if user is whitelisted
- `check-user-reward-status(user-principal)` - Check if user has claimed rewards
- `get-user-collected-amount(user-principal)` - Get amount claimed by user
- `get-total-distributed-tokens()` - Total tokens distributed so far
- `get-reward-per-user()` - Current reward amount per user
- `get-withdrawal-period()` - Current withdrawal period in blocks
- `get-giveaway-start-block()` - Block height when contract was deployed
- `get-logged-event(event-id)` - Retrieve specific event log

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-UNAUTHORIZED-ACCESS` | Caller is not the contract admin |
| 101 | `ERR-REWARD-ALREADY-COLLECTED` | User has already claimed their reward |
| 102 | `ERR-USER-NOT-WHITELISTED` | User is not eligible for rewards |
| 103 | `ERR-INSUFFICIENT-CONTRACT-FUNDS` | Contract doesn't have enough tokens |
| 104 | `ERR-GIVEAWAY-SUSPENDED` | Giveaway is currently inactive |
| 105 | `ERR-INVALID-REWARD-AMOUNT` | Reward amount must be greater than 0 |
| 106 | `ERR-WITHDRAWAL-PERIOD-ACTIVE` | Cannot withdraw during active period |
| 107 | `ERR-INVALID-USER-ADDRESS` | User address is invalid or already exists |
| 108 | `ERR-INVALID-TIME-PERIOD` | Time period must be greater than 0 |

## Usage Example

1. **Deploy Contract**: Contract automatically mints initial token supply
2. **Whitelist Users**: Admin calls `whitelist-user` or `batch-whitelist-users`
3. **Users Claim**: Whitelisted users call `collect-reward-tokens`
4. **Withdraw Unused**: After withdrawal period, admin can call `withdraw-unused-tokens`

## Security Features

- **Single Claim**: Users can only claim rewards once
- **Access Control**: Critical functions restricted to admin
- **Input Validation**: All inputs are validated before processing
- **Time Locks**: Withdrawal protection during active giveaway period
- **Event Logging**: Full audit trail of contract interactions

## Development & Deployment

This contract is written in Clarity for the Stacks blockchain. Deploy using Clarinet or similar Stacks development tools.

### Prerequisites
- Stacks wallet for contract deployment
- Sufficient STX for deployment costs
- Clarinet for local testing (recommended)

### Testing
Test all functions thoroughly before mainnet deployment, especially:
- Whitelist management
- Token distribution mechanics
- Access control enforcement
- Time-based withdrawal functionality