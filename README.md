# UART + FIFO ASIC IP

UART + FIFO digital IP core developed in Verilog RTL.

## RTL hierarchy

uart_fifo_top
├── baud_generator
├── TX FIFO
│   └── fifo
├── uart_tx
├── uart_rx
└── RX FIFO
    └── fifo

## Repository structure

- `rtl/` — synthesizable Verilog RTL
- `sim/` — simulation/testbench files
- `openroad/` — ASIC physical-design flow

## Target flow

RTL → Synthesis → Floorplanning → Power Planning → Placement → CTS → Routing → STA → DRC/LVS → GDS
