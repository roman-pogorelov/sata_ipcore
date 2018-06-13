// (C) 2001-2017 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


//
// Functions for embedded reconfiguration streamer block
//
// $Header$
//
// PACKAGE DECLARATION
`timescale 1 ps/1 ps

package alt_xcvr_native_rcfg_strm_functions;
	localparam integer MAX_CHARS = 40;
	localparam integer MAX_STRS = 16;
  localparam integer MAX_XCVR_CHANNELS = 64;
  localparam integer MAX_PRECISION = 32;


  /////////////////////////////////////////////////////////////////////////
	// convert frequency string into integer Hz.  Fractional Hz are truncated
	// Must remain a constant function - can't use string.atoi().
	function time str2hz (
		input [8*MAX_CHARS:1] s
	);

		integer i;
		integer c; // temp char storage for frequency conversion
		integer unit_tens; // assume already Hz
		integer is_numeric;
		integer saw_dot;
		
		reg [8:1] c_dot; // = ".";
		reg [8:1] c_space; // = " ";
		reg [8:1] c_a; // = 8'h61; //"a";
		reg [8:1] c_z; // = 8'h7a; //"z";
		reg [8*4:1] s_unit;
                reg [8*MAX_CHARS:1] s_shift;
		
		begin
			// frequency ratio calculations
			str2hz = 0;
			unit_tens = 0; // assume already Hz
			is_numeric = 1;
			saw_dot = 0;
			s_unit = "";
			
			// Modelsim optimizer bug forces us to initialize these non-statically
			c_dot = ".";
			c_space = " ";
			c_a = "a";
			c_z = "z";
			for (i=(MAX_CHARS-1); i>=0; i=i-1) begin
                                s_shift = (s >> (i*8));
				c = s_shift[8:1] & 8'hff;
				if (c > 0) begin
					//$display("[%d] => '%1s',", i, c);
					if (c >= 8'h30 && c <= 8'h39 && is_numeric) begin
						str2hz = (str2hz * 10) + (c & 8'h0f);
						if (saw_dot) unit_tens = unit_tens - 1;  // count digits after decimal point
					end else if (c == c_dot) saw_dot = 1;
					else if (c != c_space) begin
						is_numeric = 0;	// stop accepting new numeric digits in value
						// if it's a-z, convert to upper case A-Z
						if (c >= c_a && c <= c_z) c = (c & 8'h5f);	// convert a-z (lower) to A-Z (upper)
						s_unit = (s_unit << 8) | c;
					end
				end
			end
			//$display("numeric = %d x 10**(%2d), unit = '%0s'", str2hz, unit_tens, s_unit);
			
			// account for frequency unit
			if (s_unit == "GHZ" || s_unit == "GBPS") unit_tens = unit_tens + 9; // 10**9
			else if (s_unit == "MHZ" || s_unit == "MBPS") unit_tens = unit_tens + 6; // 10**6
			else if (s_unit == "KHZ" || s_unit == "KBPS") unit_tens = unit_tens + 3; // 10**3
			else if (s_unit != "HZ" && s_unit != "BPS") begin
				$display("Invalid frequency unit '%0s', assuming %d x 10**(%2d) 'Hz'", s_unit, str2hz, unit_tens);
			end
			//$display("numeric in Hz = %d x 10**(%2d)", str2hz, unit_tens);

			// align numeric to Hz
			if (unit_tens < 0) begin
				//str2hz = str2hz / (10**(-unit_tens));
				for (i=0; i>unit_tens; i=i-1) begin
					str2hz = str2hz / 10;
				end
			end else begin
				//str2hz = str2hz * (10**unit_tens);
				for (i=0; i<unit_tens; i=i+1) begin
					str2hz = str2hz * 10;
				end
			end
			//$display("%d Hz", str2hz);
		end
	endfunction


  /////////////////////////////////////////////////////////////////////////////
  // Convert a string to an integer
  // Uses pre-existing str2hz function
  function integer str2int(
    input [MAX_CHARS*8-1:0] instring
  );
    time temp;
    temp = str2hz({instring,"Hz"});
    str2int = temp[31:0];
  endfunction


  //////////////////////////////////////////////////////////////////////////
  // Accepts a comma separated list of string values and returns the element
  // found at the specified index. If the index is invalid, "NA" is returned
  //
  // @param index - The index of the value to return within "set"
  // @param set - A comma separated list of string values. The entire list may
  //            be surrounded by parenthesis("(item0,item1,item2)")
  function [MAX_CHARS*8-1:0] get_value_at_index(
    input integer index,
    input [MAX_STRS*MAX_CHARS*8-1:0] set
  );
    // check value against each in set
	  integer close_pos;	// end of string marker can be comma or closing paren
		integer open_pos;	// open paren is start of set, if appropriate
		reg [MAX_STRS*MAX_CHARS*8-1:0] legalstr;
    integer cur_index;
			
    get_value_at_index = "";
    legalstr = "NA";
    cur_index = 0;
	  open_pos = MAX_STRS*MAX_CHARS-1;
    // Remove closing parenthesis if exists
    if(set[7:0] == 8'h29) begin
      set = (set >> 8);
      set[(MAX_STRS*MAX_CHARS*8-1)-:8] = 8'h00;
    end
    // Find the start of the string
	  while (open_pos >= 1 && (set[open_pos*8 +: 8] == 8'h00 || set[open_pos*8 +: 8] == 8'h28)) // look for first non-null
				open_pos = open_pos - 1;

    // Iterate through list until the string is found or we've reached the end of the list
	  while (legalstr == "NA" && open_pos >= 0 && cur_index <= index) begin
	    close_pos = open_pos;
      // Move the close iterator to the end of the current value (or end of string)
			while (close_pos > 0
					&& set[close_pos*8 +: 8] != 8'h2c) // look for comma (8'h2c)
			  close_pos = close_pos - 1;
			if (close_pos >= 0) begin
          close_pos = close_pos == 0 ? 0 : close_pos + 1;
          if(index == cur_index) begin 
				    legalstr = ((set & ((1'b1 << open_pos*8+8)-1)) >> close_pos*8);
				  end
				  open_pos = close_pos-2;  // prepare to look for next legal string
      end
      cur_index = cur_index + 1;
		end

    cur_index = 0;
    while(legalstr[cur_index*8+:8] != 0) begin
      get_value_at_index[cur_index*8+:8] = legalstr[cur_index*8+:8];
      cur_index = cur_index + 1;
    end
    
		//$display("is_in_legal_set(): returns %d", is_in_legal_set);
	endfunction


  ///////////////////////////////////////////////////////////////////////////////////////////
  // Accepts a comma separated list of positive string values and returns the element
  // with the maximum value. Returns 0 if the max value is negative or count is not positive.
  //
  // @param count - The number of elements in the list. Must be a positive number.
  // @param set - A comma separated list of string values. The entire list may
  //            be surrounded by parenthesis("(item0,item1,item2)")
	function integer get_max_value(
		input integer count,
		input [MAX_STRS*MAX_CHARS*8-1:0] set
	);
		get_max_value = 0;
		for(integer i = 0; i < count; i = i + 1)begin
			integer temp;
			temp = str2int(get_value_at_index(i,set));
			if(temp > get_max_value) get_max_value = temp;
		end
	endfunction


  /////////////////////////////////////////////////////////////////////////////////////////
	// Accepts a comma separated list of numbers in string format and returns the sum
	//
	// @param count - The number of elements in the list. Must be a non-negative.
	// @param set - A comma separated list of numbers in string format. The entire list may
	//            be surrounded by parenthesis("(item0,item1,item2)")
	function integer get_sum(
		input integer count,
		input [MAX_STRS*MAX_CHARS*8-1:0] set
	);
		get_sum = 0;
		for(integer i = 0; i < count; i = i + 1)begin
			get_sum = get_sum + str2int(get_value_at_index(i,set));
		end
	endfunction
   
endpackage
