LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY RCAdd IS
PORT (A, B : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
Result : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END RCAdd;

ARCHITECTURE behavioral OF RCAdd IS
BEGIN
RippleCarryAdder:
PROCESS (A, B)
VARIABLE LocalCarry : STD_LOGIC_VECTOR(8 DOWNTO 0);
BEGIN
LocalCarry(0) := '0';
FOR i IN 0 TO 7 LOOP
Result(i) <= A(i) XOR B(i) XOR LocalCarry(i);
LocalCarry(i+1) := (A(i) AND B(i)) OR
(LocalCarry(i) AND (A(i) OR B(i)));
END LOOP;
END PROCESS;
END behavioral;