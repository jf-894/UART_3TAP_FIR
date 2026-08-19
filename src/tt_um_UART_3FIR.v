`default_nettype none

module tt_um_UART_3FIR (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    localparam integer CLOCK_HZ  = 66_000_000;
    localparam integer BAUD_RATE = 9600;

    wire       rx_trigger;
    wire [7:0] internal_data;

    wire       fir_trigger;
    wire [7:0] final_data;

    wire       uart_tx;
    wire [3:0] count;
    
    reg uart_rx_meta;
    reg uart_rx_sync;

    assign uo_out[0]   = uart_tx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rx_meta <= 1'b1;
            uart_rx_sync <= 1'b1;
        end
        else begin
            uart_rx_meta <= ui_in[0];
            uart_rx_sync <= uart_rx_meta;
        end
    end

    UART_RX #(
        .CLOCK_HZ  (CLOCK_HZ),
        .BAUD_RATE (BAUD_RATE)
        ) my_RX (
        .data_in  (uart_rx_sync),
        .clk      (clk),
        .rst_n    (rst_n),
        .data_out (internal_data),
        .trigger  (rx_trigger)
    );

    input_counter my_counter (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_trigger (rx_trigger),
        .count      (count)
    );

    _3tap_fir my_FIR (
        .count      (count),
        .user_in    (internal_data),
        .rx_trigger (rx_trigger), 
        .final_fir  (final_data),
        .trigger    (fir_trigger),
        .clk        (clk),
        .rst_n      (rst_n)
    );

    UART_TX #(
        .CLOCK_HZ  (CLOCK_HZ),
        .BAUD_RATE (BAUD_RATE)
    ) my_TX (
        .clk     (clk),
        .rst_n   (rst_n),
        .data    (final_data),
        .trigger (fir_trigger),
        .test    (uart_tx)
    );

   
    assign uo_out[7:1] = 7'b0000000;

    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;


    wire _unused = &{
        ena,
        ui_in[7:1],
        uio_in,
        1'b0
    };
    
endmodule
//Submodule

module UART_RX #(
    parameter integer CLOCK_HZ  = 66_000_000,
    parameter integer BAUD_RATE = 9600
)(
    input  wire       data_in,
    input  wire       clk,
    input  wire       rst_n,
    output reg  [7:0] data_out,
    output reg        trigger
);

    localparam integer CLKS_PER_BIT_INT = CLOCK_HZ / BAUD_RATE;
    localparam integer HALF_BIT_INT     = CLKS_PER_BIT_INT / 2;

    localparam [13:0] CLKS_PER_BIT = CLKS_PER_BIT_INT[13:0];
    localparam [13:0] HALF_BIT     = HALF_BIT_INT[13:0];

    localparam [1:0] IDLE  = 2'b00;
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA  = 2'b10;
    localparam [1:0] STOP  = 2'b11;

    reg [1:0]  state;
    reg [13:0] counter;
    reg [2:0]  data_count;
    reg [7:0]  received_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            counter       <= 14'd0;
            data_count    <= 3'd0;
            received_data <= 8'd0;
            data_out      <= 8'd0;
            trigger       <= 1'b0;
        end
        else begin
            
            trigger <= 1'b0;

            case (state)

                IDLE: begin
                    counter    <= 14'd0;
                    data_count <= 3'd0;
                    
                    if (data_in == 1'b0)
                        state <= START;
                end

                START: begin
                    
                    if (counter == HALF_BIT - 14'd1) begin
                        counter <= 14'd0;

                        if (data_in == 1'b0)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end
                    else begin
                        counter <= counter + 14'd1;
                    end
                end

                DATA: begin
                    
                    if (counter == CLKS_PER_BIT - 14'd1) begin
                        counter <= 14'd0;
                        received_data[data_count] <= data_in;

                        if (data_count == 3'd7) begin
                            data_count <= 3'd0;
                            state      <= STOP;
                        end
                        else begin
                            data_count <= data_count + 3'd1;
                        end
                    end
                    else begin
                        counter <= counter + 14'd1;
                    end
                end

                STOP: begin
                    if (counter == CLKS_PER_BIT - 14'd1) begin
                        counter <= 14'd0;
                        
                        if (data_in == 1'b1) begin
                            data_out <= received_data;
                            trigger  <= 1'b1;
                        end

                        state <= IDLE;
                    end
                    else begin
                        counter <= counter + 14'd1;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule


module UART_TX #(
    parameter integer CLOCK_HZ  = 66_000_000,
    parameter integer BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data,
    input  wire       trigger,
    output reg        test
);

    localparam integer CLKS_PER_BIT_INT = CLOCK_HZ / BAUD_RATE;
    localparam [13:0]  CLKS_PER_BIT     = CLKS_PER_BIT_INT[13:0];

    localparam [1:0] IDLE  = 2'b00;
    localparam [1:0] START = 2'b01;
    localparam [1:0] DATA  = 2'b10;
    localparam [1:0] STOP  = 2'b11;

    reg [1:0]  state;
    reg [13:0] counter;
    reg [2:0]  data_count;
    reg [7:0]  transmit_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            counter       <= 14'd0;
            data_count    <= 3'd0;
            transmit_data <= 8'd0;
            test          <= 1'b1;
        end
        else begin
            case (state)

                IDLE: begin
                    test       <= 1'b1;
                    counter    <= 14'd0;
                    data_count <= 3'd0;

                    if (trigger) begin
                        transmit_data <= data;
                        state         <= START;
                    end
                end

                START: begin
                    test <= 1'b0;

                    if (counter == CLKS_PER_BIT - 14'd1) begin
                        counter <= 14'd0;
                        state   <= DATA;
                    end
                    else begin
                        counter <= counter + 14'd1;
                    end
                end

                DATA: begin
                    test <= transmit_data[data_count];

                    if (counter == CLKS_PER_BIT - 14'd1) begin
                        counter <= 14'd0;

                        if (data_count == 3'd7) begin
                            data_count <= 3'd0;
                            state      <= STOP;
                        end
                        else begin
                            data_count <= data_count + 3'd1;
                        end
                    end
                    else begin
                        counter <= counter + 14'd1;
                    end
                end

                STOP: begin
                    test <= 1'b1;

                    if (counter == CLKS_PER_BIT - 14'd1) begin
                        counter <= 14'd0;
                        state   <= IDLE;
                    end
                    else begin
                        counter <= counter + 14'd1;
                    end
                end

                default: begin
                    state <= IDLE;
                    test  <= 1'b1;
                end

            endcase
        end
    end

endmodule


module input_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_trigger,
    output reg  [3:0] count
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count    <= 4'd1;
        end
        else if (rx_trigger) begin
            if (count < 4'd6) begin
                count <= count + 4'd1;
            end
            else begin
                count <= 4'd1;
            end
        end
    end

endmodule


module _3tap_fir (
    input  wire [3:0] count,
    input  wire [7:0] user_in,
    input  wire       rx_trigger,
    output reg  [7:0] final_fir,
    output reg        trigger,
    input  wire       clk,
    input  wire       rst_n
);

    reg [7:0] sample0;
    reg [7:0] sample1;
    reg [7:0] sample2;

    reg [7:0] coefficient0;
    reg [7:0] coefficient1;
    reg [7:0] coefficient2;
    
    reg       calc_pending; 

    wire [15:0] product0;
    wire [15:0] product1;
    wire [15:0] product2;

    wire [19:0] fir_sum;

    assign product0 = sample0 * coefficient0;
    assign product1 = sample1 * coefficient1;
    assign product2 = sample2 * coefficient2;

    assign fir_sum =
        {4'b0000, product0} +
        {4'b0000, product1} +
        {4'b0000, product2};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample0      <= 8'd0;
            sample1      <= 8'd0;
            sample2      <= 8'd0;

            coefficient0 <= 8'd0;
            coefficient1 <= 8'd0;
            coefficient2 <= 8'd0;

            final_fir    <= 8'd0;
            trigger      <= 1'b0;
            calc_pending <= 1'b0;
        end
        else begin
            
            trigger <= 1'b0; 
    
            if (rx_trigger) begin
                case (count)
                    4'd1: sample0      <= user_in;
                    4'd2: sample1      <= user_in;
                    4'd3: sample2      <= user_in;
                    4'd4: coefficient0 <= user_in;
                    4'd5: coefficient1 <= user_in;
                    4'd6: begin
                        coefficient2 <= user_in;
                        calc_pending <= 1'b1; 
                    end
                    default: ;
                endcase
            end
            
          
            if (calc_pending) begin
                calc_pending <= 1'b0;
                
                if (fir_sum > 20'd255)
                    final_fir <= 8'd255;
                else
                    final_fir <= fir_sum[7:0];
                    
                trigger <= 1'b1; 
            end
        end
    end

endmodule

`default_nettype wire
