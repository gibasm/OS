# My own OS & bootloader

This is a personal project, I'm just playing with bootloader & OS development (:


Supported architectures as of right now: x86\_64 (aka AMD64)


Support planned also for RV32i (RISC-V)

## Requirements:

### General:

- GNU core utils,

- GNU Make,

- bash,

- qemu-system-(...),

### x86\_64:

- NASM (Netwide Assembler for x86\_64)

## Building and running with a qemu vm

### x86\_64:

```bash
make x86_64 -j`nproc`
./qemu_run_x86_64.sh
```
