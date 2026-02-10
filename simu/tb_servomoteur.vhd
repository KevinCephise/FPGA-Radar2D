library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_servomoteur is
end entity;

architecture SIM of tb_servomoteur is
    constant T_CLOCK : time := 20 ns;

    signal clk_tb, reset_n_tb, commande_tb : std_logic;
    signal position_tb : std_logic_vector(7 downto 0);

begin
    uut : entity work.servomoteur(rtl)
        port map(
            clk => clk_tb,
            reset_n => reset_n_tb,
            position => position_tb,
            commande => commande_tb
        );

    clock : process
    begin
        clk_tb <= '0';
        wait for T_CLOCK/2;
        clk_tb <= '1';
        wait for T_CLOCK/2;
    end process;

    stim : process
    begin
        -- INITIALISATION --
        reset_n_tb <= '0';
        position_tb <= (others => '0');
        wait for 100 ns;

        reset_n_tb <= '1';
        -- POSITION = 0 => COMMANDE = 1 ms --
        position_tb <= "00000000";
        wait for 20 ms;

        -- POSITION = 512 (90°) => COMMANDE = 1,5 ms --
        position_tb <= "10000000";
        wait for 20 ms;

        -- POSITION = 1023 (180°) => COMMANDE = 2 ms --
        position_tb <= "11111111";
        wait for 40 ms;

        -- FIN --
        wait; 
    end process;
end architecture SIM;