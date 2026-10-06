---
name: nova-plc-robotics
description: "PLC programming, industrial automation and robotics with safety first: IEC 61131-3 (ladder, structured text, function blocks, SFC), Modbus RTU/TCP, OPC UA, SCADA/HMI tags, ROS 2 and robot simulation. Use when the user writes or changes PLC logic, maps Modbus registers, connects to OPC UA, or programs or simulates a robot. BM: 'PLC', 'ladder', 'Modbus', 'SCADA', 'HMI', 'robot', 'ROS', 'automasi industri', 'mesin kilang'."
---

# nova-plc-robotics — machines can hurt people

A wrong line of PLC or robot code moves a real machine. Treat every change as safety-relevant until it is
shown not to be.

## Hard boundaries — never cross them, whatever is asked
- **Safety functions are out of scope for the agent**: emergency-stop circuits, safety PLC programs, light
  curtains, guard interlocks, safe torque off, anything rated under a functional-safety standard
  (e.g. ISO 13849, IEC 62061, IEC 61508). Do not write, change, bypass or "temporarily disable" them;
  refer the user to a qualified safety engineer. Never suggest jumpering or forcing a safety input.
- **No change to a running machine** without the site's procedure: machine stopped and isolated
  (lockout/tagout), an authorised person present, the current program backed up, a way back.
- **Forcing I/O or writing registers on a live system** is a production change: state the risk and leave
  the action to the responsible engineer.

## 1. Read before write
- Get the current program **from the PLC** (upload/online backup) and keep it with date and version
  before editing. Work on a copy.
- Identify the PLC make, model and firmware, the engineering software and its version, the I/O list, the
  tag/address map and the network (which device talks to which).
- Use the vendor's manual for instruction behaviour (timers, edge detection, scan order, retentive
  memory). Vendors differ; never assume another vendor's semantics.

## 2. Writing PLC logic (IEC 61131-3)
- Languages: Ladder Diagram (LD), Function Block Diagram (FBD), Structured Text (ST), Sequential Function
  Chart (SFC). Instruction List (IL) was deprecated in the 2013 edition and is no longer part of the language
  set in the 2025 edition — do not use it for new work.
- Prefer an explicit state machine (SFC, or CASE in ST) over scattered latches. Write each output in one
  place. Name tags by function and comment every rung/network with its intent.
- Think in scans: inputs are read, logic runs in order, outputs are written. Check edge detection, timer
  resets and power-up behaviour (initial values, retained memory).
- Simulate first — the vendor simulator or a soft PLC (e.g. CODESYS, OpenPLC) — with test cases for the
  normal sequence, every fault, power loss and restart.

## 3. Industrial protocols
- **Modbus RTU/TCP**: take function codes, register types and addressing from the device manual.
  "40001"-style numbers are 1-based labels while the protocol address is 0-based — off-by-one is the
  classic bug. Check byte/word order for 32-bit values. Classic Modbus RTU/TCP has no authentication or
  encryption: keep it on an isolated control network, and where devices support Modbus Security (TLS with
  certificates) consider it — never assume plain Modbus is protected.
- **OPC UA**: use a security mode with signing/encryption and certificates where the server supports it;
  browse the address space instead of guessing node IDs.
- **Networks**: separate control networks from office and internet traffic (zones and conduits, e.g.
  IEC 62443). No remote access to a PLC without a secure, approved path.

## 4. Robotics (ROS 2 and others)
- Check the currently supported ROS 2 distributions at https://docs.ros.org and prefer a long-term-support
  release for projects that must last.
- Simulation first, using the same launch files that will run on the robot. Name the ROS 2 distribution,
  the OS, the Gazebo release and the matching `ros_gz` bridge; do not start new work on Gazebo Classic,
  which reached end of life in January 2025.
- Speed and force limits; a hardware emergency stop that does not depend on software; a clear workspace.
  First motion on real hardware at reduced speed, with a person ready at the stop.
- Never disable collision or limit checks to "make it move".

## 5. Commissioning evidence — before saying done

| Test | Expected | Actual | Witnessed by |
|---|---|---|---|
| Program backup taken from the PLC | file + date | | |
| Simulation: normal sequence | as specified | | |
| Simulation: every fault / stop path | unchanged behaviour | | |
| I/O check on site (machine isolated) | each point correct | | engineer |
| First run at reduced speed | as specified | | engineer |

Site tests are carried out and signed by the responsible engineer. The agent prepares the plan; it does
not replace commissioning.

## Honest limits
You cannot see the machine or the plant. Anything that moves, heats or holds pressure is verified on site
by a qualified person.
