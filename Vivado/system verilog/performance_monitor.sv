`timescale 1ns / 1ps

module performance_monitor #(parameter COUNT_CYCLES = 32'h F_4240, INPUT_STREAMS = 2)(
    input aclk,
    input resetn,
    
    //AXI stream Interface
	input logic S00_AXIS_TVALID,
	input logic [127:0] S00_AXIS_TDATA,
	output logic S00_AXIS_TREADY,

    input logic S01_AXIS_TVALID,
	input logic [127:0] S01_AXIS_TDATA,
	output logic S01_AXIS_TREADY,

    //ports for performance monitor
    output logic [31:0] counter_value,
    output logic ready_to_read,
    input logic [31:0] command
    
);
    // variables for performance Monitor
    logic [31:0] global_counter;
    logic [31:0] next_count_global; 
    logic [INPUT_STREAMS - 1:0] [31:0] package_counter;
    logic [INPUT_STREAMS - 1:0] [31:0] next_count_package;

    logic enable_global_counter;
    logic [INPUT_STREAMS - 1:0] enable_package_counter;
    logic [INPUT_STREAMS - 1:0] s_axis_valid;
    
    logic transaction_reset;
    logic command_reset;
    logic [4:0] addr;
    logic addr_valid;
    
    logic [INPUT_STREAMS - 1:0] tready_vector;
    
	assign s_axis_valid = {S00_AXIS_TVALID, S01_AXIS_TVALID}; 

	assign S00_AXIS_TREADY = tready_vector[0];
    assign S01_AXIS_TREADY = tready_vector[1];

    // assign control commands
    assign command_reset = command[6];
    assign addr = command[5:1];
    
    assign enable_global_counter = global_counter != COUNT_CYCLES;
    
    genvar i;
    for (i=0; i<INPUT_STREAMS; i = i + 1) begin
        assign enable_package_counter[i] = (global_counter != COUNT_CYCLES) && (s_axis_valid[i] == 1);
    end
    
    assign transaction_reset = (!resetn) || (command_reset == 1);
    assign addr_valid = addr <= INPUT_STREAMS;
    
    // handle cycle count
    always_ff @(posedge aclk) begin
        if(transaction_reset) begin
            global_counter <= 0;
            for (int t=0; t<INPUT_STREAMS; t = t + 1) begin
                package_counter[t] <= 0;
                tready_vector[t] <= 0;
            end
            ready_to_read <= 0;
        end else begin
            global_counter <= next_count_global;
            for (int t=0; t<INPUT_STREAMS; t = t + 1) begin
            	tready_vector[t] <= 1;
                package_counter[t] <= next_count_package[t];
            end
            ready_to_read <= ~enable_global_counter;
        end
    end    

    // handle count read
    always_ff @(posedge aclk) begin    
        if(!resetn)
            counter_value <= 0;
        else begin 
            if(~enable_global_counter) begin
                if(addr_valid) 
                    counter_value <= next_count_package[addr];
                else
                    counter_value <= '0;
            end else 
                counter_value <= counter_value;   
        end
        
        
    end
        
    // increase counter values
    always_comb begin
        if(enable_global_counter)
                next_count_global = global_counter + 1;  
            else
                next_count_global = global_counter;
    end

    always_comb begin            
        for (int t=0; t<INPUT_STREAMS; t = t + 1) begin
            if(enable_package_counter[t])
                next_count_package[t] = package_counter[t] + 1;
            else
                next_count_package[t] = package_counter[t];   
        end
    end
endmodule	


