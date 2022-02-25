library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

package median_filter_tools is
	-- picture values
	constant pic_width		: positive	:= 256;	
	constant pic_height		: positive	:= 256;	-- Positive is 1 to int'high
	constant color_depth	: positive	:= 5;	-- RGB is orignally 8bit for color, we use 5bit due to hardware limits
	constant kernel_sqrt	: positive	:= 3;
	
	-- unit types
	subtype unit_pixel	is std_logic_vector((color_depth-1) downto 0);						-- Each cell of the color (R/G/B) matrix can be values from 0 to 2^color_depth (32)
	type unit_row		is array (natural range <>) of unit_pixel; 							--(0 to (pic_width+1))
	type unit_matrix 	is array (0 to (pic_height-1)) of unit_row (0 to (pic_width+1));	-- Single color matrix
	
	-- median types
	type three_row		is array (0 to 2) of unit_row (0 to (pic_width+1));					-- 3 row buffer
	type kernel_matrix	is array (0 to kernel_sqrt-1) of unit_row (0 to kernel_sqrt-1);		-- 3x3 matrix for median filter
	
	-- functions
	function med_row			(arg: unit_row)			return unit_pixel;
	function med_ker			(arg: kernel_matrix)	return unit_pixel;
	function med_3row			(arg: three_row)		return unit_row;
	
	function std_to_unitpixel	(arg: std_logic_vector)	return unit_row;
	function unitpixel_to_std	(arg: unit_row)			return std_logic_vector;
	
	---------------------------------------
	constant mif_file_name_format: string := "x.mif";
	type     rom_str_arr is array (0 to 2) of string(mif_file_name_format'range);
	constant rom_arr : rom_str_arr := ("r.mif", "g.mif", "b.mif");
	------------------------------------------
	constant ram_file_name_format: string := "xRAM";
	type     ram_str_arr is array (0 to 2) of string(ram_file_name_format'range);
	constant ram_arr : ram_str_arr := ("rRAM", "gRAM", "bRAM");
	------------------------------------------
	
end package median_filter_tools;


package body median_filter_tools is
	
	function med_3row (arg: three_row) return unit_row is
		variable temp_row		:	unit_row (0 to pic_width-1);
		variable temp_kernel	:	kernel_matrix;
		begin 
			for i in 0 to pic_width-1 loop
				for j in 0 to 2 loop
					temp_kernel(j)	:= arg(j)(i to (i+kernel_sqrt-1));
				end loop;
				temp_row(i) := med_ker(temp_kernel);
			end loop;
		return temp_row;
	end function med_3row;
	
	
	function med_ker (arg: kernel_matrix) return unit_pixel is
		variable temp_row	:	unit_row(0 to kernel_sqrt-1);
		variable temp_unit	: 	unit_pixel;
		begin 
			for i in 0 to kernel_sqrt-1 loop
				temp_row(i) := med_row(arg(i));
			end loop;
			temp_unit := med_row(temp_row);
		return temp_unit;
	end function med_ker;
	
	
	function med_row (arg: unit_row) return unit_pixel is
		variable temp :	unit_pixel;
		begin 
			if (arg(2) >= arg(1) and arg(2) <= arg(0)) then
				temp:= arg(2);
			elsif (arg(2) >= arg(0) and arg(2) <= arg(1)) then
				temp:= arg(2);
			elsif (arg(1) >= arg(0) and arg(1) <= arg(2)) then
				temp:= arg(1);
			elsif (arg(1) >= arg(2) and arg(1) <= arg(0)) then
				temp:= arg(1);
			elsif (arg(0) >= arg(1) and arg(0) <= arg(2)) then
				temp:= arg(0);
			else
				temp:= arg(0);
			end if;
		return temp;
	end function med_row;
	
	function std_to_unitpixel (arg: std_logic_vector) return unit_row is
		variable out_unit	:	unit_row(0 to (pic_width-1));
		begin
			for i in (pic_width-1) downto 0 loop
				out_unit(pic_width-1-i)	:=	arg(((i*color_depth) + (color_depth-1)) downto i*color_depth);
			end loop;
		return out_unit;
	end function std_to_unitpixel;

	function unitpixel_to_std (arg: unit_row) return std_logic_vector is
		variable out_vector	:	std_logic_vector(((color_depth * pic_width)-1) downto 0);
		begin
			for i in 0 to pic_width-1 loop
				out_vector((((pic_width-1-i)*color_depth) + (color_depth-1)) downto (pic_width-1-i)*color_depth)	:=	arg(i);
			end loop;
		return out_vector;
	end function unitpixel_to_std;  
	
end package body median_filter_tools;