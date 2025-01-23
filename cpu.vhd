----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/20/2024 10:54:57 PM
-- Design Name: 
-- Module Name: cpu - fsm
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity cpu is
  port( clk      : in  std_logic;
        reset    : in  std_logic;
        wr_en    : out  std_logic;
        dr       : in  std_logic_vector( 7 downto 0); -- Data from the memory (read)
        dw       : out std_logic_vector( 7 downto 0); -- Data to the memory (write)
        addr     : out std_logic_vector( 7 downto 0); -- Memory address
        pc_out   : out std_logic_vector( 7 downto 0); -- Program counter value
        accu_out : out std_logic_vector( 7 downto 0)  -- Accumulator value
        );
end cpu;

architecture fsm of cpu is

  --   op-codes
  constant LDA : std_logic_vector( 3 downto 0) := "0001";
  constant STA : std_logic_vector( 3 downto 0) := "0010";
  constant ADD : std_logic_vector( 3 downto 0) := "0011";
  constant JNC : std_logic_vector( 3 downto 0) := "0100";
  constant JMP : std_logic_vector( 3 downto 0) := "0101";
  constant SUB : std_logic_Vector( 3 downto 0) := "0110";
  constant S_LEFT : std_logic_vector( 3 downto 0) := "0111";
  constant S_RIGHT : std_logic_Vector( 3 downto 0) := "1000";
  constant MUL : std_logic_Vector( 3 downto 0) := "1001";
  constant PRNG : std_logic_vector( 3 downto 0) := "1010";
  constant JSR : std_logic_vector( 3 downto 0) := "1011";

  constant one : std_logic_vector( 7 downto 0) := "00000001";


  -- CPU registers
  signal accu    : std_logic_vector( 7 downto 0) := "00000000" ; -- Accumulator
  signal op_code : std_logic_vector( 3 downto 0) := "0000" ;     -- Current op-code
  signal pc      : std_logic_vector( 7 downto 0) := "00000000" ; -- Program counter

  -- Signals required
  signal accu_temp : std_logic_vector( 7 downto 0); --Temporoary accumulator for operand
  signal temp_result : std_logic_vector( 8 downto 0); --Temporary result for addition
  signal carry : std_logic; --Carry flag
  signal return_addr : std_logic_vector( 7 downto 0); --Hold for return address in JSR
  signal return_flag : std_logic;
  signal prng_seed : std_logic_vector( 7 downto 0); --Hold for seed for prng, this should never = x'00'
  signal mult_result : std_logic_vector ( 15 downto 0); --Store large results from multiplication, only half will be shown at once
  
    --   FSM states
  type state_t is ( load_opcode, LDA_1, STA_1, STA_2, ADD_1, ADD_2, ADD_3, ADD_4, JMP_1, JNC_1,
                    SUB_1, SUB_2, SUB_3, SUB_4, S_LEFT_1, S_LEFT_2, S_LEFT_3, S_RIGHT_1, S_RIGHT_2, S_RIGHT_3,
                    MUL_1, MUL_2, MUL_3, MUL_4, MUL_5, PRNG_1, PRNG_2, JSR_1, JSR_2, JSR_3); -- List of states in the CPU FSM

  -- Signals used for debugging
  signal state_watch : state_t;
  
