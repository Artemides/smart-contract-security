# Protocol Notes

- Allows Link deposit and receive shares froma chainlink operator node.

### Staking Pool

- handles liquid staking of tokens giving stTokens in return at a ratio of 1:1
- in case of Link they are deposited into Chainlink Stacking contracts
- is Rebasing token so that shares values will be adjusted postively or negatively automatically.

### Priority Pool

- used to queue assets so that stake them into `StakingPool`

### Withdrawl Pool

- where users can queue in a FIFO withdrawals if insuficient liquidity in Priority Pool
- withdrawn occurs if new deposits are received in the Priority pool or liquidity is available in the Staking Pool.

### LSTRewardSplitter & Controller

- allows users to deposit and split any rewards involved
- manager: controls multiple splitters

# Q&A

1. delegated liquid staking?
2. Interoperabilty by stLink.
3. How deposited and withdraw rooms are calculated?

# SDL Governance tokens

- when staked shares are received as (reSDL)
- if staked is locked the ratio is higher than 1:1 (boost), withdraw can be started as half of the locking period is at least the half
- it not locket the ratio is 1:1 and can be withdrawn anytime
- SLD holders gains priotity for withdraws
- reSDL can be transfered so underlying SDL will also be transfered
