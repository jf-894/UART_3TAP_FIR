# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, Edge

# Manual UART TX function for 9600 baud
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

# Manual UART RX function for 9600 baud
async def uart_rx(dut):
    # 1. Wait for the start bit (bit 0 drops from 1 to 0)
    while True:
        await Edge(dut.uo_out)
        if dut.uo_out.value.binstr[-1] == '0':
            break
            
    # 2. Wait half a bit period to sample in the middle of the start bit
    await Timer(52083, units='ns')
    
    received_byte = 0
    
    # 3. Sample the 8 data bits (LSB first)
    for i in range(8):
        # Wait a full bit period (1 / 9600 sec)
        await Timer(104167, units='ns')
        
        # Read the current bit value of uo_out[0] (the last character in the binstr)
        bit_val = int(dut.uo_out.value.binstr[-1])
        received_byte |= (bit_val << i)
        
    # 4. Wait a full bit period to reach the center of the stop bit
    await Timer(104167, units='ns')
    
    return received_byte

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start Simulation")

    # 15.15ns period = ~66 MHz clock
    clock = Clock(dut.clk, 15.15, units="ns")
    cocotb.start_soon(clock.start())

    # Initial values
    dut.ena.value = 1
    dut.ui_in.value = 1  # UART Idle is high
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    # Reset
    dut._log.info("Applying Reset")
    await Timer(100, units='ns')
    dut.rst_n.value = 1
    
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

    # Wait for the hardware to process and intercept the serial output
    dut._log.info("Waiting for processing and receiving UART output...")
    result = await uart_rx(dut) 
    
    dut._log.info(f"Received FIR calculation result: {result}")
    
    # Assert the reconstructed parallel integer
    assert result == 3, f"FIR calculation failed. Expected 3, got {result}"
