# Stack Fund Hub

A decentralized freelance marketplace built on Stacks blockchain with escrow-based payments, DAO governance, and reputation systems.

## Overview

Stack Fund Hub is a smart contract-based platform that enables secure job posting, bidding, and payment settlements between clients and freelancers using STX tokens. The platform leverages escrow mechanisms, milestone tracking, and decentralized voting to ensure trust and fairness.

## Features

### Core Functionality

- **Job Management**
  - Post jobs with specified payment amounts
  - Track job milestones and completion status
  - Unique job ID generation and management

- **Bidding System**
  - Freelancers can bid on available jobs
  - Dynamic auction system with minimum bids
  - Highest bidder tracking for competitive pricing

- **Escrow & Payments**
  - Client deposits funds into smart contract escrow
  - Secure payment release via DAO consensus
  - Milestone-based submission tracking

- **DAO Governance**
  - Quorum-based voting system (3 votes required)
  - Community approval for fund releases
  - Prevents duplicate voting on same job

- **Reputation System**
  - Rate freelancers on a scale of 0-5
  - Cumulative reputation scoring
  - Public reputation lookup

- **Staking & Subscriptions**
  - Minimum 50,000 STX stake requirement for participation
  - Subscription-based access model
  - Account verification via staking

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | `ERR-NOT-FOUND` | Job or auction not found |
| 101 | `ERR-INSUFFICIENT-FUNDS` | Insufficient balance for operation |
| 103 | `ERR-UNAUTHORIZED` | Unauthorized action attempt |
| 104 | `ERR-NOT-FREELANCER` | Address is not the assigned freelancer |
| 105 | `ERR-ALREADY-VOTED` | Address has already voted |
| 106 | `ERR-AUCTION-NOT-FOUND` | Auction does not exist |
| 107 | `ERR-BID-TOO-LOW` | Bid amount below minimum |
| 108 | `ERR-AUCTION-ENDED` | Auction period has ended |
| 109 | `ERR-INVALID-SCORE` | Score outside 0-5 range |
| 110 | `ERR-INVALID-AMOUNT` | Invalid amount specified |

## Constants

- `DAO-QUORUM`: 3 votes required for payment approval
- `MIN-STAKING-AMOUNT`: 50,000 STX minimum stake

## Usage

### For Clients

```clarity
;; 1. Subscribe to platform
(subscribe)

;; 2. Post a job
(post-job u100000) ;; 100,000 STX for job amount

;; 3. Deposit funds to escrow
(deposit-escrow u1) ;; Job ID 1

;; 4. Vote to approve completion
(vote-approve u1) ;; Job ID 1
```

### For Freelancers

```clarity
;; 1. Stake minimum amount
(stake)

;; 2. Subscribe to platform
(subscribe)

;; 3. Bid on a job
(bid-job u1) ;; Job ID 1

;; 4. Submit milestone
(submit-milestone u1) ;; Job ID 1
```

### Job Auction

```clarity
;; Create auction with initial bid and end block
(create-job-auction u1 u50000 u1000) ;; Job 1, 50k min bid, ends at block 1000

;; Place a competitive bid
(place-bid u1 u75000) ;; Job 1, 75k bid
```

### Reputation

```clarity
;; Rate a completed job
(rate-freelancer 'ST1PQHQV0PMZ5P01A92F472ZRT4ZQ69GAQST90PTD u5) ;; 5 stars

;; Check reputation score
(reputation-score 'ST1PQHQV0PMZ5P01A92F472ZRT4ZQ69GAQST90PTD)
```

## Smart Contract Structure

### Data Maps

- `reputation`: Freelancer reputation scores
- `staked`: User staking balances
- `subscribers`: Platform subscribers
- `job-auctions`: Auction details per job
- `votes`: Voter tracking per job
- `jobs`: Complete job information

### Key Functions

**Public Functions:**
- `subscribe()` - Join the platform
- `stake()` - Deposit minimum stake
- `post-job(amount)` - Create new job listing
- `bid-job(job-id)` - Submit freelancer bid
- `deposit-escrow(job-id)` - Client funds escrow
- `submit-milestone(job-id)` - Freelancer progress
- `vote-approve(job-id)` - DAO vote for payment
- `rate-freelancer(user, score)` - Submit rating
- `create-job-auction(...)` - Launch auction
- `place-bid(job-id, amount)` - Submit bid

**Read-Only Functions:**
- `get-job(job-id)` - Retrieve job details
- `get-auction(job-id)` - Retrieve auction details
- `reputation-score(user)` - Get freelancer rating

## Security Considerations

- Smart contract escrow prevents fraud
- DAO voting ensures community consensus
- Staking requirement filters bad actors
- Reputation system incentivizes quality work
- Authorization checks on all sensitive operations

## Requirements

- Stacks blockchain testnet/mainnet
- Clarity smart contract support
- STX token balance for operations


**Status:** Active Development  
**Last Updated:** March 22, 2026
