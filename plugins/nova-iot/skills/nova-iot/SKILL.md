---
name: nova-iot
description: "IoT and embedded work done safely: microcontrollers (ESP32/ESP8266, Arduino, RP2040, STM32), Raspberry Pi, sensors and actuators, MQTT, Wi-Fi/BLE/LoRa, over-the-air (OTA) updates, serial debugging. Use when the user builds, wires, flashes or debugs a device, or asks about MQTT, OTA or GPIO. BM: 'projek IoT', 'ESP32', 'Arduino', 'Raspberry Pi', 'sensor', 'MQTT', 'flash firmware', 'OTA', 'GPIO'."
---

# nova-iot — hardware has no undo button

A code mistake costs a rebuild; a hardware mistake can cost a board, a battery fire or a chip that is
locked for good. Apply the three laws to devices:

1. **Never destroy** — back up a device's flash before writing to it. Never burn eFuses or enable secure
   boot / flash encryption without the user's explicit, informed go-ahead: both are one-way.
2. **Read before write** — identify the exact board, its logic voltage and pinout from the official
   datasheet before wiring or flashing. Never guess a pin, register or I2C address.
3. **Verify after change** — prove it on the real device (serial log, a message arriving on the broker,
   a reading that changes when the sensor changes), not "it compiled".

## 1. Identify before anything else
Find out (photo of the board, `lsusb`, the flashing tool's chip/flash ID command, or
`cat /proc/device-tree/model` on a Raspberry Pi):
- exact board and revision, the chip, flash size, logic voltage (3.3 V or 5 V), power source;
- every connected part (sensor, module, relay, motor driver) and its supply voltage.
Then open the official datasheet or pinout. If no official source can be found, say so instead of
inventing values.

## 2. Wiring checks — state them; the user does the wiring
- A 3.3 V input must not receive a 5 V signal: use a level shifter or divider. Share ground between parts.
- Do not power motors, relays, LED strips or servos from a GPIO pin or the board's regulator: separate
  supply sized for the load, a driver/transistor in between, a flyback diode on inductive loads.
- Mains voltage (e.g. 230 V AC): certified modules in an enclosure only, and recommend a qualified person.
  Never suggest working on live mains wiring.
- Lithium batteries: protected cells, the correct charger, and no unattended charging during first tests.

## 3. Build in the smallest steps
Blink or serial "hello" → read one sensor → publish one value → the next feature. Prove each step on the
device before the next, and commit each working step so there is always a good state to return to.

Use the toolchain the project already uses (PlatformIO, Arduino CLI, ESP-IDF, MicroPython, Pico SDK…).
Raspberry Pi 5: use gpiozero or libgpiod — the legacy RPi.GPIO library does not work on the Pi 5.

## 4. Back up before flashing
- ESP32/ESP8266: `esptool flash-id` shows the flash size; `esptool read-flash 0 ALL backup-<board>-<date>.bin`
  reads the whole flash (older `esptool.py` versions spell these `flash_id` / `read_flash` and need the
  size instead of `ALL` — check `--help` for the installed version).
- If secure boot or flash encryption is enabled, the dump is encrypted and normal flashing may be refused:
  stop and follow the vendor's documented update path instead of forcing a write.
- Other chips: use the vendor tool's read/backup function before any write.
- Raspberry Pi: image the SD card before a risky change.
Read twice and compare checksums (`shasum -a 256`): a loose cable gives a corrupt backup silently.

## 5. Connectivity and MQTT
- Broker: authentication on; TLS whenever traffic leaves the local network; never an anonymous broker
  reachable from the internet.
- Write down the topic plan (e.g. `site/device/metric`), choose QoS per message, use retained messages
  only for state, and a Last Will message for online/offline.
- Reconnect with back-off; never block the main loop waiting for the network.
- Wi-Fi passwords, broker credentials and API keys live in a separate, git-ignored config — never in a
  public repository or a screenshot.

## 6. Over-the-air updates
Only with a way back: two application slots (A/B) and a health check that marks a new image good only
after it boots and connects, otherwise roll back. Sign images where the platform supports it. Test the
rollback once on the bench before relying on it in the field.

## 7. Security baseline for any connected device
Change default passwords; close services that are not used (telnet, debug ports); keep firmware
updated; put IoT devices on their own network segment where possible.

## 8. Done = evidence
Show a table before saying done:

| Probe | Expected | Actual |
|---|---|---|
| Serial boot log | no reset loop, firmware version printed | |
| Sensor reading | changes when the input changes | |
| Broker | message arrives on the topic (`mosquitto_sub -t …`) | |
| Power cycle / Wi-Fi drop | reconnects without a manual reset | |
| OTA (if used) | update applies; a bad image rolls back | |

## Honest limits
You cannot see or touch the hardware. Wiring, heat, smells and voltages are checked by the user, with a
multimeter. Say clearly what you could not verify.
