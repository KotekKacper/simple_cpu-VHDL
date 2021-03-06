LIBRARY ieee; USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY fpgaproc IS
	PORT (	SW : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
				KEY : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
				LEDR : OUT STD_LOGIC_VECTOR(17 DOWNTO 0));
END fpgaproc;

ARCHITECTURE Behavior OF fpgaproc IS
	COMPONENT proc
		PORT (	DIN : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				Resetn, Clock, Run : IN STD_LOGIC;
				Done : BUFFER STD_LOGIC;
				BusWires : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0));
	END COMPONENT;

BEGIN	
	pr : proc PORT MAP (SW(15 DOWNTO 0), KEY(0), KEY(1), SW(17), LEDR(17), LEDR(15 DOWNTO 0));
	
END Behavior;
