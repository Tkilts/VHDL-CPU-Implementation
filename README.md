This project demonstrates the functionality of a CPU using Finite State Machines to achieve different funcitonalities such as an ADDER, SUBTRACTOR, MULTIPLER, and Pseudo Random Number Generator.

The Procram file handles Ram and Rom memory management, acting as the memory unit of the CPU.

The Disp4 file handles a 7 segment 4 digit display used to demonstrate the CPU is working.

The CPU file fetches instructions, and reads and writes to/from the Ram and Rom in the Procram file. 

The CPU TOP file is used to connect all the files and allow them to properly interact.

The CPU_TOP_TB file is a testbench used to demonstrate the functioning CPU.

All these files were used together in vivado to develop a simple functioning CPU, using FSMs and OPCODES to navigate through the program to utilize different functions. 
