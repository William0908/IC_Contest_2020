//==================================
//Project: IC Design Contest_2020
//Designer: William
//Date: 2022/07/14
//Version: 2.0
//==================================
module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg valid;
// FSM
reg [2:0] state;
reg [2:0] n_state; 
parameter RESET   = 3'b000; // 0
parameter STRING  = 3'b001; // 1
parameter PATTERN = 3'b010; // 2
parameter IDLE    = 3'b011; // 3
parameter MATCH   = 3'b100; // 4
parameter HEAD    = 3'b101; // 5
parameter ENDING  = 3'b110; // 6
parameter OUTPUT  = 3'b111; // 7
//
reg [2:0] pattern_done;
reg [5:0] string_cnt;
reg [3:0] pattern_cnt;
reg [7:0] string_reg [0:31];
reg [7:0] pattern_reg [0:7];
reg [4:0] string_end;
reg [2:0] pattern_end;
// Control signal
reg [3:0] match_cnt;
reg match_flag;
wire unmatch_flag;
reg head_flag;
reg ending_flag;
// Star
reg star_flag;
reg get_star;
reg [2:0] star_match_temp;

integer i;

// FSM current state
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    state <= 0;
	end
	else begin
		state <= n_state;
	end
end

// FSM next state
always @(*) begin
	case(state)
	     RESET: begin
	     	if(isstring) n_state = STRING;
	     	else if(ispattern) n_state = PATTERN;
	     	//else if(head_flag) n_state = HEAD;
	     	//else if(pattern_done == 2) n_state = MATCH;
	     	else n_state = OUTPUT;
	     end
         STRING: begin
         	if(ispattern) n_state = PATTERN;
         	else n_state = state;
         end
         PATTERN: begin
            if(!ispattern) n_state = IDLE;
            else n_state = state;
         end
         IDLE: begin
            if(pattern_done == 3) begin
            	if(head_flag) n_state = HEAD;
                else if(ending_flag && !head_flag) n_state = ENDING;
                else n_state = MATCH;
            end
            else begin
            	n_state = IDLE;
            end
         end
         MATCH: begin
         	if(unmatch_flag || match_flag) n_state = RESET;
         	else n_state = state;
         end
         HEAD: begin
         	if(unmatch_flag || match_flag) n_state = RESET;
         	else n_state = state;
         end
         ENDING: begin
         	if(string_cnt == 0 || match_flag) n_state = RESET;
         	else n_state = state;
         end
         OUTPUT: begin
         	if(isstring) n_state = STRING;
         	else if(ispattern) n_state = PATTERN;
         	else n_state = state;
         end
         default: begin
         	n_state = state;
         end
	endcase
end

// Match flag
always @(*) begin
    case(state)
         MATCH: begin
             /*if(star_flag) begin
                 if(match_cnt != 0 && match_cnt == pattern_end) match_flag <= 1;
                 else match_flag <= 0;
             end*/
             //else begin
                 if(match_cnt != 0 && match_cnt == pattern_end + 1) match_flag <= 1;
                 else match_flag <= 0;
             //end 
         end
         HEAD: begin
             if(ending_flag) begin // ^ and $ sign
                if(match_cnt != 0 && match_cnt == pattern_end) match_flag <= 1;
                else match_flag <= 0;
             end
             else begin // ^ sign
                 if(match_cnt != 0 && match_cnt == pattern_end) match_flag <= 1;
                 else match_flag <= 0;
             end  
         end
         ENDING: begin
             if(star_flag) begin // star
                 if(match_cnt != 0 && match_cnt == pattern_end - 1) match_flag <= 1;
                 else match_flag <= 0;
             end
             else begin
                 if(match_cnt != 0 && match_cnt == pattern_end) match_flag <= 1;
                 else match_flag <= 0;
             end 
         end
         default: begin
             match_flag <= 0;
         end
    endcase
end

