# Simple processor using VHDL

## Design
The project follows this design:

<img src="https://user-images.githubusercontent.com/71709842/152693528-6754b696-e462-4785-903a-ed6edad768ec.png" alt="drawing" width="500"/>

with a few modifications:
- instruction format is IIXXYY (instruction number, register XX, register YY)
- there are only 4 general-purpose registers


## Instructions
This processor implementation can interpret 4 different instructions:
- move    (00XXYY) - move the value of a register YY to XX
- move in (01XXYY) - move the value of the input to the register XX
- add     (10XXYY) - add the value of register YY to XX and store in XX
- sub     (11XXYY) - subtract the value of register YY from XX and store in XX


## Contents of the repository
- file 'test_cpu.circ' contains implementation of the processor in logisim
- folder 'proc' contains the processor component in a quartus project (including VHDL file)
- folder 'fpgaproc' contains the implementation designed to work on Altera Cyclone II FPGA
