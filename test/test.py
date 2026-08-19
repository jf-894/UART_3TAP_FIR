# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotbext.uart import UartSink  


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

   
    
    clock = Clock(dut.clk, 15.15, units="ns")
    cocotb.start_soon(clock.start())

   
    uart_receiver = UartSink(dut.uo_out[0], baud=9600, bits=8)

    # Initial values
    dut.ena.value = 1
    dut.ui_in.value = 1  # UART Idle is high (8'b0000_0001)
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    # Reset (wait a bit, then pull high)
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

    # 3. Wait for the hardware to process
    dut._log.info("Waiting for processing and UART output...")
    received_data = await uart_receiver.read(count=1) 
    
    # 4. Extract the integer and assert
    result = received_data[0]
    dut._log.info(f"Received FIR calculation result: {result}")
    
    assert result == 3, f"FIR calculation failed. Expected 3, got {result}"
