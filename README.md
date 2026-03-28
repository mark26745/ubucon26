#  AeroNix ROS 2 Drone Workspace

A reproducible, containerized drone development environment built with **Nix Flakes**, **ROS 2 Humble**, and **PX4 SITL**. This repository provides everything you need to simulate, develop, and interact with a drone stack—from firmware to ROS 2 topics.

---

## Features

*  Fully reproducible dev environment via Nix
*  ROS 2 Humble preconfigured
*  PX4 SITL simulation support
*  Docker image for portable runtime
*  DDS bridge (PX4 ↔ ROS 2)
*  MAVLink proxy for external tools (e.g. QGroundControl)

---

##  Requirements

* Nix (with flakes enabled) - Optional
* Docker - Optional - Use this if not using Nix

---

## Getting Started

### 1. Enter Development Environment

```bash
nix develop
```

---

### 2. Build Docker Image

```bash
nix build .#demo-container
docker load -i result
docker run --rm -it -v ./:/app -w /app localhost/aeronix-drone-workspace:latest bash
```

---

## Workflow with Just

This project uses a `Justfile` to simplify complex multi-process workflows.

List all commands:

```bash
just --list
```

---

## Typical Simulation Workflow

Open **multiple terminals**:

### Terminal 1 — Start Simulation Stack

```bash
just sim
```

* Builds PX4 SITL
* Launches services via `hivemind`

---

### Terminal 2 — MAVLink Proxy

```bash
just proxy
```

* Routes MAVLink telemetry
* Enables connection to external tools (e.g. QGroundControl)

---

### Terminal 3 — DDS Agent

```bash
just sitl-dds-agent
```

* Bridges PX4 ↔ ROS 2 via Micro XRCE-DDS

---

### Terminal 4 — ROS 2 Sensor Stream

```bash
just ros2-subscribe-sensors
```

* Waits for PX4 topics
* Streams sensor data from:

```bash
/fmu/out/sensor_combined
```

---

## Available Commands

### Build PX4 SITL

```bash
just build-sitl
```

Builds firmware in `firmware/px4`.

---

### Run PX4 SITL

```bash
just sitl
```

Runs the SITL binary directly.

---

### Full Simulation

```bash
just sim
```

Runs orchestrated simulation via `hivemind`.

---

### MAVLink Proxy

```bash
just proxy
```

* Input: `udp:127.0.0.1:14550`
* Outputs:

  * `14551`
  * `14552`

Logs stored in:

```bash
./tlogs
```

---

### DDS Agent

```bash
just sitl-dds-agent
```

Runs:

```bash
MicroXRCEAgent udp4 -p 8888
```

---

### ROS 2 Sensor Subscriber

```bash
just ros2-subscribe-sensors
```

* Waits for PX4 to publish
* Subscribes automatically

---

Happy flying & hacking 🚀
