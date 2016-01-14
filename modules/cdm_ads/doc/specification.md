# Introduction

This document specifies the implementation of the core debug module
for cores with an advanced debug system interface. It uses the [MMIO
Bridge] module for integration in the Open SoC Debug Interconnect
Infrastructure.

## License

This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License. To view a copy of
this license, visit
[http://creativecommons.org/licenses/by-sa/4.0/](http://creativecommons.org/licenses/by-sa/4.0/)
or send a letter to Creative Commons, PO Box 1866, Mountain View, CA
94042, USA.

You are free to share and adapt this work for any purpose as long as
you follow the following terms: (i) Attribution: You must give
appropriate credit and indicate if changes were made, (ii) ShareAlike:
If you modify or derive from this work, you must distribute it under
the same license as the original.

## Authors

Stefan Wallentowitz

Andreas Traber

Fill in your name here!

# Core Interface

The core is connected as a slave on this interface:

 Signal       | Driver | Width        | Description
 ------       | ------ | -----        | -----------
 `stall`      | Module | 1            | Stall the core
 `breakpoint` | Core   | 1            | Indicates breakpoint
 `strobe`     | Module | 1            | Access to the core debug interface
 `ack`        | Core   | 1            | Complete access to the core
 `adr`        | Module | ?            | Address of CPU register to access
 `write`      | Module | 1            | Write access
 `data_in`    | Module | `DATA_WIDTH` | Write data
 `data_out`   | Core   | `DATA_WIDTH` | Read data

# Memory Map


The memory map uses a 16 bit wide address space, roughly divided into 4 bits
for the group and 12 bits for the address inside a group, which results in 16
groups.

 Address Range       | Group | Description
 -------------       | ----- | -----
 `0x0000` - `0x0fff` | GPR   | General-Purpose Register, Floating Point Registers, ...
 `0x1000` - `0x1fff` | CSR   | Control and Status Registers
 `0x2000` - `0x2fff` | DBG   | Debug Registers (Debug Mode, Program Counters, ...)
 `0x3000` - `0x3fff` |       | Reserved for Custom Extensions/Co-Processors
 `0x4000` - `0x41ff` | MMIO  | Control and Status
 `0x4200`            | MMIO  | Interrupt Cause
 `0x4201` - `0x42ff` | MMIO  | Reserved
 `0x4300` - `0xffff` | MMIO  | Slave module address space

## Group "GPR"

The GPR group contains the general-purpose register file and the floating point
register file.

They are mapped as follows:

 Address Range       | Key     | Description
 -------------       | ---     | -----
 `0x0000` - `0x001f` | x0-x31  | General-Purpose Registers
 `0x0020`            | pc      | (Next) Program Counter
 `0x0021`            | ppc     | (Previous) Program Counter
 `0x0100` - `0x001f` | f0-f31  | Floating-Point Registers
 `0x0120`            | fcsr    | Floating-Point Control and Status Register

Address `0x0000 (register x0) is read-only and hard-wired to 0.

It is assumed that the core is halted when a register is read. `pc` then
contains the program counter of the next instruction that will be executed by
the core when it continues operation.
`ppc` contains the program counter of the previously executed instruction which
is important for software breakpoints.

If a register is not present, the MMIO interface returns 0.

## Group "CSR"

The CSR group is directly mapped to the control and status registers specified
in the RISC-V privileged specification.

## Group "DBG"

The DBG group contains registers related to the interaction with a connected
debugger.

Specifically it contains the following registers

 Address Range       | Key     | Description
 -------------       | ---     | -----
 `0x2000`            | DMR     | Debug Mode Register
 `0x2001`            | DSR     | Debug Stop Register
 `0x2002`            | DCR     | Debug Cause Register

The debug mode register controls single-stepping mode, trap on branches and so on

The debug stop register controls trap behaviour when encountering interrupts.

The debug cause register contains information why the core has trapped to the debugger.

TODO: describe those registers in more detail with individual bits

## Control and Status

The slave module must handle the following control and status requests
properly, that are elaborated in the following:

 Address | Key | Description
 ------- | --- | -----------
 `0x0200` | `MMI_IRQ_CAUSE` | Interrupt Cause

### Interrupt Cause

On occurence of an interrupt, a trace event is generated and sent to
the host or configured destination. The value of the trace event is
determined by reading from this 16 bit register and the host or
destination module can take appropriate action.

Depending on the size signaled by the interrupt signal (see above)
`irq` count words are read from the address (same-address burst).


