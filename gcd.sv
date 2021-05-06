//gcd


module gcd(input [31:0] a_in,		//operand a
       input [31:0] b_in,		//operand b
       input start,			//validates the input data
       input reset_n,			//reset
       input clk,			//clock
       output reg [31:0] result,	//output of GCD engine
       output reg done);		//validates output value

       reg [31:0] first_num;
       reg [31:0] sec_num;
       reg [31:0] third_num;


    
       enum reg[4:0]{ IDLE = 5'b00001, READ = 5'b00010, A_G_B = 5'b00100,
                      B_G_A = 5'b01000,  DONE = 5'b10000} ps, ns;


       // copy the next state to the present state at the edge of the clock cycle
       always_ff @(posedge clk, negedge reset_n) begin
           if (!reset_n) ps <= IDLE;
	   else          ps <= ns;
       end
      

       // combinational logic determines the next state and carry out the GCD algorithm based on the state
       always_comb  begin
	     unique case (ps)
	           IDLE :
		          if (start) begin
			        ns= READ;
                          end
		          else begin  
			  ns=IDLE;
			  end

	           READ:   begin
		           first_num = a_in;
			   sec_num = b_in;
			   ns = A_G_B;
			   end
							         
		   A_G_B :  
		          if (first_num > sec_num) begin 
			  ns = B_G_A;
                          third_num = first_num - sec_num;
			  first_num <= third_num;
			  end
			  else if (sec_num > first_num) begin
                          third_num = sec_num-first_num;
			  sec_num <= third_num;
			  ns = B_G_A;
			  end
			  else ns = DONE;

		   B_G_A :
		          if (first_num > sec_num) begin
			  ns = A_G_B;
			  third_num = first_num - sec_num;
                          first_num <= third_num;
			  end
		          else if (sec_num > first_num) begin
			  third_num = sec_num-first_num;
			  sec_num <= third_num;
			  ns = A_G_B;
			  end
			  else ns = DONE;
	           DONE : begin 
		        ns = IDLE;
			result = first_num;
		   end
            endcase
	    // assigns done to the MS of the state
	    assign {done} = ps[4];
       end

      
endmodule