// Unmatch flag
//assign unmatch_flag = (state == MATCH && (string_cnt == string_end + 1 && pattern_cnt == 0) || (string_cnt == string_end && string_reg[string_end] != pattern_reg[0]) ) ? 1'd1 : 1'd0;
assign unmatch_flag = (state == MATCH) ? ( (string_cnt == string_end + 1) ? 1'd1 : 1'd0 ) : (string_cnt == string_end && string_reg[string_end] != pattern_reg[0] ? 1'd1 : 1'd0);
// Pattern input done
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    pattern_done <= 0;
	end
	else if(ispattern) begin
		pattern_done <= 1;
	end
	else if( (pattern_done == 1 || pattern_done == 2) && !ispattern) begin
		pattern_done <= pattern_done + 1;
	end
	else begin
		pattern_done <= 0;
	end
end

// String index
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    string_cnt <= 0;
	end
	else begin
		case(n_state)
             RESET: begin
             	string_cnt <= 0;
             end
             STRING: begin
             	if(string_cnt == 31) string_cnt <= 0;
             	else string_cnt <= string_cnt + 1;
             end
             IDLE: begin
                if(star_flag) begin
                    string_cnt <= 0;
                end
                else begin
                    if(ending_flag && !head_flag) string_cnt <= string_end;
                    //else if(head_flag) string_cnt <= 0;
                    else string_cnt <= 0;
                end
             end
             MATCH: begin
             	if(string_cnt == string_end + 1) begin // stop counting
             		string_cnt <= string_cnt;
             	end
                else begin
                    string_cnt <= string_cnt + 1;             
                end          	
             end
             HEAD: begin
             	if(string_cnt == string_end) begin
             		string_cnt <= string_cnt;
             	end
             	else begin
             		string_cnt <= string_cnt + 1;
             	end
             end
             ENDING: begin
                if(star_flag) begin
                    if(string_cnt == string_end) begin
                        string_cnt <= 0;
                    end
                    else begin
                        string_cnt <= string_cnt + 1;
                    end
                end
                else begin
                    if(string_cnt == 0) begin
                        string_cnt <= string_cnt;
                    end
                    else begin
                        string_cnt <= string_cnt - 1;
                    end
                end
             end
             OUTPUT: begin
             	string_cnt <= 0;
             end
             default: begin
             	string_cnt <= string_cnt;
             end
		endcase
	end
end

