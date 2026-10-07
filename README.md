# UART + FIFO

A synthesizable UART + FIFO digital IP core developed in Verilog RTL, with the goal of taking the design through a complete ASIC physical-design flow using OpenROAD.

## Overview

This project implements a UART communication interface with independent transmit and receive FIFOs.

The design provides:

- 8-bit UART transmit path
- 8-bit UART receive path
- TX FIFO buffering
- RX FIFO buffering
- Configurable baud-rate generation
- FIFO full/empty status signals
- Loopback-capable simulation testbench

## Architecture

```text
                    ┌─────────────────┐
                    │ Baud Generator  │
                    └────────┬────────┘
                             │ baud_tick
                             │
       TX                    │                    RX
       │                     │                     │
       ▼                     │                     ▼
┌─────────────┐              │              ┌─────────────┐
│   TX FIFO   │              │              │ UART RX     │
└──────┬──────┘              │              └──────┬──────┘
       │                     │                     │
       ▼                     │                     ▼
┌─────────────┐              │              ┌─────────────┐
│   UART TX   │              │              │   RX FIFO   │
└──────┬──────┘              │              └──────┬──────┘
       │                     │                     │
       ▼                     │                     ▼
    uart_tx                 clk                 rx_data
