** Draft **

This is a simple multi-recipient straight-line vesting contract with an
optional cliff. The intended use is with future rounds of Radicle Seeder
rewards, but it is generally applicable to other vesting situations.

### Initialisation

The deployer must provide

- `admin`: controls grants / revocations
- `coin`: the vesting token (ERC20)
- `period`: the vesting period
- `cliff`: the vesting cliff

### Control

This contract is controlled by an `admin`, which has the power to both `grant`
and `revoke` vesting `awards`.

### Granting

The `admin` can call `grant(address user, uint start, uint amount)`, to
create an award of size `amount` for `user`, with vesting commencing at
the given `start`.

To grant multiple users at once at a single start time, the admin can call
`grant(address[] user, uint start, uint[] amount)`, with a list of
users, the start time, and a list of amounts.

Awards are indexed by user and by start time, so one user can have
multiple awards with different start times.  If a user already has an
award at a given start time, subsequent awards will add to this.

### Revoking

The admin can call `revoke(address user, uint start)` to cancel the unvested
share of a single user award. It is not possible to revoke the vested share.

### Timing

All times are expressed in seconds.

There are two configurable time variables,

- `period`: the vesting duration
- `cliff`: the duration after vesting start when vested tokens become claimable

These can be *reduced only* by the admin with `setPeriod` and `setCliff`
respectively.

### Claiming

A user can call `claim(uint start)` at any time to claim their vested
tokens from a given start time. An EIP-712 equivalent is also provided.
