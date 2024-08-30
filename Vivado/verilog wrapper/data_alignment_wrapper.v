`timescale 1ns / 1ps

module data_alignment_wrapper #(parameter RECEIVER_STREAMS = 4) (
    input aclk,
    input resetn,
    
	output M00_AXIS_TVALID,
	output [127:0] M00_AXIS_TDATA,
	input M00_AXIS_TREADY,

    input [RECEIVER_STREAMS - 1:0] S_AXIS_TVALID,
    input [RECEIVER_STREAMS- 1:0] [13: 0] S_AXIS_TDATA,
    output [RECEIVER_STREAMS - 1:0] S_AXIS_TREADY,

    output  [31:0] counter_value,
    output  ready_to_read,
    input  [31:0] command
    
);


data_alignment DA (
    .aclk(aclk), 
    .resetn(resetn),
    .S00_AXIS_TVALID(S_AXIS_TVALID),
    .S00_AXIS_TREADY(S_AXIS_TREADY),
    .S00_AXIS_TDATA(S_AXIS_TDATA),
    .M00_AXIS_TVALID(M00_AXIS_TVALID),
    .M00_AXIS_TREADY(M00_AXIS_TREADY),
    .M00_AXIS_TDATA(M00_AXIS_TDATA),
    .counter_value(counter_value),
    .ready_to_read(ready_to_read),
    .command(command)
 ); 
endmodule	