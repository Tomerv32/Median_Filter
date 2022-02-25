library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.median_filter_tools.all;

entity color_process is
generic(	
	get_rom_name	: string;
	get_ram_name	: string
);

port (
	clk		:	in std_logic;
	rst	:	in std_logic;
	
	-- For "delay" purpose	
	push	:	in std_logic;
	wr_en	:	in std_logic;
	re_add	:	in std_logic_vector(7 downto 0);
	wr_add	:	in std_logic_vector(7 downto 0)	
);

constant rom_name : string := "C:\top\" & get_rom_name;

end entity color_process;


architecture arc_color_process of color_process is

component rom is 
	generic (init_file_path : string);
	port(
		aclr		: IN STD_LOGIC  := '0';
		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q			: OUT STD_LOGIC_VECTOR (1279 DOWNTO 0)
		);
end component;
	
component ram is
	generic (inst_name : string);
	port
	(
		aclr		: IN STD_LOGIC  := '0';
		address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (1279 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (1279 DOWNTO 0)
	);
end component;


-- Buffer
Signal three_buffer	:	three_row	:= (0 =>(others=> (others=> '0')), 
										1 => ( 0 => "11111", others=> (others=> '0')),
										2=> (others=> (others=> '0')));

-- ROM/RAM
Signal rom_q		:	std_logic_vector(pic_width*color_depth-1 downto 0)	:=	(others=>'0');
Signal ram_data_in	:	std_logic_vector(pic_width*color_depth-1 downto 0)	:=	(others=>'0');

begin

u1: entity work.rom_256_1280
	generic map (init_rom_name	=>	get_rom_name)
	port map(
		aclr	=>	rst,
		address	=>	re_add,
		clock	=>	clk,		
		q		=>	rom_q
	);

u2: entity work.ram_256_1280
	generic map (inst_name	=>	get_rom_name)
	port map(
		aclr	=>	rst,	
		address	=>	wr_add,	-- FIX TO THE RIGHT DELAY,
		clock	=>	clk,
		data	=>	ram_data_in,
		wren	=>	wr_en,	-- FIX TO THE RIGHT DELAY,
		q		=>	open
	);
	
	-- RAM is sync anyway, we don't want another register	->	outside the process!
	ram_data_in	<=	unitpixel_to_std(med_3row(three_buffer));

process(clk, rst)

	Variable temp_row		:	unit_row(0 to pic_width-1);
	
	begin
		if rst = '1' then
			--three_buffer	<=	(others=> (others=> (others=>'0')));
		
		elsif (rising_edge(clk)) then			
			if push	= '1' then
				temp_row := std_to_unitpixel(rom_q);
				three_buffer(2)	<=	temp_row(temp_row'left) & temp_row & temp_row(temp_row'right);
				three_buffer(1)	<=	three_buffer(2);
				three_buffer(0)	<=	three_buffer(1);	
			end if;
		end if;		
end process;

end architecture arc_color_process;