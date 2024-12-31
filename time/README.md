# Clarity TimeLock Vault

## Features

- **Token Locking**: Lock STX tokens for a customizable time period (up to 1 year)
- **Secure Withdrawals**: Automated time-based unlock mechanism
- **Emergency Controls**: Contract owner can help users recover funds in emergencies
- **Ownership Management**: Transferable contract ownership for long-term maintenance
- **Full Transparency**: All operations are verifiable on-chain

## Function Overview

### User Functions

1. `lock-tokens`
   - Lock STX tokens for a specified period
   - Parameters:
     - `lock-period`: Duration in blocks (max: 52,560 blocks ≈ 1 year)
   - Returns: `(ok true)` on success

2. `withdraw`
   - Withdraw tokens after the lock period expires
   - No parameters needed
   - Returns: `(ok true)` on success

### Admin Functions

1. `emergency-withdraw`
   - Allows contract owner to help users withdraw funds in emergency situations
   - Parameters:
     - `user`: Principal address of the user whose funds need to be withdrawn
   - Returns: `(ok true)` on success

2. `transfer-ownership`
   - Transfer contract ownership to a new principal
   - Parameters:
     - `new-owner`: Principal address of the new owner
   - Returns: `(ok true)` on success

### Read-Only Functions

1. `get-locked-amount`
   - Check the amount of tokens locked for a given user
   - Parameters:
     - `owner`: Principal address to check
   - Returns: Amount of locked tokens or error if none

2. `get-unlock-height`
   - Check when tokens will be unlocked for a given user
   - Parameters:
     - `owner`: Principal address to check
   - Returns: Block height for unlock or error if no tokens locked

3. `has-locked-tokens`
   - Check if a user has any locked tokens
   - Parameters:
     - `owner`: Principal address to check
   - Returns: Boolean indicating if tokens are locked

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Caller not authorized for this operation
- `ERR-NO-LOCKED-TOKENS (u101)`: No tokens locked for the specified user
- `ERR-NOT-UNLOCKED (u102)`: Lock period hasn't expired yet
- `ERR-INVALID-AMOUNT (u103)`: Invalid token amount specified
- `ERR-TRANSFER-FAILED (u104)`: Token transfer operation failed
- `ERR-INVALID-LOCK-PERIOD (u105)`: Lock period outside valid range
- `ERR-INVALID-PRINCIPAL (u106)`: Invalid principal address specified

## Security Considerations

1. **Lock Period Limits**
   - Maximum lock period is capped at ~1 year (52,560 blocks)
   - Minimum lock period must be greater than 0

2. **Access Controls**
   - Only contract owner can perform emergency withdrawals
   - Only token owners can initiate standard withdrawals
   - Ownership transfers require current owner authorization

3. **Data Validation**
   - All inputs are validated before processing
   - Principal addresses checked for validity
   - Transfer operations verified for success

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/stacks-timelock.git
cd stacks-timelock
```

2. Install dependencies:
```bash
npm install
```

3. Run tests:
```bash
npm test
```

## Deployment

1. Configure your deployment settings in `Clarinet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy --network mainnet
```

## Testing

The contract includes a comprehensive test suite covering:
- Token locking functionality
- Withdrawal mechanisms
- Emergency procedures
- Access controls
- Edge cases and error conditions

Run the test suite:
```bash
clarinet test
```
## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request