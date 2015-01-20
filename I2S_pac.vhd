----------------------------------------------------------------------------------
-- I2S_RX PAC 
-- Copyright (c) Fernando Rodriguez, 2007
-- 
-- Configuration and type declarations for I2S_RX
--
-- This file is part of I2S_RX.   
--  I2S_RX is free software: you can redistribute it and/or modify
--  it under the terms of the Lesser GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  I2S_RX is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  Lesser GNU General Public License for more details.
--
--  You should have received a copy of the Lesser GNU General Public License
--  along with I2S_RX.  If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package I2S is

	constant num_inputs : integer :=4;
	constant log_num_inputs : integer :=2;
	type sr_type is array (num_inputs-1 downto 0) of std_logic_vector(23 downto 0);


end I2S;



