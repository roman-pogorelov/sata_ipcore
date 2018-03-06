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


// Revision 2.0
package pcie_mgmt_functions_h;

`define f_set_rom prog_rom[rom_i]=
`define f_inc_rom rom_i=rom_i+1

import pcie_mgmt_commands_h::*;

localparam  MAX_LABEL = 512;
localparam  MAX_DEPTH = 4096;

// These should be synthesized away
integer             rom_labels[0:(MAX_LABEL-1)];
reg [ROM_WIDTH-1:0] prog_rom  [0:(MAX_DEPTH-1)]; // Command storage ROM
integer             rom_i;
integer             clocks_per_second;  // Must be set from outside


task set_clocks_per_second;
  input integer new_clocks_per_second;
  begin
    clocks_per_second = new_clocks_per_second;
  end
endtask


task f_noop;
  begin
    `f_set_rom sleep(0);
    `f_inc_rom;
  end
endtask

// Halt function
// Required as last instruction in ROM. Instructs the command
// processor to halt execution indefinitely.
//
// @param unused - An unused but required value.
task f_halt;
  begin
    `f_set_rom halt(0);
    `f_inc_rom;
  end
endtask

// Sleep function
// Pauses execution for the number of clock cycles specified
// by the parameter "ticks"
//
// @param ticks - The number of clock cycles to sleep
task f_sleep;
  input [WAIT_SIZE-1:0] ticks;
  begin
    `f_set_rom sleep(ticks);
    `f_inc_rom;
  end
endtask

task f_convert_ctle;
  begin
    `f_set_rom convert_ctle(0);
    `f_inc_rom;
  end
endtask

task f_add_to_reg;
  input [REG_SIZE-1:0] value;
  begin
    `f_set_rom add_to_reg(value);
    `f_inc_rom;
  end
endtask

task f_mod_mem_value;
  input [REG_SIZE-1:0] mask;
  begin
    `f_set_rom modify_reg_from_mem_address(mask);
    `f_inc_rom;
  end
endtask

task f_sub_from_reg;
  input [REG_SIZE-1:0] value;
  begin
    `f_set_rom sub_from_reg(value);
    `f_inc_rom;
  end
endtask

task f_inc_mem_address;
  begin
    `f_set_rom inc_mem_address(0);
    `f_inc_rom;
  end
endtask

task f_load_mem_address;
  begin
    `f_set_rom load_mem_addr_to_reg(0);
    `f_inc_rom;
  end
endtask

task f_store_mem_address;
  begin
    `f_set_rom store_reg_to_mem_addr(0);
    `f_inc_rom;
  end
endtask

task f_st_reg_to_address;
  begin
    `f_set_rom wr_to_mem_address(0);
    `f_inc_rom;
  end
endtask

task f_ld_address_to_reg;
  begin
    `f_set_rom rd_from_mem_address(0);
    `f_inc_rom;
  end
endtask

// Micro-sleep function
// Pauses execution for the number of microseconds specified
// by the parameter "usecs"
//
// @param usecs - The number of microseconds to sleep.
task f_usleep;
  input integer usecs;
  reg [WAIT_SIZE-1:0] ticks;
  begin
    ticks = (clocks_per_second / 1000000) * usecs;
    f_sleep(ticks);
  end
endtask


// Load the internal result register with the value
// specified.
//
// @param datain - The value to be loaded to the internal result
//                register
task f_load_result;
  input [REG_SIZE-1:0]  datain;
  begin
    `f_set_rom load_result(datain);
    `f_inc_rom;
  end
endtask

// Write result to register function
// Writes the data stored in the internal result register to the
// register specified by the parameter "address".
//
// @param address - Address of the register to write
task f_write_result_to_reg;
  input [REG_SIZE-1:0]  address;
  begin
    `f_set_rom load_address(address);
    `f_inc_rom;
    `f_set_rom write_reg(0);
    `f_inc_rom;
  end
endtask


// Write register function
// Writes the data specified by the parameter "writedata" to the
// register specified by the parameter "address". First stores
// the writedata in the internal result register then writes it
// to the the specified address.
//
// @param address - Address of the register to write
// @param writedata - Data to be written to register
task f_write_reg;
  input [REG_SIZE-1:0]      address;
  input [REG_VAL_SIZE-1:0]  writedata;
  begin
    f_load_result(writedata);
    f_write_result_to_reg(address);
  end
