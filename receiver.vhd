----------------------------------------------------------------------------------
-- I2S Receiver Module
-- Copyright (c) Fernando Rodriguez, 2007
-- 
-- Create Date:    14:16:59 06/21/2007 
-- Design Name:    I2S
-- Module Name:    receiver - Behavioral 
-- Project Name:   I2S Receiver
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.i2s.ALL;


entity receiver is
    Port ( 
			--I2S INPUTS (NOTE ALL INPUTS NEED TO BE SYNCHRONOUS TO EACH OTHER)
			LRCK : in  STD_LOGIC;  								--I2S  L/R   INPUT
			BCK : in  STD_LOGIC;								--I2S CLOCK INPUT
			DIN : in  STD_LOGIC_VECTOR (num_inputs-1 downto 0);	--I2S DATA INPUTS
          
			--HOST CPU BUS INTERFACE
		   INT : out std_logic;						--INTerrupt signal (When FIFO is close to full)
		   OVERFLOW: out std_logic;					--Signal that an OVERFLOW occurred (data was not read fast enough)
			
		   RESET : in STD_LOGIC;						
 		   A : in  STD_LOGIC_VECTOR (7 downto 0);		--ADRESS bus
           D : inout  STD_LOGIC_VECTOR (7 downto 0);	--Data Bus
           NCS : in  STD_LOGIC;							--Chip Select
           NRD : in  STD_LOGIC;							--Read Select	
           NWR : in  STD_LOGIC);						--Write Select
end receiver;

architecture Behavioral of receiver is
	
component i2s_fifo
	port (
	din: IN std_logic_VECTOR(27 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(27 downto 0);
	empty: OUT std_logic;
	full: OUT std_logic;
	overflow: OUT std_logic;
	wr_data_count: OUT std_logic_VECTOR(9 downto 0));
end component;

	signal fifo_din: std_logic_VECTOR(27 downto 0);
	signal fifo_dout : std_logic_VECTOR(27 downto 0);
	signal fifo_rd_en : std_logic;
	signal fifo_wr_en : std_logic;
	signal fifo_empty : std_logic;
	signal fifo_full : std_logic;
	signal fifo_wr_count : std_logic_VECTOR(9 downto 0);


	signal bus_clk : std_logic;
	
	signal sr : sr_type;  --shift registers to receive data
	signal sr_latch : sr_type;  --place to hold data when assembled
	signal LRCKo : std_logic; --to detect change of LRCK signal
	signal count : integer range 0 to 24;
	signal sync :std_logic; --Determines when we are in sync with frame
	
begin
	bus_clk <= not (NRD and NWR);
	
	--This make fifo output data when CPU reads register 0.
	fifo_rd_en <= '1' when  (NCS='0' and NRD='0' and A(7 downto 2)="000000") else '0'; 

data_fifo : i2s_fifo
		port map (
			din => fifo_din,
			rd_clk => bus_clk,
			rd_en => fifo_rd_en,
			rst => RESET,
			wr_clk => BCK,
			wr_en => fifo_wr_en,
			dout => fifo_dout,
			empty => fifo_empty,
			full => fifo_full,
			overflow => OVERFLOW,
			wr_data_count => fifo_wr_count);


	businterface:process (NCS, NRD, NWR, RESET)
	begin   
        D <= (others => 'Z');
        if (RESET='1') then
              --fifo_out<=0;          
        
        elsif (NCS='0' and NRD='0') then
				if (A(1 downto 0)="11") then
					D<= "0000" & fifo_dout (27 downto 24);
				else
                D <= fifo_dout( 7+8*conv_integer(A(1 downto 0)) downto 8*conv_integer(A(1 downto 0)) );  --pass fifo data
				end if;
		  end if;
	end process; --businterface
	
	
	
	sample : process (BCK)
		begin
		--fifo_wr_en<='0';
		
		if (RESET='1') then
			INT <='1';
			LRCKo <= '0';
			count<=0;
			sync<='0';
			
		elsif (BCK'event and BCK='1') then
			fifo_wr_en<='0';
			count<=count+1;
			
			--first capture data
			for i in num_inputs-1 downto 0 loop
				sr(i)(23 downto 1) <= sr(i)(22 downto 0); --shift
				sr(i)(0) <= DIN(i); --and read new data
			end loop;
			
			--check to see if LRCK has changed (meaning we have new data)
			if (LRCK/=LRCKo) then
				LRCKo<=LRCK;
				count<=0; --reset at each change of LRCK
				if (LRCK='0') then
					sync<='1'; --we are synchronized
				end if;
				
				--latch all data of channel just received
				for i in num_inputs-1 downto 0 loop
					sr_latch(i)<=sr(i);
				end loop;
			end if; --LRCK\=LRCKo
			
			--Now put the data in the fifo if needed
			--We do this at time n for the Nth channel
			--Remeber there are 2 channels, hence LRCK appears as MSB.
			if (sync='1' and count>0 and count<num_inputs+1) then
				fifo_wr_en<='1';
				fifo_din<= LRCK & CONV_STD_LOGIC_VECTOR(count,log_num_inputs+1) & sr_latch(count-1);
			end if;
		
			--Check to see if we should interrupt
			if (conv_integer(fifo_wr_count)>512) then
				INT <= '0';
			else
				INT <='1';
			end if;
		end if;
	end process; --sample

end Behavioral;

