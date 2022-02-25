library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.median_filter_tools.all;

entity state_machine is
port (
	clk			:	in std_logic;
	rst		:	in std_logic;
		
	start		:	in std_logic;
	done_o		:	out std_logic;
		
	push_o		:	out std_logic;
	o_wr_en		:	out std_logic;

	o_re_add	:	out std_logic_vector(7 downto 0);
	o_wr_add	:	out std_logic_vector(7 downto 0)
);
end entity state_machine;


architecture arc_state_machine of state_machine is
-- idle: wait for start
-- s0: line 0 
-- s1: line 0 again to 255
-- s2: line 255 again
-- done: done.. go back to idle
Type	state_mechine is (idle, s0, s1, s2, done); 
Signal	State	:	state_mechine;
Signal	re_add	:	std_logic_vector(7 downto 0);	-- Counter for read address
Signal	wr_add	:	std_logic_vector(7 downto 0);	-- Counter for write address
Signal	re_en	:	std_logic;
Signal	wr_en	:	std_logic;

-- DELAY Signals
Signal wr_en_d_1, wr_en_d_2, wr_en_d_3, wr_en_d_4		:	std_logic	:=	'0';
Signal wr_add_d_1, wr_add_d_2, wr_add_d_3, wr_add_d_4	:	std_logic_vector(wr_add'HIGH downto 0)	:=	(others=>'0');

Signal push, push_d_1									:	std_logic	:=	'0';


begin

o_wr_en		<=	wr_en_d_4;

o_re_add	<=	re_add;
o_wr_add	<=	wr_add_d_4;

process(clk, rst) is 	
	variable	f_case	:	std_logic;							
	variable	l_case	:	std_logic;
	
	begin

	if rst = '1' then
		push_o	<=	'0';
		re_en	<=	'0';
		wr_en	<=	'0';
		done_o	<=	'0';
		re_add	<=	(others=>'0');	
		wr_add	<=	(others=>'0');
		f_case	:=	'0';
		l_case	:=	'0';
		
		
	elsif rising_edge(clk) then
	
		-- DELAYS - FF
		wr_add_d_1	<=	wr_add;
		wr_add_d_2	<=	wr_add_d_1;
		wr_add_d_3	<=	wr_add_d_2;
		wr_add_d_4	<=	wr_add_d_3;
				
		wr_en_d_1	<=	wr_en;
		wr_en_d_2	<=	wr_en_d_1;
		wr_en_d_3	<=	wr_en_d_2;
		wr_en_d_4	<=	wr_en_d_3;
		
		push_d_1	<=	push;
		push_o		<=	push_d_1;
	
		-- Counters for read/write ROM/RAM respectively
		if (re_en and NOT(f_case) and NOT(l_case)) = '1' then
			re_add <= re_add + '1';
		end if;
		
		if (wr_en and NOT(f_case) and NOT(l_case)) = '1' then
			wr_add <= wr_add + '1';
		end if;	
		
		-- State Machine!
		State	<=	State;
		
		-- Reset all lines
		push	<=	'0';
		re_en	<=	'0';
		wr_en	<=	'0';
		f_case	:=	'0';
		l_case	:=	'0';
		
		case State is			
			when idle	=>
				if start = '1' then
					State	<=	s0;
					push	<=	'1';
				end if;
			
			when s0		=>
	-- when we are at counter = 0 we want to write line 0 twice
	-- so we won't enable the counter for 1 more cycle
				f_case	:=	'1';
				re_en	<=	'1';
				wr_en	<=	'1';
				push	<=	'1';
				State	<=	s1;
				
			when s1		=>
				re_en	<=	'1';
				wr_en	<=	'1';
				push	<=	'1';
	-- when we are at counter = 254 the counter is already updated to 255 (next clock)
	-- we want to stop the counter at 255 so we can write this line again
				if re_add = 254 then
					l_case	:=	'1';
					State	<=	s2;					
				end if;
				
			when s2		=>
				re_en	<=	'1';
				wr_en	<=	'1';
				push	<=	'1';				
				State	<=	done;
			
			when done	=>
				if wr_add_d_4 = 255 then
					done_o	<=	'1';
				end if;
				
			when others	=>
				State	<=	idle;
				
		end case;
	end if;
end process;

end architecture arc_state_machine;