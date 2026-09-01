# Multilayer MAS-AIoT Water Quality Monitoring: CupCarbon P2P Simulation

Official repository for the simulation and experimental evaluation of a Peer-to-Peer (P2P) Multi-Agent System (MAS) for end-user domestic water quality monitoring in Mexico, built entirely within the **CupCarbon** simulation environment.

---

## Project Overview

This simulation models distributed consensus and communication latency among AIoT sensor agents. Using **SenScript**, edge sensor nodes perform local anomaly detection and initiate cross-validation requests (`100`) while neighbor nodes evaluate local states to return acknowledgments (`101 ACK`).

---

## Empirical Findings & Scalability Bottlenecks

Trace logs processed from CupCarbon simulations (focusing on dense deployments from nodes S52 to S114) highlighted critical constraints in flat P2P topologies:

* **Timer Desynchronization (Race Condition):** Senders enforce a static waiting window of 300 ms (`ALERTA_RECHAZADA_AISLAMIENTO`). Under high traffic load, actual neighbor processing delays average ~1168.1 ms, triggering false isolation alerts.
* **Orphaned Packet Corruption:** Delayed ACK payloads (`101`) arrive after the sender reverts to `MONITOREO_NORMAL`, leading to invalid state transitions in the node's local Finite State Machine (FSM).
* **Medium Contention:** Channel contention and stochastic delays (`RANDB`) in the simulated wireless environment demonstrate that flat P2P consensus requires adaptive timing before scaling to larger urban municipal networks.

---

## 📁 Repository Structure

```text
.
├── config/                 # CupCarbon configuration settings
├── gps/                    # Spatial node coordinates and GPS mapping
├── logs/                   # Simulation execution traces and console output
├── natevents/              # Environmental event injection scenarios
├── network/                # CupCarbon network topology files (.net)
├── results/                # Raw simulation metric outputs and performance data
├── scripts/                # SenScript behavioral routines for sensor agents
├── tmp/                    # Temporary simulation runtime cache
├── xbee/                   # XBee communication layer configurations
├── LoRaP2PSimulation.cup   # Main CupCarbon project file
└── README.md               # Repository documentation

```
## Execution Guide
### Prerequisites
- CupCarbon Simulator: Version 5.2 or higher (Java JRE 11+ required).
- Python 3.10+: Recommended for parsing trace logs generated in /logs or /results.
## Steps
- Clone this repository
- Launch CupCarbon, navigate to File > Open Project, and select LoRaP2PSimulation.cup.
- Verify that topology configurations in /network correctly reference the SenScript routines stored in /scripts.
- Run the simulation. Execution logs will automatically populate in /logs and numerical results in /results.
