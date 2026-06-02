# SPI Slave with Single-Port RAM

An RTL implementation of an **SPI Slave** interfaced with a **256×8 single-port RAM**, supporting four memory operations over a standard 4-wire SPI bus. The project includes a main design, an alternative FSM implementation, a wrapper testbench, and FPGA constraints for the Digilent Basys3.

---

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [SPI Protocol & Frame Format](#spi-protocol--frame-format)
- [Module Descriptions](#module-descriptions)
  - [SPI Slave](#spi-slave)
  - [RAM](#ram)
  - [SPI Wrapper](#spi-wrapper)
- [Design Variants](#design-variants)
- [Simulation](#simulation)
- [FPGA Implementation](#fpga-implementation)

---

## Overview

The system receives 10-bit serial frames via MOSI and executes one of four RAM operations based on the 2-bit command field. Read data is shifted back serially on MISO.

```
Master ──MOSI──► SPI Slave ──rx_data[9:0]──► RAM ──dout[7:0]──► SPI Slave ──MISO──► Master
        ◄─MISO──            ◄──tx_data/tx_valid──              
         SS_n ──►
```

**Key specs:**

- SPI Mode 0 (CPOL=0, CPHA=0), MSB-first
- 10-bit frame: 2-bit command + 8-bit payload
- 256-entry × 8-bit synchronous RAM
- Active-low reset (`rst_n`)
- FPGA target: Digilent Basys3 (Artix-7)

---

## Project Structure

```
SPI-Slave-with-Single-Port-RAM/
│
├── Main Design/
│   ├── SPI_Slave.V          # SPI Slave FSM (right-shift, counter-based)
│   ├── RAM.V                # 256×8 synchronous single-port RAM
│   ├── SPI_Wrapper.V        # Structural top-level integrating SPI + RAM
│   ├── Wrapper_tb.v         # Testbench: write addr, write data, read addr, read data
│   ├── mem.dat              # Binary memory initialization file ($readmemb)
│   ├── run.do               # ModelSim compile and run script
│   └── Constraints_SPI.xdc  # Vivado pin constraints for Basys3
│
├── Alternative Design/
│   ├── SPI_Slave.V          # Alternative SPI Slave FSM (left-shift, separate rd_addr)
│   ├── RAM.V                # Alternative RAM with separate wr_addr and rd_addr registers
│   ├── SPI_Wrapper.V        # Same structural wrapper
│   └── Wrapper_tb.V         # Same testbench sequence
│
└── Report/
    └── Code_Red_Project2.pdf   # Full project report
```

---

## SPI Protocol & Frame Format

Each transaction is one 10-bit frame, transmitted MSB-first while `SS_n` is low:

```
 Bit 9   Bit 8  │  Bits [7:0]
─────────────────┼──────────────
  CMD[1]  CMD[0] │  Payload
```

| CMD[9:8] | Operation       | Payload             |
|----------|-----------------|---------------------|
| `00`     | Write Address   | 8-bit write address  |
| `01`     | Write Data      | 8-bit data to store  |
| `10`     | Read Address    | 8-bit read address   |
| `11`     | Read Data       | Triggers MISO output |

**Transaction flow:**
1. Assert `SS_n` low
2. Send 1-bit command prefix on MOSI (`0` = write, `1` = read/read-data)
3. FSM transitions to the appropriate state
4. Shift 10 bits total; FSM asserts `rx_valid` when the frame is complete
5. RAM decodes `rx_data[9:8]` and executes the operation
6. For Read Data: RAM asserts `tx_valid` and drives `dout`; SPI Slave shifts `dout` out on MISO

---

## Module Descriptions

### SPI Slave

**File:** `Main Design/SPI_Slave.V`

A 5-state Mealy/Moore FSM implementing the SPI receive and transmit logic.

```
IDLE → CHK_CMD → WRITE
                → READ_ADD → READ_DATA
```

| State       | Description                                                             |
|-------------|-------------------------------------------------------------------------|
| `IDLE`      | Waits for `SS_n` to go low                                              |
| `CHK_CMD`   | Samples the first MOSI bit to determine direction (0=write, 1=read)     |
| `WRITE`     | Shifts in 10 bits MSB-first; asserts `rx_valid` after 10 clock cycles   |
| `READ_ADD`  | Shifts in 10-bit read address; sets `ADD_READ` flag when complete       |
| `READ_DATA` | If `tx_valid=0`: shifts in 10-bit read command. If `tx_valid=1`: shifts `tx_data` out on MISO, MSB-first |

**Ports:**

| Port       | Dir    | Width | Description                          |
|------------|--------|-------|--------------------------------------|
| `clk`      | input  | 1     | System clock                         |
| `rst_n`    | input  | 1     | Active-low asynchronous reset        |
| `SS_n`     | input  | 1     | Slave select (active low)            |
| `MOSI`     | input  | 1     | Master-out slave-in serial data      |
| `tx_valid` | input  | 1     | RAM has valid data to send           |
| `tx_data`  | input  | 8     | Data byte from RAM to serialize      |
| `rx_data`  | output | 10    | Received 10-bit frame                |
| `rx_valid` | output | 1     | Pulses high for one cycle when frame is complete |
| `MISO`     | output | 1     | Master-in slave-out serial data      |

---

### RAM

**File:** `Main Design/RAM.V`

A parameterized synchronous 256×8 single-port RAM with command-decoded operation.

**Parameters:**

| Parameter    | Default | Description              |
|--------------|---------|--------------------------|
| `MEM_DEPTH`  | 256     | Number of memory entries |
| `ADDR_SIZE`  | 8       | Address and data width   |

**Operation (decoded from `din[9:8]` when `rx_valid` is high):**

| `din[9:8]` | Action                                    |
|------------|-------------------------------------------|
| `2'b00`    | Latch `din[7:0]` as write address         |
| `2'b01`    | Write `din[7:0]` to `mem[addr_wr]`        |
| `2'b10`    | Latch `din[7:0]` as (read) address        |
| `2'b11`    | Drive `mem[addr_wr]` on `dout`; assert `tx_valid` |

**Ports:**

| Port       | Dir    | Width | Description                       |
|------------|--------|-------|-----------------------------------|
| `clk`      | input  | 1     | System clock                      |
| `rst_n`    | input  | 1     | Active-low reset                  |
| `rx_valid` | input  | 1     | Strobe: decode and execute `din`  |
| `din`      | input  | 10    | Command + data from SPI Slave     |
| `dout`     | output | 8     | Read data to SPI Slave            |
| `tx_valid` | output | 1     | Asserted when `dout` is valid     |

---

### SPI Wrapper

**File:** `Main Design/SPI_Wrapper.V`

Structural top-level connecting `SPI_Slave` and `RAM`. Exposes only the raw SPI interface externally.

**Ports:**

| Port    | Dir    | Description              |
|---------|--------|--------------------------|
| `clk`   | input  | System clock             |
| `rst_n` | input  | Active-low reset         |
| `SS_n`  | input  | SPI slave select         |
| `MOSI`  | input  | SPI data in              |
| `MISO`  | output | SPI data out             |

---

## Design Variants

The project contains two independent implementations of the SPI Slave:

| Feature                  | Main Design                        | Alternative Design                    |
|--------------------------|------------------------------------|---------------------------------------|
| Shift direction          | Right-shift into `rx_temp[9:1]`    | Left-shift into `rx_shift_temp`       |
| Counter style            | Single 4-bit counter, resets at 9  | Counter runs to 11 (extra copy cycle) |
| Read address register    | Shared `addr_wr` in RAM            | Separate `wr_addr` and `rd_addr` in RAM |
| `tx_valid` de-assertion  | Not de-asserted between frames     | Explicitly cleared on non-`11` commands |
| Read flag name           | `ADD_READ`                         | `read_flag`                           |

Both variants use the same 5-state FSM structure and share the same wrapper and testbench.

---

## Simulation

### Requirements

- ModelSim / QuestaSim

### Running the Testbench

```tcl
cd "Main Design/"
vsim -do run.do
```

The testbench (`Wrapper_tb.v`) pre-loads `mem.dat` into the RAM using `$readmemb`, then executes the following sequence:

| Step        | Frame (bin)    | Description                        |
|-------------|----------------|------------------------------------|
| Reset       | —              | 5 cycles with `rst_n=0`            |
| Write Addr  | `00_00000101`  | Set write address to 5             |
| Write Data  | `01_00000111`  | Write `0x07` to address 5         |
| Read Addr   | `10_00000011`  | Set read address to 3              |
| Read Data   | `11_00001000`  | Read from address 8; data appears on MISO |

Each frame is sent by toggling `SS_n` low, asserting the command bit on MOSI, then shifting 10 bits on the falling edge of the clock.

---

## FPGA Implementation

**Target:** Digilent Basys3 — Xilinx Artix-7 XC7A35T  
**Tool:** Vivado

### Pin Assignments (`Constraints_SPI.xdc`)

| Signal  | FPGA Pin | Standard   | I/O       |
|---------|----------|------------|-----------|
| `clk`   | W5       | LVCMOS33   | Clock (100 MHz onboard) |
| `rst_n` | V17      | LVCMOS33   | Switch SW0 |
| `SS_n`  | V16      | LVCMOS33   | Switch SW1 |
| `MOSI`  | W16      | LVCMOS33   | Switch SW2 |
| `MISO`  | U16      | LVCMOS33   | LED LD0   |
