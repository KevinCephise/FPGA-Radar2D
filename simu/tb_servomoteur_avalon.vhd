library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_servomoteur_avalon is
end entity;

architecture behavior of tb_servomoteur_avalon is

    -- 1. Déclaration du composant à tester (DUT)
    component servomoteur_avalon
        port (
            clk        : in  std_logic;
            reset_n    : in  std_logic;
            chipselect : in  std_logic;
            write_n    : in  std_logic;
            WriteData  : in  std_logic_vector(31 downto 0);
            commande   : out std_logic
        );
    end component;

    -- 2. Signaux internes
    signal clk_tb        : std_logic := '0';
    signal reset_n_tb    : std_logic := '0';
    signal chipselect_tb : std_logic := '0';
    signal write_n_tb    : std_logic := '1';
    signal WriteData_tb  : std_logic_vector(31 downto 0) := (others => '0');
    signal commande_tb   : std_logic;

    -- Constante de temps pour 100 MHz
    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instanciation du DUT
    uut: servomoteur_avalon
        port map (
            clk        => clk_tb,
            reset_n    => reset_n_tb,
            chipselect => chipselect_tb,
            write_n    => write_n_tb,
            WriteData  => WriteData_tb,
            commande   => commande_tb
        );

    -- 4. Génération d'horloge (100 MHz)
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- 5. Processus de Stimuli
    stim_proc: process
        variable t_start, t_end, t_diff : time;
        
        -- Procédure helper pour simuler une écriture Avalon
        procedure avalon_write(valeur : in integer) is
        begin
            wait until rising_edge(clk_tb);
            chipselect_tb <= '1';
            write_n_tb    <= '0';
            WriteData_tb  <= std_logic_vector(to_unsigned(valeur, 32));
            wait until rising_edge(clk_tb);
            chipselect_tb <= '0';
            write_n_tb    <= '1';
        end procedure;

    begin
        -- === INITIALISATION ===
        report "Début de la simulation";
        reset_n_tb <= '0';
        wait for 100 ns;
        reset_n_tb <= '1';
        wait for 100 ns;

        -- =========================================================
        -- TEST CAS 1 : Position 0 (Attendu : 500 us)
        -- =========================================================
        report "Test 1 : Ecriture de 0 (Angle 0 degres)";
        avalon_write(0);

        -- On attend le début de l'impulsion (front montant)
        -- Note : Le premier cycle démarre juste après le reset
        wait until rising_edge(commande_tb);
        t_start := now;
        
        -- On attend la fin de l'impulsion (front descendant)
        wait until falling_edge(commande_tb);
        t_end := now;
        
        t_diff := t_end - t_start;
        report "Duree impulsion mesurree (Pos 0) : " & time'image(t_diff);

        -- Vérification (500 us attendu)
        assert (t_diff >= 499 us and t_diff <= 501 us)
            report "ERREUR : L'impulsion pour 0 devrait etre de 500 us" severity error;


        -- =========================================================
        -- TEST CAS 2 : Position 128 (Attendu : ~1.5 ms)
        -- =========================================================
        -- Note : Le module attend la fin du cycle de 20ms courant avant de changer
        report "Test 2 : Ecriture de 128 (Angle ~90 degres)";
        avalon_write(128);

        -- On attend le PROCHAIN cycle (le cycle courant n'est pas fini)
        wait until rising_edge(commande_tb); -- C'est le début du cycle avec la NOUVELLE valeur
        t_start := now;
        
        wait until falling_edge(commande_tb);
        t_end := now;
        
        t_diff := t_end - t_start;
        report "Duree impulsion mesurree (Pos 128) : " & time'image(t_diff);
        
        -- Calcul théorique : 500us + (128/255)*2000us approx 1500 us
        assert (t_diff >= 1490 us and t_diff <= 1510 us)
            report "ERREUR : L'impulsion pour 128 devrait etre env. 1.5 ms" severity error;


        -- =========================================================
        -- TEST CAS 3 : Position 255 (Attendu : 2.5 ms)
        -- =========================================================
        report "Test 3 : Ecriture de 255 (Angle 180 degres)";
        avalon_write(255);

        wait until rising_edge(commande_tb);
        t_start := now;
        
        wait until falling_edge(commande_tb);
        t_end := now;
        
        t_diff := t_end - t_start;
        report "Duree impulsion mesurree (Pos 255) : " & time'image(t_diff);
        
        -- Vérification (2500 us attendu)
        assert (t_diff >= 2499 us and t_diff <= 2501 us)
            report "ERREUR : L'impulsion pour 255 devrait etre de 2.5 ms" severity error;

        report "Fin des tests avec succes.";
        wait;
    end process;

end architecture;