endtask


//Modifies the value of the results register with the value of the
//you with to write to the address.  Specify two values.  The first
//is used to mask the data register, and the second is the data value
//itself.  A 1 in the mask specifies that bit to be written from the data
//value.  A 0 in the mask specifies that bit to be igrored. ie recycled.
//
//@param mask_data - 32-bit mask for RMW
//@param modify_data - 32-bt data value for the register
//
//Use: f_modify_reg(mask_data, modify_data);
task f_modify_reg;
  input [REG_VAL_SIZE-1:0]  mask_data;
  input [REG_VAL_SIZE-1:0]  modify_data;
  begin
    `f_set_rom mask_reg(mask_data);
    `f_inc_rom;
    `f_set_rom modify_reg(modify_data);
    `f_inc_rom;
  end
endtask


// Read register function
// Reads data from the register specified by the parameter "address"
// and stores the value in the internal result register.
//
// @param address - Address of the register to read
task f_read_reg;
  input [REG_SIZE-1:0]  address;
  begin
    `f_set_rom load_address(address);
    `f_inc_rom;
    `f_set_rom read_reg(0);
    `f_inc_rom;
  end
endtask

// Read register bit function
// Reads data from the register specified by the parameter "address"
// and stores the value of the bit within the register specified by
// the parameter "bit_index" in the internal result register.
//
// @param address - Address of the register to read
// @param bit_index - Index of the bit within the register to read
task f_read_reg_bit;
  input [REG_SIZE-1:0]        address;
  input [BIT_INDEX_SIZE-1:0]  bit_index;
  begin
    `f_set_rom load_address(address);
    `f_inc_rom;
    `f_set_rom read_reg_bit(bit_index);
    `f_inc_rom;
  end
endtask


// Wait for register function
// Continuously reads data from the register specified by the parameter
// "address" and waits until the register's value equals the value
// specified by parameter "expected_data" before continuing execution.
// The value of the register is stored in the internal result register.
//
// @param address - Address of the register to read (and wait for)
// @param expected_data - Value to wait for the register to equal.
task f_wait_for_reg;
  input [REG_SIZE-1:0]      address;
  input [REG_VAL_SIZE-1:0]  expected_data;
  begin
    `f_set_rom load_address(address);
    `f_inc_rom;
    `f_set_rom wait_for_reg(expected_data);
    `f_inc_rom;
  end
endtask

// Wait for register bit function
// Continuously reads data from the register specified by the parameter
// "address" and waits until the value of the bit specified by "bit_index"
// equals the value specified by the parameter "expected_data" (0 or 1).
//
// @param address - Address of the register to read (and wait for).
// @param bit_index - Index of the bit within the register to read.
task f_wait_for_reg_bit;
  input [REG_SIZE-1:0]        address;
  input [BIT_INDEX_SIZE-1:0]  bit_index;
  input [REG_VAL_SIZE-1:0]    expected_data;
  begin
    `f_set_rom load_address(address);
    `f_inc_rom;
    `f_set_rom wait_for_reg_bit(bit_index, expected_data);
    `f_inc_rom;
  end
endtask


// Write bit from result register to PIO output bit
// Reads a bit specified by the parameter "result_bit_index" within the
// internal result register and writes the value to the PIO output port bit
// specified by the parameter "pio_bit_index".
//
// @param result_bit_index - Index of the bit within the internal result
// register.
// @param pio_bit_index - Index of the bit within the PIO output port to write
// to.
task f_write_result_bit_to_pio_bit;
  input [BIT_INDEX_SIZE-1:0]  result_bit_index;
  input [BIT_INDEX_SIZE-1:0]  pio_bit_index;
  begin
    `f_set_rom write_result_bit_to_pio_bit(result_bit_index, pio_bit_index);
    `f_inc_rom;
  end
endtask


