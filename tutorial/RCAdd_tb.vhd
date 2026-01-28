LIBRARY ieee;
USE ieee.std_logic_1164.all;
-- entity declaration only. No definition here
ENTITY RCAdd_tb IS
END ;
-- Architecture of the testbench with the signal names
ARCHITECTURE RCAdd_tb_arch OF RCAdd_tb IS
SIGNAL A_tb : std_logic_vector (7 downto 0);
SIGNAL B_tb : std_logic_vector (7 downto 0);
SIGNAL Result_tb : std_logic_vector (7 downto 0) ;
-- component instantiation of the Design Under test (DUT)
COMPONENT RCAdd
PORT (
A : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
B : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
Result : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
END component RCAdd;
BEGIN
DUT : RCAdd
--port mapping: between the DUT and the testbench signals
PORT MAP (
A => A_tb ,
B => B_tb ,
Result => Result_tb ) ;
--add test logic here
sim_process: process
begin
wait for 0 ns;
A_tb <= b"0000_0000";
B_tb <= b"0000_0000";
wait for 20 ns;
A_tb <= b"0010_1010"; -- decimal 42
B_tb <= b"0011_1010"; -- decimal 58

wait for 200 ns;
A_tb <= b"01101001"; -- decimal 105
B_tb <= b"00010101"; -- decimal 21
wait;
end process sim_process;
end;