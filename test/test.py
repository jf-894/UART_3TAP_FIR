# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

# Replaces your Verilog UART_OUT task
async def uart_tx(dut, data):
    # Start bit (0)
    dut.ui_in.value = 0
    await Timer(104167, units='ns')
    
    # Send 8 data bits (LSB first)
    for i in range(8):
        bit_val = (data >> i) & 1
        dut.ui_in.value = bit_val
        await Timer(104167, units='ns')
        
    # Stop bit (1)
    dut.ui_in.value = 1
    await Timer(104167, units='ns')
    
    # Delay between data bytes (500us)
    await Timer(500000, units='ns')

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start Simulation")

    # Replaces your Verilog 'always #7.575 clk = ~clk;'
    # 15.15ns period = ~66 MHz clock
    clock = Clock(dut.clk, 15.15, units="ns")
    cocotb.start_soon(clock.start())

    # Initial values
    dut.ena.value = 1
    dut.ui_in.value = 1  # UART Idle is high (8'b0000_0001)
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    # Reset (wait a bit, then pull high)
    dut._log.info("Applying Reset")
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    
    # Replaces your Verilog '#10000;'
    await Timer(10000, units='ns')

    # Send Samples
    dut._log.info("Sending Samples...")
    await uart_tx(dut, 1)
    await uart_tx(dut, 1)
    await uart_tx(dut, 1)

    # Send Coefficients
    dut._log.info("Sending Coefficients...")
    await uart_tx(dut, 1)
    await uart_tx(dut, 1)
    await uart_tx(dut, 1)

    # Replaces your Verilog '#15_000_000;'
    dut._log.info("Waiting for processing...")
    await Timer(15_000_000, units='ns')

    assert dut.uo_out[0].value == 3
