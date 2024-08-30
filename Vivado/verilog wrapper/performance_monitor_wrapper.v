`timescale 1ns / 1ps

module performance_monitor_wrapper #(parameter COUNT_CYCLES = 32'h F_4240, INPUT_STREAMS = 4)(
    input aclk,
    input resetn,
    

	input S00_AXIS_TVALID,
	input [127:0] S00_AXIS_TDATA,
	output S00_AXIS_TREADY,

    input S01_AXIS_TVALID,
	input [127:0] S01_AXIS_TDATA,
	output S01_AXIS_TREADY,

    output [31:0] counter_value,
    output ready_to_read,
    input [31:0] command
    
);


performance_monitor #(.COUNT_CYCLES(COUNT_CYCLES),.INPUT_STREAMS(INPUT_STREAMS)) PM (
 .aclk(aclk), 
 .resetn(resetn),
 .S00_AXIS_TVALID(S00_AXIS_TVALID),
 .S00_AXIS_TREADY(S00_AXIS_TREADY),
 .S00_AXIS_TDATA(S00_AXIS_TDATA),
 .S01_AXIS_TVALID(S01_AXIS_TVALID),
 .S01_AXIS_TREADY(S01_AXIS_TREADY),
 .S01_AXIS_TDATA(S01_AXIS_TDATA),
 .counter_value(counter_value),
 .ready_to_read(ready_to_read),
 .command(command)
 ); 



endmodule	

