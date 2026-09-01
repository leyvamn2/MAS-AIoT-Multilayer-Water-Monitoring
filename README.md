# Multilayer MAS-AIoT Water Quality Monitoring System

An event-driven, edge-intelligent Multi-Agent System (MAS) combined with the Artificial Intelligence of Things (AIoT) designed for real-time water quality monitoring at domestic consumption points.

## **Overview**
Water quality in municipal supply networks often suffers from localized degradation, supply intermittency (e.g., storage tanks and cisterns), and transient contamination events. This project introduces a **multilayer AIoT architecture** utilizing decentralized **Multi-Agent Systems (MAS)** to shift computing to the Edge.

By executing local anomaly detection and event-triggered inter-agent validation, the system minimizes radio transmissions, conserves node energy, and prevents network saturation while maintaining high temporal resolution during contamination events.

---

## **Key Features**
* **Edge-First Intelligence:** Local sensor data processing and threshold validation on microcontroller units to minimize cloud dependency.
* **Event-Driven MAS Communication:** Inter-agent radio communication (`MSG_REQ` / consensus validation) is triggered strictly upon local anomaly detection.
* **Adaptive Dynamic Sampling:** Duty-cycling mechanism adjusting sampling frequencies from a low-power baseline (3–5 min) to real-time during flow events or detected spikes.
* **Decentralized Consensus:** Neighboring nodes collaborate via peer-to-peer consensus to isolate false positives caused by local sensor drift vs. genuine contamination.
* **Bandwidth & Power Optimization:** Reduces telemetry traffic to low-frequency heartbeat reports (~30 min) during steady-state conditions.

---
