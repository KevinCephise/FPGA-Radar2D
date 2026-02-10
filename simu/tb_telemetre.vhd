library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_telemetre is
end entity;

architecture behavior of tb_telemetre is

    -- 1. Déclaration du composant à tester (DUT : Device Under Test)
    component telemetre
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;
            echo     : in  std_logic;
            trig     : out std_logic;
            read_n   : in std_logic;
            chipselect : in std_logic;
            readdata : out std_logic_vector(31 downto 0);
            dist_cm  : out std_logic_vector(9 downto 0)
        );
    end component;

    -- 2. Signaux internes pour connecter le testbench au composant
    signal clk_tb          : std_logic := '0';
    signal rst_n_tb        : std_logic := '0';
    signal echo_tb         : std_logic := '0';
    signal trig_tb         : std_logic;
    signal read_n_tb       : std_logic := '1';
    signal chipselect_tb   : std_logic := '0';
    signal readdata_tb     : std_logic_vector(31 downto 0);
    signal dist_cm_tb      : std_logic_vector(9 downto 0);

    constant CLK_PERIOD : time := 20 ns;

begin

    -- 3. Instanciation du DUT (On connecte les fils)
    uut: telemetre
        port map (
            clk      => clk_tb,
            rst_n    => rst_n_tb,
            echo     => echo_tb,
            trig     => trig_tb,
            read_n   => read_n_tb,
            chipselect => chipselect_tb,
            readdata => readdata_tb,
            dist_cm  => dist_cm_tb
        );

    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    stim_proc: process
    begin
        -- === INITIALISATION ===
        report "Début de la simulation";
        rst_n_tb <= '0';      -- Reset actif
        echo_tb  <= '0';
        chipselect_tb <= '0';
        read_n_tb <= '1';
        wait for 100 ns;
        rst_n_tb <= '1';      -- Fin du Reset
        
        -- === TEST CAS 1 : Distance de 10 cm ===
        -- Calcul théorique : 10 cm * 58 us/cm = 580 us
        
        -- A. Attendre que l'IP envoie le Trigger
        wait until trig_tb = '1';
        report "Trigger détecté (Test 10cm)";
        
        -- B. Attendre la fin du Trigger (l'IP le maintient 10us)
        wait until trig_tb = '0';
        
        -- C. Petit délai simulé avant que le son ne revienne (latence physique)
        wait for 5 us; 
        
        -- D. Génération de l'Echo pour 10 cm
        echo_tb <= '1';
        wait for 580 us;      -- Durée exacte pour 10 cm
        echo_tb <= '0';
        
        -- E. Vérification du résultat
        -- On attend un peu que l'IP finisse son calcul
        wait for 1 us; 
        
        -- Assertion automatique : vérifie si le résultat est 10
        assert to_integer(unsigned(dist_cm_tb)) = 10
            report "ERREUR : La distance mesurée devrait être 10 cm"
            severity error;
            
        report "Succès : Distance 10 cm mesurée correctement : " & integer'image(to_integer(unsigned(dist_cm_tb))) & " cm";
        chipselect_tb <= '1';
        read_n_tb <= '0';
        
        -- === TEST CAS 2 : Distance de 30 cm ===
        -- Note : L'IP attend normalement 60ms avant le prochain trigger.
        -- Pour la simulation, cela peut être long. Soyez patient ou réduisez la constante CYCLES_60MS dans le code VHDL juste pour la simulation.
        
        report "Attente du prochain cycle (peut prendre 60ms de temps simulation)...";
        
        wait until trig_tb = '1'; -- Attente du 2ème trigger
        read_n_tb <= '1';
        report "Trigger détecté (Test 30cm)";
        wait until trig_tb = '0';
        
        wait for 5 us;
        
        -- Génération de l'Echo pour 30 cm (30 * 58us = 1740 us)
        echo_tb <= '1';
        wait for 1740 us; 
        echo_tb <= '0';
        
        wait for 1 us;
        
        assert to_integer(unsigned(dist_cm_tb)) = 30
            report "ERREUR : La distance mesurée devrait être 30 cm"
            severity error;
            
        report "Succès : Distance 30 cm mesurée correctement : " & integer'image(to_integer(unsigned(dist_cm_tb))) & " cm";
        chipselect_tb <= '1';
        read_n_tb <= '0';


        -- Fin de simulation
        report "Fin des tests avec succès.";
        wait;
    end process;

end architecture;