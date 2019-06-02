----------------------------------------------------------------------------------
-- Company: Wapice Ltd
-- Engineer: Jan Lipponen
-- 
-- Create Date: 04/06/2018 11:38:14 AM
-- Design Name: 
-- Module Name: sample_generator_tb
-- Project Name: ZYNQ DMA Cyclic
-- Target Devices: Vivado simulator
-- Tool Versions: 
-- Description: Instantiates and stresses the sample generator module
-- 
-- Dependencies: sample_generator.v sample_clk_gen.v count_data_gen.v
-- 
-- Revision:
-- Revision 1.0 - Operational
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sample_generator_tb is
    generic (
        data_width_g        : integer := 32
    );
end sample_generator_tb;

architecture Behavioral of sample_generator_tb is   

    component sample_generator
    generic(
        C_M_AXIS_DATA_WIDTH : integer
    );
    port(
        ACLK                : in std_logic;
        ARESETN             : in std_logic;
        tlast_throttle      : in std_logic_vector(data_width_g - 1 downto 0);
        clk_divider         : in std_logic_vector(data_width_g - 1 downto 0);
        enable              : in std_logic;
        insert_error        : in std_logic;
        M_AXIS_TDATA        : out std_logic_vector(data_width_g - 1 downto 0);
        M_AXIS_TKEEP        : out std_logic_vector((data_width_g/8) - 1 downto 0);
        M_AXIS_TLAST        : out std_logic;
        M_AXIS_TREADY       : in std_logic;
        M_AXIS_TVALID       : out std_logic
    );
    end component;
    
    -- Constants
    constant period_10ns_c	: time := 10 ns;    -- For 100MHz clock gen 
    constant period_8ns_c	: time := 8 ns;     -- For 125MHz clock gen
    
    -- Clock and reset signals   
    signal ACLK             : std_logic := '0';     -- 100MHz axi clock for the dsp_stage
    signal rstn             : std_logic := '0';     -- Active low reset
    
    -- DUV input signals
    signal tlast_throttle_s : std_logic_vector(data_width_g - 1 downto 0) := "00000000000000000000000000000000";
    signal clk_divider_s    : std_logic_vector(data_width_g - 1 downto 0) := "00000000000000000000000000000000";
    signal enable_s         : std_logic := '0';
    signal insert_error_s   : std_logic := '0';

    -- DUV AXIS signals
    signal tdata_s          : std_logic_vector(data_width_g - 1 downto 0);
    signal tkeep_s          : std_logic_vector((data_width_g/8) - 1 downto 0);
    signal tlast_s          : std_logic;
    signal tready_s         : std_logic;
    signal tvalid_s         : std_logic;
    
begin
    -- Scheduled tasks
    rstn <= '1' after 50ns;
    tready_s <= '1' after 80ns;--, '0' after 520ns, '1' after 540ns;
    tlast_throttle_s <= "00000000000000000000000000000011" after 100ns;
    clk_divider_s <= "00000000000000000000000000000000" after 100ns,  -- 0
                     "00000000000000000000000000000001" after 200ns,  -- 1
                     "00000000000000000000000000000010" after 400ns,  -- 2
                     "00000000000000000000000000000011" after 600ns,  -- 3
                     "00000000000000000000000000000100" after 800ns, -- 4
                     "00000000000000000000000000000101" after 1000ns; -- 5
    enable_s <= '1' after 120ns;         
    
    -- Error insertion
    --insert_error_s <= '1' after 575ns, '0' after 650ns, '1' after 800ns;

    -- Process to generate 100MHz clock
    process(ACLK)
    begin
        ACLK <= not ACLK after period_8ns_c/2;
    end process;

    -- DUV instantiation
    SAMPLE_GENERATOR_INST: sample_generator
    generic map(
        C_M_AXIS_DATA_WIDTH => data_width_g
    )
    port map(
        ACLK => ACLK,
        ARESETN => rstn,
        tlast_throttle => tlast_throttle_s,
        clk_divider => clk_divider_s,
        enable => enable_s,
        insert_error => insert_error_s,
        M_AXIS_TDATA => tdata_s,
        M_AXIS_TKEEP => tkeep_s,
        M_AXIS_TLAST => tlast_s,
        M_AXIS_TREADY => tready_s,
        M_AXIS_TVALID => tvalid_s
    );
           
end Behavioral;
