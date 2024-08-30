`timescale 1ns / 1ps

module tg_14bit(
    //clocks
    input logic aclk,
    input logic resetn,
    input logic extenable,
    
    //AXI stream Interface
    output logic M00_AXIS_TVALID,
    output logic [13:0] M00_AXIS_TDATA,
    input logic M00_AXIS_TREADY

    );
    parameter AdderStop = 1'b1;   
    
    logic [13:0] nextValue;
    logic enable;
    logic AdderReset;
    
    assign M00_AXIS_TVALID = resetn & extenable;
    assign enable = M00_AXIS_TREADY & M00_AXIS_TVALID;
    assign AdderReset = !resetn || ( nextValue[12] == AdderStop );
    
    always_ff @(posedge aclk) begin
        if(AdderReset)
            M00_AXIS_TDATA <= 0;
        else if(enable) begin
            M00_AXIS_TDATA <= nextValue;    
        end
     end
        
     always_comb begin
            nextValue = M00_AXIS_TDATA + 1;    
     end   
        
    
endmodule
