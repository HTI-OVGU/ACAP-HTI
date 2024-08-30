`timescale 1ns / 1ps

module tg_14bit_wrapper #(parameter RECEIVER_STREAMS = 8)(
    input wire aclk,
    input wire resetn,
    input wire extenable,
    
    output [RECEIVER_STREAMS - 1:0] M_AXIS_TVALID,
    output [RECEIVER_STREAMS - 1:0] [13:0] M_AXIS_TDATA,
    input [RECEIVER_STREAMS - 1:0] M_AXIS_TREADY
    
    );
    
    genvar i;
    generate 
        for(i = 0; i < RECEIVER_STREAMS; i = i + 1) begin
            tg_14bit TG (
                .aclk(aclk),
                .resetn(resetn),
                .extenable(extenable),
                .M00_AXIS_TVALID(M_AXIS_TVALID[i]),
                .M00_AXIS_TREADY(M_AXIS_TREADY[i]),
                .M00_AXIS_TDATA(M_AXIS_TDATA[i])
                );
        end
    endgenerate
    
endmodule
