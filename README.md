# Distributed Proof of Work Consensus Algorithm using CUDA
## Introduction

Blockchain technology is widely known for its decentralized ledger system used in cryptocurrencies like Bitcoin. It relies on a consensus mechanism to agree on the state of the blockchain. One of the consensus algorithms is Proof of Work (PoW), which is used to secure and validate transactions in a blockchain network.
## Key Concepts
  - Decentralization:  Data is managed by a distributed network of nodes without a central authority.
 - Immutability:  Once data is recorded in the blockchain, it cannot be modified or deleted.
 - Transparency:  Transactions are public and can be verified by anyone.
 - Security:  Cryptographic algorithms ensure the security and integrity of the blockchain data.

# Objectives
-  Understand Blockchain Basics: Learn the fundamentals of blockchain technology.
 - Understand Proof of Work Algorithm: Learn how the PoW consensus mechanism works.
 - Participate in Consensus: Implement the PoW algorithm from the perspective of a blockchain node.
  - Program on GPU using CUDA: Leverage CUDA for efficient parallel computation.

## Proof of Work Algorithm

In the PoW consensus mechanism, miners (nodes) compete to solve a complex mathematical problem. The first miner to solve the problem broadcasts the solution to the network. The solution is then verified by other nodes. The problem is designed such that:

  - Hard to Solve: It requires significant computational effort to find a valid solution.
  - Easy to Verify: The solution can be quickly verified by other nodes.

The miner who solves the problem first is rewarded. In this implementation, you will use CUDA to accelerate the computation of PoW.
## Block Structure

### A block consists of:

- Previous Block Hash: A predefined value linking to the previous block.
 - Root Hash of Transactions: A calculated value representing the transactions in the block.
- Nonce: A 32-bit random integer that miners try to find such that the resulting hash of the block is below a specified difficulty threshold.

The resulting hash must start with a number of zero bits (depending on the difficulty level).

## Problem Solving

The problem is to find a nonce such that the hash of the block, when calculated using a hash function like SHA-256, starts with a specified number of zero bits. For example:
 - Difficulty = 1: The hash must start with at least 1 zero bit (e.g., 09b044fe...).
- Difficulty = 3: The hash must start with at least 3 zero bits (e.g., 000...).
