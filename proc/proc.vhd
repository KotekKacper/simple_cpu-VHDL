LIBRARY ieee; USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY proc IS
	PORT (	DIN : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				Resetn, Clock, Run : IN STD_LOGIC;
				Done : BUFFER STD_LOGIC;
				BusWires : BUFFER STD_LOGIC_VECTOR(15 DOWNTO 0));
END proc;

ARCHITECTURE Behavior OF proc IS
	-- declare components
	COMPONENT upcount
		PORT (	Clear, Clock : IN STD_LOGIC;
					Q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT dec2to4
		PORT (	SIGNAL	W:  IN  std_logic_vector(1 DOWNTO 0);
					SIGNAL	EN:  IN  std_logic;
					SIGNAL 	Y:  OUT std_logic_vector(3 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT regn
		GENERIC (n : INTEGER := 16);
		PORT (	R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
					Rin, Clock : IN STD_LOGIC;
					Q : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT reg6
		GENERIC (n : INTEGER := 6);
		PORT (	R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
					Rin, Clock : IN STD_LOGIC;
					Q : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT mux3bit8to1  
   PORT ( S: IN STD_LOGIC_VECTOR(5 DOWNTO 0);
				U0, U1, U2, U3, U4, U5: IN     STD_LOGIC_VECTOR(15 DOWNTO 0);  
				M                   : BUFFER    STD_LOGIC_VECTOR(15 DOWNTO 0));  
	END COMPONENT;
	
	COMPONENT ALU IS
   PORT(X			: IN  std_logic_vector(15 DOWNTO 0);
        Y			: IN  std_logic_vector(15 DOWNTO 0);
        operation : IN  std_logic;
        result    : OUT std_logic_vector (15 DOWNTO 0));        
	END COMPONENT;

	
	-- declare signals
		-- to control unit
		SIGNAL Tstep_Q : STD_LOGIC_VECTOR(1 DOWNTO 0);
		SIGNAL IR : STD_LOGIC_VECTOR(0 TO 5);
		SIGNAL I: STD_LOGIC_VECTOR(0 TO 1);
		SIGNAL Xreg: STD_LOGIC_VECTOR(0 TO 3);
		SIGNAL Yreg: STD_LOGIC_VECTOR(0 TO 3);
		-- from control unit
		SIGNAL Clear: STD_LOGIC;
		SIGNAL IRin: STD_LOGIC;
		SIGNAL Rout: STD_LOGIC_VECTOR(3 DOWNTO 0);
		SIGNAL Gout: STD_LOGIC;
		SIGNAL DINout: STD_LOGIC;
		SIGNAL Rin: STD_LOGIC_VECTOR(3 DOWNTO 0);
		SIGNAL Ain: STD_LOGIC;
		SIGNAL AddSubTrigger: STD_LOGIC;
		SIGNAL Gin: STD_LOGIC;
	SIGNAL BUSsig: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL R0: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL R1: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL R2: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL R3: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL A: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL G: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL AddSub: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL High: STD_LOGIC;


BEGIN
	High <= '1';
	Tstep: upcount PORT MAP (Clear, Clock, Tstep_Q);
	IReg: reg6 PORT MAP (DIN(5 DOWNTO 0), IRin, Clock, IR);
	I <= IR(0 TO 1);
	decX: dec2to4 PORT MAP (IR(2 TO 3), High, Xreg);
	decY: dec2to4 PORT MAP (IR(4 TO 5), High, Yreg);

	mux: mux3bit8to1 PORT MAP (Rout & DINout & Gout, R3, R2, R1, R0, DIN, G, Bussig);
	--BusWires <= Rout & DINout & Gout & "0000000000";
	
	controlsignals: PROCESS (Tstep_Q, I, Xreg, Yreg)
	BEGIN
		-- specify initial values
		Clear <= '0';
		Done <= '0';
		Rin <= "0000";
		Rout <= "0000";
		DINout <= '0';
		Gout <= '0';
		AddSubTrigger <= '0';
		CASE Tstep_Q IS
			WHEN "00" => -- store DIN in IR as long as Tstep_Q = 0
				IRin <= '1';
			WHEN "01" => -- define signals in time step T1
				IRin <= '0';
				CASE I IS
					WHEN "00" =>
						Rout <= Yreg;
						Rin <= Xreg;
						Done <= '1';
						Clear <= '1';
					WHEN "01" =>
						DINout <= '1';
						Rin <= Xreg;
						Done <= '1';
						Clear <= '1';
					WHEN "10" =>
						Rout <= Xreg;
						Ain <= '1';
					WHEN "11" =>
						Rout <= Xreg;
						Ain <= '1';
				END CASE;
			WHEN "10" => -- define signals in time step T2
				IRin <= '0';
				Ain <= '0';
				Rout <= "0000";
				CASE I IS
					WHEN "00" =>
						Clear <= '1';
					WHEN "01" =>
						Clear <= '1';
					WHEN "10" =>
						Rout <= Yreg;
						Gin <= '1';
					WHEN "11" =>
						Rout <= Yreg;
						Gin <= '1';
						AddSubTrigger <= '1';
				END CASE;
			WHEN "11" => -- define signals in time step T3
				IRin <= '0';
				Gin <= '0';
				Rout <= "0000";
				AddSubTrigger <= '0';
				CASE I IS
					WHEN "00" =>
						Clear <= '1';
					WHEN "01" =>
						Clear <= '1';
					WHEN "10" =>
						Gout <= '1';
						Rin <= Xreg;
						Done <= '1';
					WHEN "11" =>
						Gout <= '1';
						Rin <= Xreg;
						Done <= '1';
				END CASE;
		END CASE;
	END PROCESS;

	
	
	-- instantiate registers and the adder/subtracter unit
	reg_0: regn PORT MAP (BUSsig, Rin(0), Clock, R0);
	reg_1: regn PORT MAP (BUSsig, Rin(1), Clock, R1);
	reg_2: regn PORT MAP (BUSsig, Rin(2), Clock, R2);
	reg_3: regn PORT MAP (BUSsig, Rin(3), Clock, R3);
	
	acm: regn PORT MAP (BUSsig, Ain, Clock, A);
	as: ALU PORT MAP (A, BUSsig, AddSubTrigger, AddSub);
	res: regn PORT MAP (AddSub, Gin, Clock, G);
	
	-- Bus declaration
	BusWires <= BUSsig;

END Behavior;



LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

ENTITY upcount IS
	PORT (	Clear, Clock : IN STD_LOGIC;
				Q : OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
END upcount;

ARCHITECTURE Behavior OF upcount IS
SIGNAL Count : STD_LOGIC_VECTOR(1 DOWNTO 0);
BEGIN
	PROCESS (Clock)
	BEGIN
		IF (Clock'EVENT AND Clock = '1') THEN
			IF Clear = '1' THEN
				Count <= "00";
			ELSE
				Count <= Count + 1;
			END IF;
		END IF;
	END PROCESS;
	Q <= Count;
END Behavior;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY dec2to4 IS
		PORT (	SIGNAL	W:  IN  std_logic_vector(1 DOWNTO 0);
					SIGNAL	EN:  IN  std_logic;
					SIGNAL 	Y:  OUT std_logic_vector(3 DOWNTO 0));
END dec2to4;
					
ARCHITECTURE Behavior OF dec2to4 IS
BEGIN
	PROCESS (W, En)
	BEGIN
		IF En = '1' THEN
			CASE W IS
				WHEN "00" => Y <= "0001";
				WHEN "01" => Y <= "0010";
				WHEN "10" => Y <= "0100";
				WHEN "11" => Y <= "1000";
			END CASE;
		ELSE
			Y <= "0000";
		END IF;
	END PROCESS;
END Behavior;


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY regn IS
	GENERIC (n : INTEGER := 16);
	PORT (	R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
				Rin, Clock : IN STD_LOGIC;
				Q : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END regn;

ARCHITECTURE Behavior OF regn IS
BEGIN
	PROCESS (Clock)
	BEGIN
		IF Clock'EVENT AND Clock = '1' THEN
			IF Rin = '1' THEN
				Q <= R;
			END IF;
		END IF;
	END PROCESS;
END Behavior;


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY reg6 IS
	GENERIC (n : INTEGER := 6);
	PORT (	R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
				Rin, Clock : IN STD_LOGIC;
				Q : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END reg6;

ARCHITECTURE Behavior OF reg6 IS
BEGIN
	PROCESS (Clock)
	BEGIN
		IF Clock'EVENT AND Clock = '1' THEN
			IF Rin = '1' THEN
				Q <= R;
			END IF;
		END IF;
	END PROCESS;
END Behavior;


library ieee;
use ieee.std_logic_1164.all;

ENTITY mux3bit8to1 IS  
   PORT ( S: IN STD_LOGIC_VECTOR(5 DOWNTO 0);
				U0, U1, U2, U3, U4, U5: IN     STD_LOGIC_VECTOR(15 DOWNTO 0);  
				M                   : BUFFER    STD_LOGIC_VECTOR(15 DOWNTO 0));
END mux3bit8to1;

ARCHITECTURE Behavior OF mux3bit8to1 IS  
BEGIN 
		with S select
		M <=  U0 when "100000",
				U1 when "010000",
				U2 when "001000",
				U3 when "000100",
				U4 when "000010",
				U5 when "000001",
				S & "0000000000" when others;
END Behavior; 


LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY ALU IS
   PORT(X			: IN  std_logic_vector(15 DOWNTO 0);
        Y			: IN  std_logic_vector(15 DOWNTO 0);
        operation : IN  std_logic;
        result    : OUT std_logic_vector (15 DOWNTO 0));        
END ALU;

ARCHITECTURE Behavior OF ALU IS
BEGIN
    result <= (X + Y) WHEN (operation = '0') ELSE (X - Y);
END Behavior;