// Write PIO bit function
// Writes the value specified by the parameter "bit_value" (0 or 1) to
// the PIO output bit specified by the parameter "bit_index". First
// writes the value to the internal result register then writes it to the
// PIO.
//
// @param bit_index - The bit within the PIO output port to write to.
// @param bit_value - The value to write to the PIO output bit.
task f_write_pio_bit;
  input [BIT_INDEX_SIZE-1:0]  bit_index;
  input [BIT_VAL_SIZE-1:0]    bit_value;
  begin
    f_load_result(bit_value);
    f_write_result_bit_to_pio_bit(0, bit_index);
  end
endtask


// Read PIO bit function
// Reads a bit from the PIO input port and stores the value (0 or 1) into the
// internal result register.
//
// @param bit_index - Index of bit within the PIO input port to read.
task f_read_pio_bit;
  input [BIT_INDEX_SIZE-1:0]  bit_index;
  begin
    `f_set_rom read_pio_bit(bit_index);
    `f_inc_rom;
  end
endtask

//  Wait for PIO bit function
//  Continuously reads the value of the bit specified by the parameter
//  "bit_index" within the PIO input port and waits for the value of the
//  bit to be equal to the value specified by the parameter
//  "expected_bit_value" before continuing execution.
//
//  @param bit_index - Index of bit within the PIO input port to read.
//  @param expected_bit_value - Expected value of the bit on the PIO
//  input port
task f_wait_for_pio_bit;
  input [BIT_INDEX_SIZE-1:0]  bit_index;
  input [BIT_VAL_SIZE-1:0]    expected_bit_value;
  begin
    `f_set_rom wait_for_pio_bit(bit_index, expected_bit_value);
    `f_inc_rom;
  end
endtask

// Compare result function
// Compares the contents of the internal result register to the value
// specified by the parameter "compare_value". Stores the result (1 for
// no-match, 0 for match) in the internal result register.
//
// @param compare_value. The value to compare with the internal result
// register.
task f_compare_result;
  input [CMP_VAL_SIZE-1:0]  compare_value;
  begin
    `f_set_rom compare_result(compare_value);
    `f_inc_rom;
  end
endtask


// Set a label which can be subsequently jumped to.
//
// @param label - The integer label to assign as an identifier.
task f_label;
  input integer label;
  begin
    if(rom_labels[label] != -1)
      $display("[f_label] ERROR - Duplicate label %0d! at address %0d", label, rom_i);
    else if(label < MAX_LABEL && label >= 0)
      rom_labels[label] = rom_i;
    else
      $display("[f_label] ERROR - Invalid label: %0d!, must be between 0<=MAX_LABEL", label);
  end
endtask

// jump-not-equal-zero instruction
// Compares the contents of the internal result register to 0. If the
// contents are 0, program execution continues, otherwise the program
// jumps to the indicated label which was set by a previous set_label command
task f_jump_not_equal_zero;
  input integer label;
  begin
    if(label > MAX_LABEL || label < 0)
      $display("[mgmt_master] ERROR - Invalid jump label %0d!, must be between 0<=MAX_LABEL", label);
    begin
      `f_set_rom jump_not_equal_zero(label);
      `f_inc_rom;
    end
  end
endtask


task pre_process;
  begin
    // Initialize ROM with HALT instructions
    for(rom_i=0;rom_i<MAX_DEPTH;rom_i=rom_i+1) begin
      prog_rom[rom_i] = halt(0);
    end
    // Initialize ROM labels (0 is an invalid address)
    for(rom_i=0;rom_i<MAX_LABEL;rom_i=rom_i+1) begin
      rom_labels[rom_i] = -1;
    end

    rom_i = 0;
    f_noop();         // First instruction is a NOOP
  end
endtask

// The post process task resolves code labels and jump instructions
task post_process;
  integer label;
  begin
    for(rom_i=0;rom_i<MAX_DEPTH;rom_i=rom_i+1) begin
      label = prog_rom[rom_i][REG_VAL_OFST+:REG_VAL_SIZE];
      if(prog_rom[rom_i][CMD_OFST+:CMD_SIZE] == CMD_JNEZ) begin
        if(rom_labels[label] == -1) begin
          $display("[post_process] ERROR - Invalid jump label %0d at address %0d. Label not initialized!", label, rom_i);
        end else begin
          `f_set_rom jump_not_equal_zero(rom_labels[label]);
        end
      end
    end
  end
endtask

`undef f_set_rom
`undef f_inc_rom

endpackage
