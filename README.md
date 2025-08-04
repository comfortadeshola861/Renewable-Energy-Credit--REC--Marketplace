# Renewable Energy Credit (REC) Marketplace

A comprehensive smart contract system for managing renewable energy credits on the Stacks blockchain. This marketplace enables the verification, issuance, trading, retirement, and regulatory compliance of RECs.

## System Overview

The REC Marketplace consists of five interconnected smart contracts:

### 1. Energy Generation Verification Contract (`energy-verification.clar`)
- Validates renewable energy production from solar, wind, and hydro facilities
- Records energy generation data with timestamps and facility information
- Implements verification mechanisms to ensure data integrity
- Supports multiple renewable energy source types

### 2. REC Issuance Contract (`rec-issuance.clar`)
- Creates digital RECs based on verified renewable energy generation
- Issues unique REC tokens with metadata including energy source, amount, and generation date
- Maintains REC ownership records
- Implements minting controls and validation

### 3. REC Trading Platform Contract (`rec-trading.clar`)
- Facilitates buying and selling of RECs between energy producers and consumers
- Manages order books with bid/ask functionality
- Handles REC transfers and payment processing
- Implements price discovery mechanisms

### 4. REC Retirement Tracking Contract (`rec-retirement.clar`)
- Records the permanent retirement of RECs for carbon offset purposes
- Tracks retirement reasons and associated carbon reduction claims
- Maintains immutable retirement records
- Prevents double-counting of retired RECs

### 5. Regulatory Compliance Contract (`regulatory-compliance.clar`)
- Ensures REC trading adheres to government regulations
- Implements compliance checks and validation rules
- Maintains regulatory reporting capabilities
- Supports audit trails and transparency requirements

## Key Features

- **Decentralized Verification**: Transparent and immutable energy generation records
- **Automated Issuance**: Streamlined REC creation process
- **Efficient Trading**: Market-based price discovery and automated matching
- **Permanent Retirement**: Immutable records preventing double-counting
- **Regulatory Compliance**: Built-in compliance checks and reporting

## Data Types

### Energy Generation Record
- Facility ID
- Energy source type (solar, wind, hydro)
- Generation amount (MWh)
- Generation timestamp
- Verification status

### REC Token
- Unique REC ID
- Energy source
- Generation amount
- Issuance date
- Current owner
- Status (active, retired)

### Trading Order
- Order ID
- REC ID
- Order type (buy/sell)
- Price
- Quantity
- Order status

## Getting Started

1. Deploy contracts in the following order:
    - energy-verification.clar
    - rec-issuance.clar
    - rec-trading.clar
    - rec-retirement.clar
    - regulatory-compliance.clar

2. Initialize regulatory parameters
3. Register energy facilities
4. Begin energy generation verification and REC issuance

## Testing

Run the test suite using:
\`\`\`bash
npm test
\`\`\`

## Compliance

This system is designed to support various regulatory frameworks including:
- Renewable Portfolio Standards (RPS)
- Voluntary carbon markets
- Corporate sustainability reporting
- Government renewable energy targets
