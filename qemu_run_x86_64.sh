#!/bin/bash

QEMU_ADDITIONAL_OPTIONS=-d int,cpu_reset,guest_errors

qemu-system-x86_64 -device VGA,vgamem_mb=256 -hda boot/x86_64/img.bin -no-reboot -no-shutdown $@
