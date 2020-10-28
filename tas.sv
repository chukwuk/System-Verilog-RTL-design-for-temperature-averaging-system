module tas(input clk_50,
           input clk_2,
           input reset_n,
	   input serial_data,
	   input data_ena,
	   output reg  ram_wr_n,
	   output reg [10:0] ram_data,
	   output reg [11:0] ram_addr
           
);
// variables for processing and averaging data
reg [7:0] mem;
reg [7:0] data_out;
reg [7:0] first;
reg [7:0] second;
reg [7:0] third;
reg [7:0] fourth;
reg [7:0] header;
reg [7:0] store_header;
reg [7:0] store_first;
reg [7:0] store_second;
reg [7:0] store_third;
reg [7:0] store_fourth;


initial ram_addr = 12'h800;
// states for collecting data
enum reg[4:0]{ IDLE = 5'b0_1100, HEADER = 5'b0_1000, FIRST = 5'b0_0010, 
             SECOND = 5'b0_0100, THIRD =5'b0_0110, FOURTH = 5'b0_0111, DONE_CO =5'b1_1111} ps, ns;

// states for averaging data
enum reg[0:0] { DONE_D = 1'b1, AVG_TEMP = 1'b0} nextstate, presentstate;

  
 // buffer the serial data 

always_ff @(posedge clk_50) begin
  if (data_ena) begin
    mem[7] <= serial_data;
    mem[6] <= mem [7];
    mem[5] <= mem [6];
    mem[4] <= mem [5];
    mem[3] <= mem [4];
    mem[2] <= mem [3];
    mem[1] <= mem [2];
    mem[0] <= mem [1];
  end
  else
    mem <= mem;
   end

// stores the one packet of data
always_ff@(posedge clk_50) begin
    if (data_ena==1'b0)
    data_out<=mem;
    else
    data_out<=data_out;
  end

always_ff@(posedge clk_50) begin
   if (!reset_n) 
     ps<=IDLE;
     else begin
     if (data_ena==1'b0)
     ps<=ns;
     else
     ps<=ps;
     end
end


//  always combinational block for copying the each packet of the data
always_comb begin
  unique case(ps)
    IDLE : begin
      if (data_ena==1'b1)
      ns = HEADER;
      else
      ns = ns;
     end
    HEADER : begin
      if (data_ena==1'b1) begin
      ns = FIRST;
      end 
      else begin
      header = data_out; // copies the header
      ns = ns;
      end
     end
     FIRST : begin 
       if (data_ena==1'b1) begin
       ns = SECOND;
       end
       else
       first = data_out;  // copies the first data
       ns = ns;
     end
     SECOND : begin
        if (data_ena==1'b1) begin
       ns = THIRD;
       end
       else
       ns = ns;
       second = data_out; // copies the second data
      end
     THIRD : begin
       if (data_ena==1'b1) begin
       ns = FOURTH;
       end 
       else
       ns = ns;
       third = data_out;  // copies third data
       end
      FOURTH : begin
       if (data_ena==1'b1) begin
       ns = DONE_CO;
       end
       else
       fourth = data_out; // copies fourth data
       ns = DONE_CO;
       end 
      DONE_CO :
        ns = IDLE;
   endcase
   end
// stores the 5 packet data based on the positive edge of the done signal
always@(posedge ns[4]) begin
  store_header = header;
  store_first = first;
  store_second = second;
  store_third = third;
  store_fourth = fourth;

end
// always block calculates the memory address  for the data
always@(posedge ns[4]) begin
  if (ram_addr==12'h0) begin
     ram_addr = 12'h7FF;
  end
  else begin
    if (store_header == 8'hA5 || store_header == 8'hC3) 
         ram_addr = ram_addr-1'b1;
    else
         ram_addr = ram_addr;
  end
end


// The flip flop copies the next state of the present state.
  // The state is either on  standby or calculating the average of the temperature
    always_ff@(posedge clk_2)  begin
         if (!reset_n) begin
            presentstate <= AVG_TEMP;
	 end
	 else 
	   presentstate <= nextstate;

     end
// it calculates the average of the data and decide the next state for the processing
     always_comb begin
        unique case (presentstate)
        AVG_TEMP:
	     if (ps[4]==1'b1 && ((store_header == 8'hA5) || (store_header == 8'hC3))) begin
	       ram_data = (store_fourth + store_first + store_second + store_third)/8'h4;
	       nextstate = DONE_D;
	       end
	      else begin
	       if (nextstate==DONE_D)
                 nextstate = DONE_D;
	       else
	         nextstate = AVG_TEMP;
	       end
        DONE_D :
	   nextstate = AVG_TEMP;
 	endcase
      end
     assign ram_wr_n = presentstate;  // triggers signal for writing to the ram address and ram data    

endmodule
