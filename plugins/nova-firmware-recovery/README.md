# ALESA NOVA Firmware Recovery

Recover and update firmware on devices you own — CCTV cameras, recorders, routers, discontinued models: identify the hardware, back up the original flash first, recover through vendor tools, UART/U-Boot/TFTP or an SPI programmer, then secure the device.

The skill (`nova-firmware-recovery`) loads automatically when the task matches; its first rule is the pack's motto: *the original flash is the only undo*.
It follows ALESA NOVA's three laws — never destroy, read before write, verify after change — and ends every task with an evidence table instead of a bare "done".

**Honest limits:** the agent cannot see or touch hardware; anything involving mains power, moving machinery or safety functions is checked by a qualified person.

Part of ALESA NOVA by Novastack System Sdn. Bhd. — see LICENSE.txt.
