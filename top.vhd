library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.median_filter_tools.all;

entity top is
port (
	clk		:	in std_logic;
	rst	:	in std_logic;
	
	start	:	in std_logic;
	done_o	:	out std_logic
);

attribute altera_chip_pin_lc : string;
attribute altera_chip_pin_lc of clk  	: signal is "Y2";
attribute altera_chip_pin_lc of rst  	: signal is "AB28";
attribute altera_chip_pin_lc of start	: signal is "AC28";
attribute altera_chip_pin_lc of done_o	: signal is "E21";
end entity top;


architecture arc_top of top is

component state_machine is
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
end component;

component color_process is
generic(	
	get_rom_name	: string;
	get_ram_name	: string
);
port (
	clk		:	in std_logic;
	rst		:	in std_logic;
		
	push	:	in std_logic;
	wr_en	:	in std_logic;
	re_add	:	in std_logic_vector(7 downto 0);
	wr_add	:	in std_logic_vector(7 downto 0)
);
end component;

Signal s_push	:	std_logic;
Signal s_wr_en	:	std_logic;
Signal s_re_add	:	std_logic_vector(7 downto 0);
Signal s_wr_add	:	std_logic_vector(7 downto 0);

begin

u1:	state_machine
port map(
	clk			=>	clk,
	rst		=>	rst,
	
	start		=>	start,
	done_o		=>	done_o,
	
	push_o		=>	s_push,
	o_wr_en		=>	s_wr_en,
	
	o_re_add	=>	s_re_add,
	o_wr_add	=>	s_wr_add
);


L1: for i in 0 to 2 generate
	u2: color_process
	generic map (
		get_rom_name => rom_arr(i),
		get_ram_name => ram_arr(i)
		)
		
	port map (
		clk		=>	clk,
		rst   =>	rst,

		push	=>	s_push,
		wr_en   =>	s_wr_en,
		re_add  =>	s_re_add,
		wr_add  =>	s_wr_add
		);
end generate L1;

end architecture arc_top;