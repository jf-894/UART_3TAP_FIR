`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
 tt_um_UART_3FIR (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

always begin
  #7.575 clk = ~ clk;
end
 task UART_OUT(input [7:0] data);
     integer i;
     begin
     //Start bit
     ui_in[0] = 0;
     #104167;
     
     //Sends bits
    for (i = 0; i<8; i = i+1) begin
    ui_in[0] = data[i];
     #104167;
 end
    // Stop bit (1)
     ui_in[0] = 1;
     #104167;
   // Delay between data bytes  
 #500000;
 end
endtask


    initial begin
    clk = 0;
    rst_n = 0;
    ena = 1;
    ui_in = 8'b0000_0001;
    #100;
    rst_n = 1;
    #10000;
    //Samples
    UART_OUT(8'd0);
    
    UART_OUT(8'd0);
   
    UART_OUT(8'd1);
  
    //Coefficients
    UART_OUT(8'd0);
    
    UART_OUT(8'd0);
  
    UART_OUT(8'd1);
    
    #15_000_000;
    
    $finish;
    
end
endmodule
