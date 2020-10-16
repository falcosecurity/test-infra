# Poiana Migration

## Terms & Definitions

[Poiana] Name of the github bot (2nd github account)
[Tide] Name of the auto merging system in prow

## Motivation

We need to move Poiana to the new prow cluster on EKS, and come up with a plan to move it once new infrastructure is created. 

## Goals

- Move Poiana to prow cluster on EKS
- Achieve minimal downtime on Poiana
- Have clear success criteria
- Have rollback plan in case migration doesn't work

## Non-Goals

- CICD for prow on EKS
- Build jobs on Prow for EKS

## Proposal

It appears through initial testing that it's possible to have multiple prow microservices up using the same github credentials. 

1. The plan would be to spin up the EKS cluster in a seperate PR, and ensure kubectl access before the migration occurs. 
2. Next create the required configmaps for prow by pulling from 1Password.
3. Spin up the required Prow microserves in parallel to existing services.
4. Confirm functionality of new services
5. Scale down existing prow deployments deployed on Packet.io
6. Confirm switch over occured correctly, by sending PR's on multipe repositories Poiana is watching over.
7. Spin down old prow infrastructure on Packet.io

### Prerequisites

- Terraform CirlCI scripts in place
- 1Password CICD scripts in place
- Test prow on EKS with github tokens from 1password to ensure no errors
- Inform community about planned downtime
