library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity servomoteur is
    port (
        clk : in std_logic;
        reset_n : in std_logic;
        position : in std_logic_vector(7 downto 0);
        commande : out std_logic
    );
end entity;

architecture rtl of servomoteur is

    type state_type is (READ, MESURE, IMPULSION, WAIT_IMP);
    signal current_state : state_type;

    constant IMPULSION_MIN : integer := 25000;   -- 500 us
    constant IMPULSION_MAX : integer := 125000;  -- 2,5 ms
    constant INTERVALLE    : integer := 1000000;  -- 15 ms
    constant NB_VALEURS    : integer := 255;    -- 2^8 - 1

    signal input : integer range 0 to 255 := 0;
    signal size_impulsion : integer range 0 to 125000;
    signal cnt_impulsion : integer range 0 to 125000 := 0;
    signal cnt_intervalle : integer range 0 to 1000000 := 0;

begin
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            current_state <= READ;
            commande <= '0';
            cnt_impulsion <= 0;
            cnt_intervalle <= 0;

        elsif rising_edge(clk) then

            case current_state is
                when READ =>
                    input <= to_integer(unsigned(position));
                    cnt_impulsion <= 0;
                    cnt_intervalle <= 0;
                    current_state <= MESURE;

                when MESURE =>
                    size_impulsion <= 25000 + input * (IMPULSION_MAX - IMPULSION_MIN) / NB_VALEURS; -- 392 = 100 000 / 255
                    commande <= '1';
                    current_state <= IMPULSION;

                when IMPULSION =>
                    if cnt_impulsion < size_impulsion then
                        commande <= '1';
                        cnt_impulsion <= cnt_impulsion + 1;
                    else
                        commande <= '0';
                        cnt_intervalle <= size_impulsion;
                        current_state <= WAIT_IMP;
                    end if;
                
                when WAIT_IMP =>
                    commande <= '0';
                    if cnt_intervalle < INTERVALLE then
                        cnt_intervalle <= cnt_intervalle + 1;
                    else
                       current_state <= READ; 
                    end if;
                    
                when others =>
                    current_state <= READ;
            
            end case;
        end if;
    end process;
end architecture rtl;

