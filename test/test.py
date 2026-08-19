# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, Edge

# Manual UART TX function for physical 9600 baud rate
async def uart_tx(dut, data):
    # Start bit (0)
    dut.ui_in.value = 0
    await Timer(104167, unit='ns')
    
    # Send 8 data bits (LSB first)
    for i in range(8):
        bit_val = (data >> i) & 1
        dut.ui_in.value = bit_val
        await Timer(104167, unit='ns')
        
    # Stop bit (1)
    dut.ui_in.value = 1
    await Timer(104167, unit='ns')
    
    # Delay between data bytes 
    await Timer(10000, unit='ns')

# Manual UART RX function for physical 9600 baud
async def uart_rx(dut):
    # 1. Wait for the start bit (bit 0 drops from 1 to 0)
    while True:
        await Edge(dut.uo_out)
        # FIXED: Removed deprecated .binstr in favor of str()
        if str(dut.uo_out.value)[-1] == '0':
            break
            
    # 2. Wait half a bit period to sample in the middle of the start bit
    await Timer(52083, unit='ns')
    
    received_byte = 0
    
    # 3. Sample the 8 data bits (LSB first)
    for i in range(8):
        # Wait a full bit period (1 / 9600 sec)
        await Timer(104167, unit='ns')
        
        # FIXED: Removed deprecated .binstr in favor of str()
        bit_val = int(str(dut.uo_out.value)[-1])
        received_byte |= (bit_val << i)
        
    # 4. Wait a full bit period to reach the center of the stop bit
    await Timer(104167, unit='ns')
    
    return received_byte

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start Simulation")

    # 15.15ns period = ~66 MHz clock
    clock = Clock(dut.clk, 15.15, unit="ns")
    cocotb.start_soon(clock.start())

    # Initial values
    dut.ena.value = 1
    dut.ui_in.value = 1  # UART Idle is high
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    # Reset
    dut._log.info("Applying Reset")
    await Timer(100, unit='ns')
    dut.rst_n.value = 1
    
    await Timer(10000, unit='ns')

    # Send Samples
    dut._log.info("Sending Samples...")
    await uart_tx(dut, 1)
    await uart_tx(dut, 1)
    await uart_tx(dut, 1)

    # Send first two Coefficients
    dut._log.info("Sending Coefficients...")
    await uart_tx(dut, 1)
    await uart_tx(dut, 1)
    
    # FIXED: Start listening in the background BEFORE sending the final byte 
    # so we don't miss the hardware's immediate response!
    rx_task = cocotb.start_soon(uart_rx(dut))
    
    # Send the final Coefficient
    await uart_tx(dut, 1)

    # Wait for the background RX task to finish capturing the output
    dut._log.info("Waiting for processing and receiving UART output...")
    result = await rx_task 
    
    dut._log.info(f"Received FIR calculation result: {result}")
    
    # Assert the reconstructed parallel integer
    assert result == 3, f"FIR calculation failed. Expected 3, got {result}"