begin  --  fsm 

  -- Accumulator and program counter value outputs
  accu_out <= accu;
  pc_out <= pc;
  
  fsm_proc : process ( clk, reset)

    variable state   : state_t := load_opcode;
    variable prng_temp : STD_LOGIC := '0'; --Used for LFSR PRNG
    variable shift_amount : std_logic_vector( 7 downto 0); --Used for L and R shift input
    
  begin  --  process fsm_proc 

    if ( reset = '1') then  -- Asynchronous reset

      --   output and variable initialisation
      wr_en    <= '0';
      dw       <= ( others => '0');
      addr     <= ( others => '0');
      op_code  <= ( others => '0');
      accu     <= ( others => '0');
      pc       <= ( others => '0');

      state := load_opcode;

    elsif rising_edge( clk) then  -- Synchronous FSM

      state_watch <= state;

      case state is
        when load_opcode =>
          op_code <= dr(3 downto 0); -- Load the op-code
          pc      <= pc + one;        -- Increment the program counter
          addr    <= pc + one;        -- Memory address pointed to PC
          -- Op-code determines the next state:
          case dr (3 downto 0) is
            when LDA => state := LDA_1;
            when STA => state := STA_1;
            when ADD => state := ADD_1;
            when JMP => state := JMP_1;
            when JNC => state := JNC_1;
            when SUB => state := SUB_1;
            when S_LEFT => state := S_LEFT_1;
            when S_RIGHT => state := S_RIGHT_1;
            when MUL => state := MUL_1;
            when PRNG => state := PRNG_1;
            when JSR => state := JSR_1;
            
            when others => state := load_opcode;
          end case; -- opcode decoder

        -- Op-code behaviors here:
          
        when LDA_1 =>           -- Load accumulator from memory address
          accu    <= dr; 
          pc      <= pc + one;
          addr    <= pc + one;
          if (return_flag = '1') then
            state := JSR_3;
          else
            state := load_opcode;
          end if;
          
        when STA_1 => -- Store accumulator to memory address
          dw <= accu;  -- Store accumulator value to memory data output
          addr <= dr; -- Memory address to write data
          wr_en <= '1';  -- Enable memory write
          state := STA_2; --Transition to next state required for store
        when STA_2 => --Increment program counter, fix address
          pc <= pc + one;  -- Increment the program counter
          addr <= pc + one;
          wr_en <= '0';
          if (return_flag = '1') then
            state := JSR_3;
          else
            state := load_opcode;
          end if;

        when ADD_1 => --Read value from memory at addr
          wr_en <= '0'; --Memory read
          addr <= dr; --Memory address to read data
          state := ADD_2; --Transisition to next state required for addition
        when ADD_2 => --Put data in temp reg
          accu_temp <= dr; --Load temp accumulator from memory address
          state := ADD_3; --Transistion to next state required for addition
        when ADD_3 => --Compute sum
          temp_result <= ('0'&accu) + (accu_temp); --Extend to 9 bits and add
          state := ADD_4;
        when ADD_4 =>  --Move sum to accumulator
          accu <= temp_result(7 downto 0); --Put 8 least sig bits into accumulator
          carry <= temp_result(8); --Get carry flag
          pc <= pc + one;   --Increment program counter
          addr <= pc + one;
          if (return_flag = '1') then
            state := JSR_3;
          else
            state := load_opcode;
          end if;
              
        when JMP_1 =>
          addr <= dr;  --Jump to given address
          pc <= dr; --Match program counter
          state := load_opcode;  -- Transition back to loading opcode
          --JSR omitted, never JSR to JMP
          
        when JNC_1 => 
          if carry = '0' then  -- Check if carry flag is not set
            --Load the address to jump to from the memory
            addr <= dr;  -- Update the program counter with the new address
            pc <= dr;
          else
            pc <= pc + one;
            addr <= pc + one;
          end if;
          state := load_opcode;  -- Transition back to loading opcode
          --JSR omitted, never JSR to JNC
        
        when SUB_1 => --Read value from memory at addr
          wr_en <= '0'; --Memory read
          addr <= dr; --Memory address to read data
          state := SUB_2;
        when SUB_2 => --Get value to subtract 
          accu_temp <= dr; --Load temp accumulator with data from addr
          state := SUB_3;
        when SUB_3 => --Compute subtraction
          temp_result <= ('0' & accu) + not('0' & accu_temp) + (one); --2's complement addition for subtraction
          STATE := SUB_4;
        when SUB_4 => --Move result to the accumulator
          accu <= temp_result(7 downto 0);
          carry <= temp_result(8);
          pc <= pc + one;
          addr <= pc + one;
          if (return_flag = '1') then
            state := JSR_3;
          else
            state := load_opcode;
          end if;
          
        when S_LEFT_1 =>
          wr_en <= '0'; --No writing necessary
          shift_amount := dr;
          state := S_LEFT_2;
        when S_LEFT_2 => --Shifting state
          if (shift_amount >= one) then --If a shift is required
            accu <= accu(6 downto 0)&'0'; --Perform left shift, append 0
            shift_amount := shift_amount - one; --Decrement shift amount
          end if;
          state := S_LEFT_3; --Transition to check state
        when S_LEFT_3 =>
          if (shift_amount >= one) then --Check if shift is required
            state := S_LEFT_2; --Go back to shift state if more shift is required
          else --If no more shift
            pc <= pc + one; --Proceed
            addr <= pc + one;
            if (return_flag = '1') then
               state := JSR_3;
            else
               state := load_opcode;
            end if;   
          end if;
        
        when S_RIGHT_1 =>
          wr_en <= '0'; --No writing necessary
          shift_amount := dr;
          state := S_RIGHT_2;
        when S_RIGHT_2 => --Shift state
          if (shift_amount >= one) then --If a shift is required
            accu <= '0'&accu(7 downto 1); --Perform right shift, append 0
            shift_amount := shift_amount - one; --Decrement shift amount
          end if;
          state := S_RIGHT_3;
        when S_RIGHT_3 =>
          if (shift_amount >= 1) then
            state := S_RIGHT_2;
          else
            pc <= pc + one;
            addr <= pc + one;
            if (return_flag = '1') then
                state := JSR_3;
            else
                state := load_opcode;
            end if;
          end if;
        
        when MUL_1 =>
          wr_en <= '0'; --Memory read
          addr <= dr; --Memory address to read data
          state := MUL_2; --Transisition to next state required for multiplication
        when MUL_2 => --Put data in temp reg
          accu_temp <= dr; --Load temp accumulator from memory address
          state := MUL_3; --Transistion to next state required
        when MUL_3 => --Compute Multiplication
          mult_result <= accu * accu_temp; --Need to change to structural method
          state := MUL_4;
        when MUL_4 =>  --Move 8 MSB to accumulator
          accu <= mult_result(15 downto 8); --Put 8 most sig bits into accumulator
          state := MUL_5;
        when MUL_5 => --Move 8 LSB to accumulator
          accu <= mult_result(7 downto 0); --Put 8 least sig bits into accumulator
          pc <= pc + one;   --Increment program counter
          addr <= pc + one;
          if (return_flag = '1') then
            state := JSR_3;
          else
            state := load_opcode;
          end if;
        
        
        when PRNG_1 =>
          wr_en <= '0'; --No writing necessary
          prng_seed <= dr; --User input will be the seed
          state := PRNG_2;
        when PRNG_2 =>
          prng_temp := prng_seed(4) XOR prng_seed(3) XOR prng_seed(2) XOR prng_seed(1); --Generate PRN using LFSR method found online
          accu <= prng_temp & prng_seed( 7 downto 1); --Generate PRN using LFSR method found online;
          pc <= pc + one;
          addr <= pc + one;
          if (return_flag = '1') then
            state := JSR_3;
          else
            state := load_opcode;
          end if;
          
          
        when JSR_1 =>
          wr_en <= '0'; --No writing necessary
          return_addr <= pc; --Store current location
          return_flag <= '1'; --Signal to other routines to return to return_addr, not load_opcode;
          state := JSR_2;
        when JSR_2 =>
          addr <= dr; --Jump to given address
          pc <= dr; --Match program counter
          state := load_opcode; --Fulfill sub-routine
        when JSR_3 => --Return here after sub-routine
          return_flag <= '0'; --Return has been completed
          addr <= return_addr + one; --Go to next step from jump
          pc <= return_addr + one;
          state := load_opcode;
          
           
          when others =>
            null;
      end case;  --  state

    end if; -- rising_edge(clk)

  end process fsm_proc;
end fsm;
