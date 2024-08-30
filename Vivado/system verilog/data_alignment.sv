`timescale 1ns / 1ps

typedef struct {
    logic TVALID;
    logic TREADY;
    logic [127:0] TDATA;
} AXI_STREAM;     

module data_alignment #(parameter COUNT_CYCLES = 32'h F_4240, FIFO_SIZE = 3'b101, INPUT_STREAMS = 4, OUTPUT_STREAMS = 1)(
    //clocks
    input logic aclk,
    input logic resetn,
    
    //AXI stream Interface for traffic generator streams
    input logic  [INPUT_STREAMS-1:0] S00_AXIS_TVALID,
    input logic  [INPUT_STREAMS-1:0] [13:0] S00_AXIS_TDATA,
    output logic [INPUT_STREAMS-1:0] S00_AXIS_TREADY,
 
    //AXI stream Interface
    output logic [OUTPUT_STREAMS-1:0] M00_AXIS_TVALID,
    output logic [OUTPUT_STREAMS-1:0] [127:0] M00_AXIS_TDATA,
    input logic  [OUTPUT_STREAMS-1:0] M00_AXIS_TREADY,


    //ports to monitor performance
    output logic [31:0] counter_value,
    output logic ready_to_read,
    input logic [31:0] command
    );

    // variables for performance monitor
    // one global counter
    logic [31:0] global_counter;
    logic [31:0] next_count_global;
    logic enable_global_counter;
    
    // one counter for each output stream  
    logic [31:0] package_counter [OUTPUT_STREAMS];
    logic [31:0] next_count_package [OUTPUT_STREAMS];
    logic enable_package_counter [OUTPUT_STREAMS];
    
    // varialbes for handling read and write acces
    logic transaction_reset;
    logic command_reset;
    logic [4:0] addr;
    logic addr_valid;
    

    // struct for aligned data
    AXI_STREAM TG_AXI_ALIGNED[OUTPUT_STREAMS] ='{OUTPUT_STREAMS{'{1'd0, 1'd0, 128'd0}}};
    
    // variables for FIFO
    logic [7:0] fifo_space [OUTPUT_STREAMS] = '{OUTPUT_STREAMS{{FIFO_SIZE}}};
    logic [7:0] fifo_space_decr [OUTPUT_STREAMS];
    logic [7:0] fifo_space_incr [OUTPUT_STREAMS];
    
    logic fifo_write_en [OUTPUT_STREAMS];
    logic fifo_read_en [OUTPUT_STREAMS];
    
    logic [7:0] fifo_read [OUTPUT_STREAMS];
    logic [7:0] fifo_read_next [OUTPUT_STREAMS];
    logic fifo_read_roll [OUTPUT_STREAMS];
    
    logic [7:0] fifo_write [OUTPUT_STREAMS];
    logic [7:0] fifo_write_next [OUTPUT_STREAMS];
    logic fifo_write_roll [OUTPUT_STREAMS];
    
    logic fifo_nfull [OUTPUT_STREAMS];
    logic fifo_nempty [OUTPUT_STREAMS];
    
    logic [127:0] fifo [OUTPUT_STREAMS] [FIFO_SIZE];
 
    // assign global counter 
    assign enable_global_counter = global_counter != COUNT_CYCLES;
    
    genvar i,j;
    for (i = 0; i < OUTPUT_STREAMS; i++) begin
    
        // assign package counter
        assign enable_package_counter[i] = enable_global_counter && M00_AXIS_TREADY[i];
         
        // fifo full or empty  
        assign fifo_nfull[i] = ~(fifo_space[i] == 8'b0);
        assign fifo_nempty[i] = ~(fifo_space[i] == FIFO_SIZE);
        
        // AXI presents valid data if fifo not empty    
        assign M00_AXIS_TVALID[i] = fifo_nempty[i] & resetn;
        
        // module takes data if fifo not full
        assign TG_AXI_ALIGNED[i].TREADY = fifo_nfull[i] & resetn;
        
        // data is valid if one TG presents valid data
        assign TG_AXI_ALIGNED[i].TVALID = {S00_AXIS_TVALID[i*4],S00_AXIS_TVALID[i*4 + 1],S00_AXIS_TVALID[i*4+2],S00_AXIS_TVALID[i*4+3]};
    
        // align data
        for(j=0; j< 4; j++) begin
            // data is valid if every TG presents valid data
            assign TG_AXI_ALIGNED[i].TVALID = TG_AXI_ALIGNED[i].TVALID & S00_AXIS_TVALID[j +i*4];
        
            assign S00_AXIS_TREADY[j+i*4] = TG_AXI_ALIGNED[i].TREADY;
        end
        
        for(j=0; j< 4; j++) begin
            assign TG_AXI_ALIGNED[i].TDATA[(j * 32 + 13):(j * 32)] = S00_AXIS_TDATA[j+(i*4)];
        end
    
        // assign read and write enables
        assign fifo_read_en[i] = M00_AXIS_TVALID[i] & M00_AXIS_TREADY[i];
        assign fifo_write_en[i] = TG_AXI_ALIGNED[i].TREADY & TG_AXI_ALIGNED[i].TVALID;
        
        // write/read pointer are defined as rollover
        assign fifo_read_roll[i] = fifo_read[i] == (FIFO_SIZE - 1);
        assign fifo_write_roll[i] = fifo_write[i] == (FIFO_SIZE - 1);
       

    
    end
    // assign control commands
    assign command_reset = command[6];
    assign addr = command[5:1];
    
    assign transaction_reset = (!resetn) || (command_reset == 1);
    assign addr_valid = addr <= 1;
    
    // handle cycle count
    always_ff @(posedge aclk) begin
        if(transaction_reset) begin
            global_counter <= 0;
            package_counter <= '{OUTPUT_STREAMS{{32'd0}}};
            ready_to_read <= 0;
        end else begin
            global_counter <= next_count_global;
            package_counter <= next_count_package;
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
            next_count_global = global_counter + 32'b1;  
        else
            next_count_global = global_counter;
    end

    for (i = 0; i < OUTPUT_STREAMS; i++) begin
        always_comb begin     
            if(enable_package_counter[i])
                next_count_package[i] = package_counter[i] + 32'b1;
            else
                next_count_package[i] = package_counter[i];   
        end
    
        // read data
        always_ff @(posedge aclk) begin
            if(!resetn) begin
                fifo_read[i] <= 0;
                M00_AXIS_TDATA[i] <= 0;
            end else begin
                if(fifo_read_en[i]) begin
                    M00_AXIS_TDATA[i] <= fifo[i][fifo_read[i]];
                    fifo_read[i] <= fifo_read_next[i];
                end else begin
                    M00_AXIS_TDATA[i] <= 0;
                    fifo_read[i] <= fifo_read[i];
                end     
            end   
        end
        
        // write data
        always_ff @(posedge aclk) begin
            if(!resetn) begin
                fifo_write[i] <= 0;
                fifo[i] <= '{FIFO_SIZE{{128'd0}}};
            end else begin
                if(fifo_write_en[i]) begin
                    fifo[i][fifo_write[i]] <= TG_AXI_ALIGNED[i].TDATA;
                    fifo_write[i] <= fifo_write_next[i];
                end else begin
                    fifo[i][fifo_write[i]] <= fifo[i][fifo_write[i]];
                    fifo_write[i] <= fifo_write[i]; 
                end    
            end      
        end
    
        // check if fifo space increased or decreased    
        always_ff @(posedge aclk) begin
            if(!resetn) begin
                fifo_space[i] <= FIFO_SIZE;
            end else begin
                case({fifo_write_en[i],fifo_read_en[i]})
                    2'b01   :   fifo_space[i] <= fifo_space_incr[i];
                    2'b10   :   fifo_space[i] <= fifo_space_decr[i];
                    default :   fifo_space[i] <= fifo_space[i];
                endcase                
            end
         end
        
        // increase read addr
        always_comb begin
            if(fifo_read_roll[i])
                fifo_read_next[i] = 0;
            else
                fifo_read_next[i] = fifo_read[i] + 1'b1;
        end
        
        // increase write addr
        always_comb begin  
            if(fifo_write_roll[i])
                fifo_write_next[i] = 0;
            else
                fifo_write_next[i] = fifo_write[i] + 1'b1;
        end
        
        // increase space
        always_comb begin
            if(fifo_nfull[i])
                fifo_space_decr[i] = fifo_space[i] - 1'b1;
            else
                fifo_space_decr[i] = 0;
                
            if(fifo_nempty[i])
                fifo_space_incr[i] = fifo_space[i] + 1'b1; 
            else
                fifo_space_incr[i] = FIFO_SIZE;                 
         end   
    end    
    
endmodule