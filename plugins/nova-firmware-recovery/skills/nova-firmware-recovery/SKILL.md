---
name: nova-firmware-recovery
description: "Recovering and updating firmware on devices the user owns — CCTV cameras and NVR/DVR recorders, routers, IoT boxes — including discontinued models: identify the hardware, back up the original flash first, recover through vendor tools, UART/U-Boot/TFTP or an SPI programmer, then secure the device. Use when a device is bricked or stuck in a boot loop, needs a firmware upgrade or downgrade, or is out of vendor support. BM: 'firmware', 'CCTV rosak', 'brick', 'DVR', 'NVR', 'flash semula', 'naik taraf firmware', 'model discontinue'."
---

# nova-firmware-recovery — the original flash is the only undo

## Boundaries
- Only devices the user owns or is authorised to repair. Do not help bypass anti-theft locks, cloud-account
  locks or passwords on a device the user does not own.
- Vendor firmware is copyrighted: use files from the vendor or files the user lawfully has; do not
  redistribute them.
- Opening a device can void its warranty, and recorders contain mains power supplies: unplug before
  opening; never probe a powered mains board.

## 1. Identify exactly (read before write)
- Model, hardware revision, region/variant (label, web UI "device info", boot log) and current firmware.
- Inside: the SoC (common camera families include HiSilicon, Goke, SigmaStar, Ingenic and Fullhan), the
  flash chip marking and size, the image sensor, and the UART pads (often a labelled 3–4 pin header).
- Firmware for a different hardware revision or region is the most common cause of a permanent brick.
- The security state: secure boot, signed firmware, anti-rollback, flash encryption (eFuses). These change
  which recovery paths exist at all. If the state is unknown, find out before any write.

## 2. Back up the original flash FIRST — never skip
Choose the least invasive way that works:
- the vendor's backup/export, if the device still boots;
- the U-Boot console over UART: read the flash into RAM and send it to a TFTP server, or dump it over
  the serial line;
- an SPI programmer on the flash chip (e.g. a CH341A with a clip and `flashrom`), device unpowered. Check
  the chip's voltage first: some flash chips are 1.8 V and need an adapter.
Read twice, compare checksums, and store the image with model, revision and date. No backup = no write.
The dump contains sectors unique to THIS unit — MAC address, serial number, calibration data, keys, the
bootloader environment. They must survive any recovery.

## 3. Recovery paths — least to most invasive
Before any write: know the security state and the partition map (from the vendor documentation, the boot
log, `printenv` or the vendor image — never a guess), validate the image's hash or
signature, use the vendor's load address and erase/write method, and read back to verify after writing.
If the security state or the layout is unknown, stop and obtain the vendor documentation.
1. **Vendor recovery**: the official upgrade file for the exact model, revision and region, via the web
   UI, an SD card or the vendor's recovery tool.
2. **UART + U-Boot**: interrupt the boot, load the correct image over TFTP and write it to the right
   partition. Take the partition layout from the boot log, `printenv` or the vendor image — never guess
   offsets.
3. **SPI programmer**: write back this unit's own backup, or only the documented firmware partitions while
   keeping this unit's unique sectors. Never clone a whole-flash dump from another unit — it carries that
   unit's MAC, serial, calibration and keys.
4. **Community firmware** for out-of-support cameras (e.g. OpenIPC): only when the project's current
   compatibility list marks the exact SoC and board as installable — a listed SoC alone is not proof — and
   follow the guide for that board (load address, flash layout, sensor, recovery route).
UART logic level is board-specific (often 3.3 V, sometimes 1.8 V): check the SoC/board documentation or
measure an active TX line with suitable equipment, use a level shifter when needed, and connect GND, TX and
RX only — never the adapter's VCC.

## 4. After recovery: secure it
- Change every default password. Install only the newest vendor-approved firmware for the exact model,
  hardware revision, region and boot-security state — keep the validated backup and recovery route first.
  Never downgrade or cross-flash to get around signatures, anti-rollback, cloud or account controls.
- Discontinued devices get no more security fixes: keep them off the internet (no port forwarding, no
  cloud/P2P), on their own VLAN, reachable only through the recorder or a VPN.
- Turn off services that are not needed (telnet, P2P, UPnP).

## 5. Done = evidence

| Probe | Expected | Actual |
|---|---|---|
| Original flash backup | two identical reads, checksum recorded | |
| Boot log (UART) | boots to the application, no loop | |
| Network | reachable at the expected address | |
| Video stream | RTSP/ONVIF stream plays (`ffprobe rtsp://…`) | |
| Security | default passwords changed, not reachable from the internet | |

## Honest limits
Some devices have locked bootloaders or signed firmware that cannot be recovered without the vendor. Say
so instead of attempting a risky write.