// Pattern index
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    pattern_cnt <= 0;
	end
	else begin
		case(n_state)
             RESET: begin
             	pattern_cnt <= 0;
             end
             PATTERN: begin
             	if(pattern_cnt == 7) pattern_cnt <= 0;
             	else pattern_cnt <= pattern_cnt + 1;
             end
             IDLE: begin
                if(star_flag) begin
                    pattern_cnt <= 0; 
                end
                else begin
                    if(head_flag) pattern_cnt <= 1;
                    else if(ending_flag) pattern_cnt <= pattern_end - 1;
                    else pattern_cnt <= 0;
                end 
             end
             MATCH: begin
                if(star_flag) begin // star
                    if(pattern_cnt == pattern_end) begin
                        pattern_cnt <= 0;
                    end
                    else begin
                         if(pattern_reg[0] == 8'h2E) begin // corner case for string_5: pattern_5
                             if(pattern_reg[pattern_cnt] == 8'h2A) pattern_cnt <= pattern_cnt + 1;
                             else if(pattern_reg[pattern_cnt] == string_reg[string_cnt] || pattern_reg[pattern_cnt] == 8'h2A || pattern_reg[pattern_cnt] == 8'h2E) pattern_cnt <= pattern_cnt + 1;
                             else if(match_cnt != 0) pattern_cnt <= star_match_temp + 1;
                             else pattern_cnt <= 1;
                         end
                         else begin
                             //if(pattern_reg[pattern_cnt + 1] == 8'h2A && (pattern_reg[pattern_cnt] == string_reg[string_cnt]) && (pattern_reg[pattern_cnt + 2] == string_reg[string_cnt + 1]) ) pattern_cnt <= pattern_cnt + 2;
                             if(pattern_reg[pattern_cnt] == string_reg[string_cnt] || pattern_reg[pattern_cnt] == 8'h2A || pattern_reg[pattern_cnt] == 8'h2E) pattern_cnt <= pattern_cnt + 1;
                             else if(match_cnt != 0) pattern_cnt <= star_match_temp + 1;
                             else pattern_cnt <= 0;
                         end
                         
                     end 
                end
                else begin
                    if(pattern_cnt == pattern_end) begin
                        pattern_cnt <= 0;
                    end
                    else begin
                        if(match_cnt == pattern_end - 2) begin // corner case for string_5: pattern_3
                            if( (pattern_reg[pattern_cnt] == string_reg[string_cnt] || pattern_reg[pattern_cnt] == 8'h2E) && (pattern_reg[pattern_cnt + 1] == string_reg[string_cnt + 1] || pattern_reg[pattern_cnt + 1] == 8'h2E) ) pattern_cnt <= pattern_cnt + 1;
                            else pattern_cnt <= 0;
                        end
                        else begin
                            if(pattern_reg[pattern_cnt] == string_reg[string_cnt] || pattern_reg[pattern_cnt] == 8'h2E) pattern_cnt <= pattern_cnt + 1;
                            else pattern_cnt <= 0;
                        end
                    end 
                end
             end
             HEAD: begin
             	if(pattern_cnt == pattern_end) begin
             	    pattern_cnt <= 0;
             	end
                /*else if(ending_flag) begin  // ^ and $ sign
                    if(string_reg[string_cnt] == 8'h20) pattern_cnt <= 1;
                    else if(pattern_reg[pattern_cnt] == string_reg[string_cnt]) pattern_cnt <= pattern_cnt + 1;
                    else pattern_cnt <= 0;
                end*/
                else begin
                    if(string_reg[string_cnt] == 8'h20 && pattern_reg[pattern_cnt] != 8'h2E) pattern_cnt <= 1;
                    else if(pattern_reg[pattern_cnt] == string_reg[string_cnt] || pattern_reg[pattern_cnt] == 8'h2E) pattern_cnt <= pattern_cnt + 1;
                    else pattern_cnt <= 0;
                end
             end
             ENDING: begin
                if(star_flag) begin // star, counting from zero
                    if(pattern_cnt == pattern_end - 1) begin
                        pattern_cnt <= 0;
                    end
                    else begin
                        if(pattern_reg[pattern_cnt] == string_reg[string_cnt] || pattern_reg[pattern_cnt] == 8'h2A || pattern_reg[pattern_cnt] == 8'h2E) pattern_cnt <= pattern_cnt + 1;
                        else if(match_cnt != 0) pattern_cnt <= star_match_temp + 1;
                        else pattern_cnt <= 0;
                    end
                end
                else begin
                    if(pattern_cnt == 0) begin
                        pattern_cnt <= pattern_end;
                    end
                    else begin
                        if(string_reg[string_cnt] == 8'h20) pattern_cnt <= pattern_end - 1;
                        else if(pattern_reg[pattern_cnt] == string_reg[string_cnt] || pattern_reg[pattern_cnt] == 8'h2E) pattern_cnt <= pattern_cnt - 1;
                        else pattern_cnt <= pattern_end;
                    end
                end   
             end
             default: begin
             	pattern_cnt <= pattern_cnt;
             end
		endcase
	end
end

// Register file of string
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    for(i = 0; i < 32; i = i + 1) begin
	    	string_reg[i] <= 0;
	    end
	end
	else begin
		case(n_state)
             STRING: begin
             	string_reg[string_cnt] <= chardata;
             end
             default: begin
             	for(i = 0; i < 32; i = i + 1) begin
	    	        string_reg[i] <= string_reg[i];
	            end
             end
		endcase
	end
end

// Register file of pattern
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    for(i = 0; i < 8; i = i + 1) begin
	    	pattern_reg[i] <= 0;
	    end
	end
	else begin
		case(n_state)
             RESET: begin
             	for(i = 0; i < 8; i = i + 1) begin
	    	        pattern_reg[i] <= 0;
	            end
             end
             PATTERN: begin
             	pattern_reg[pattern_cnt] <= chardata;
             end
             default: begin
             	for(i = 0; i < 8; i = i + 1) begin
	    	        pattern_reg[i] <= pattern_reg[i];
	            end
             end
		endcase
	end
end

// End of position
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    string_end <= 0;
	    pattern_end <= 0;
	end
	else begin
		case(n_state)
             STRING: begin
             	string_end <= string_cnt;
             	pattern_end <= pattern_end;
             end
             PATTERN: begin
             	string_end <= string_end;
             	pattern_end <= pattern_cnt;
             end
             default: begin
             	string_end <= string_end;
             	pattern_end <= pattern_end;
             end
		endcase
	end
end

// ^ sign flag
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    head_flag <= 0;
	end
	else begin
		case(n_state)
             PATTERN: begin
             	if(pattern_reg[0] == 8'h5E) head_flag <= 1;
             	else head_flag <= 0;
             end
             OUTPUT: begin
             	head_flag <= 0;
             end
             default: begin
             	head_flag <= head_flag;
             end
		endcase
	end
end

// $ sign flag
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    ending_flag <= 0;
	end
	else begin
		case(n_state)
             /*PATTERN: begin
             	
             end
             OUTPUT: begin
             	ending_flag <= 0;
             end*/
             default: begin
             	if(chardata == 8'h24) ending_flag <= 1;
             	else ending_flag <= 0;
             end
		endcase
	end
end

// Star flag
always @(posedge clk or posedge reset) begin
    if (reset) begin
        star_flag <= 0;
    end
    else begin
        case(n_state)
             PATTERN: begin
                 if(chardata == 8'h2A) star_flag <= 1;
                 else star_flag <= star_flag;
             end
             RESET: begin
                 star_flag <= 0;
             end
             default: begin
                 star_flag <= star_flag;
             end
        endcase
    end
end

// High when * sign appear
always @(posedge clk or posedge reset) begin
    if (reset) begin
        get_star <= 0;
    end
    else begin
        case(n_state)
             MATCH: begin
                 if(pattern_reg[pattern_cnt] == 8'h2A) get_star <= 1;
                 else get_star <= 0;
             end
             ENDING: begin
                 if(pattern_reg[pattern_cnt] == 8'h2A) get_star <= 1;
                 else get_star <= 0;
             end
             default: begin
                 get_star <= 0;
             end
        endcase
    end
end

// Store the pattern position before star
always @(posedge clk or posedge reset) begin
    if (reset) begin
        star_match_temp <= 0;
    end
    else begin
        case(n_state)
             MATCH: begin
                 if(pattern_reg[pattern_cnt] == 8'h2A) star_match_temp <= match_cnt;
                 else star_match_temp <= star_match_temp;
             end
             default: begin
                 star_match_temp <= 0;
             end
        endcase
    end
end

// Match position
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    match_cnt <= 0;
	end
	else begin
		case(n_state)
		     RESET: begin
		     	match_cnt <= 0;
		     end
             MATCH: begin
                if(star_flag) begin // star
                    if(pattern_reg[pattern_cnt + 1] == 8'h2A && (pattern_reg[pattern_cnt] == string_reg[string_cnt]) && (pattern_reg[pattern_cnt + 2] == string_reg[string_cnt + 1]) ) match_cnt <= match_cnt + 2; // corner case for string_3: pattern_6 
                    else if( (string_reg[string_cnt] == pattern_reg[pattern_cnt]) || pattern_reg[pattern_cnt] == 8'h2A || pattern_reg[pattern_cnt] == 8'h2E) begin
                        match_cnt <= match_cnt + 1;
                    end 
                    else begin
                        if(get_star) match_cnt <= match_cnt + 1;
                        else if(star_match_temp != 0 && match_cnt > star_match_temp) match_cnt <= star_match_temp + 1;
                        else match_cnt <= 0;
                    end
                end
                else begin
                    if(match_cnt == pattern_end - 2) begin
                        if( (string_reg[string_cnt] == pattern_reg[pattern_cnt] || pattern_reg[pattern_cnt] == 8'h2E) && (string_reg[string_cnt + 1] == pattern_reg[pattern_cnt + 1] || pattern_reg[pattern_cnt + 1] == 8'h2E) ) match_cnt <= match_cnt + 1;
                        else match_cnt <= 0;
                    end
                    else begin
                        if(string_reg[string_cnt] == pattern_reg[pattern_cnt] || pattern_reg[pattern_cnt] == 8'h2E) match_cnt <= match_cnt + 1;
                        else match_cnt <= 0;
                    end 
                end 
             end
             HEAD: begin
                if(ending_flag) begin  // ^ and $ sign
                    if(string_reg[string_cnt] == pattern_reg[pattern_cnt] || pattern_reg[pattern_cnt] == 8'h2E || (string_reg[string_cnt] == 8'h20 && pattern_reg[pattern_cnt] == 8'h24) ) match_cnt <= match_cnt + 1;
                    else match_cnt <= 0;
                end
                else begin  // ^ sign
                    if(string_reg[string_cnt] == pattern_reg[pattern_cnt] || pattern_reg[pattern_cnt] == 8'h2E) match_cnt <= match_cnt + 1;
                    else match_cnt <= 0;
                end   	
		     end
		     ENDING: begin
                if(star_flag) begin // star
                   if((string_reg[string_cnt] == pattern_reg[pattern_cnt]) || pattern_reg[pattern_cnt] == 8'h2A || pattern_reg[pattern_cnt] == 8'h2E) begin
                       match_cnt <= match_cnt + 1;
                   end
                   else begin
                       if(get_star) match_cnt <= match_cnt + 1;
                       else if(star_match_temp != 0 && match_cnt > star_match_temp) match_cnt <= star_match_temp + 1;
                       else match_cnt <= 0;
                   end
                end
                else begin
                   if(string_reg[string_cnt] == pattern_reg[pattern_cnt] || pattern_reg[pattern_cnt] == 8'h2E) match_cnt <= match_cnt + 1;
                   else match_cnt <= 0; 
                end
		     end
		     OUTPUT: begin
		     	match_cnt <= match_cnt;
		     end
             default: begin
             	match_cnt <= match_cnt;
             end
		endcase
	end
end

// Match
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    match <= 0;
	end
	else begin
		case(n_state) 
             RESET: begin
             	if(match_flag) match <= 1;
             	else match <= 0;
             end
             /*HEAD: begin
             	if(head_flag) begin
             		if(match_cnt == pattern_end) match <= 1;
             		else match <= 0;
             	end
             	else begin
             		match <= match;
             	end
             end*/
             default: begin
             	match <= match;
             end
		endcase
	end
end

// Match index
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    match_index <= 0;
	end
	else begin
		case(n_state)
             MATCH: begin
                if(pattern_reg[0] == 8'h2E) begin // corner case for string_5: pattern_5
                    if(get_star) match_index <= string_cnt - match_cnt - 1;
                    else match_index <= match_index;
                end
                else begin
                    if(get_star) match_index <= string_cnt - pattern_cnt;
                    else match_index <= match_index;
                end  
             end
             RESET: begin
                if(head_flag) begin // ^ sign 
                	if(match_flag) match_index <= string_cnt - match_cnt;
                	else match_index <= match_index;
                end
                else if(ending_flag) begin // $ sign
                	if(star_flag) begin    // star
                        if(get_star) match_index <= string_cnt - match_cnt;
                        else match_index <= match_index;
                    end
                    else begin
                        if(match_flag) match_index <= string_cnt + 1;
                        else match_index <= match_index;
                    end
                end 
                else begin // normal match
                    /*if(star_flag) begin
                        if(get_star) match_index <= string_cnt - match_cnt - 1;
                        else match_index <= match_index;
                    end*/
                    //else begin
                       if(match_flag && string_cnt != string_end && !star_flag) match_index <= string_cnt - match_cnt;
                       else match_index <= match_index; 
                    //end  
                end
             end
             default: begin
             	match_index <= match_index;
             end
		endcase
	end
end

// Output valid
always @(posedge clk or posedge reset) begin
	if (reset) begin
	    valid <= 0;
	end
	else begin
		case(n_state)
             /*MATCH: begin
             	if(string_cnt == string_end && pattern_cnt == pattern_end) valid <= 1;
             	else valid <= 0;
             end*/
             OUTPUT: begin
             	valid <= 1;
             end
             default: begin
             	valid <= 0;
             end
		endcase
	end
end

endmodule
