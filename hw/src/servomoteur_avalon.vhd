library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity servomoteur_avalon is
    port (
        -- Interface Avalon-MM Slave
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        chipselect : in  std_logic;                    -- Sélection du périphérique
        write_n    : in  std_logic;                    -- Write Enable (Actif bas)
        WriteData  : in  std_logic_vector(31 downto 0);-- Données venant du Nios II
        
        -- Interface Conduit (Vers le servomoteur)
        commande   : out std_logic
    );
end entity;

architecture rtl of servomoteur_avalon is

    -- 1. Signaux pour la gestion Avalon
    signal reg_position : std_logic_vector(7 downto 0) := (others => '0');

    -- 2. Signaux internes du Servomoteur (on a multiplié tous les timers par 2 puisque la PLL du Nios2 multiplie la fréquence par 2)
    type state_type is (READ, MESURE, IMPULSION, WAIT_IMP);
    signal current_state : state_type;

    constant IMPULSION_MIN : integer := 50000;   -- 500 us
    constant IMPULSION_MAX : integer := 250000;  -- 2,5 ms
    constant INTERVALLE    : integer := 2000000; -- 20 ms
    constant NB_VALEURS    : integer := 255;     

    signal input          : integer range 0 to 255 := 0;
    signal size_impulsion : integer range 0 to 250000;
    signal cnt_impulsion  : integer range 0 to 250000 := 0;
    signal cnt_intervalle : integer range 0 to 2000000 := 0;

begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            -- Reset Avalon
            reg_position <= (others => '0');
            
            -- Reset Servomoteur
            current_state <= READ;
            commande <= '0';
            cnt_impulsion <= 0;
            cnt_intervalle <= 0;

        elsif rising_edge(clk) then
            
            -- === GESTION DU BUS AVALON (Ecriture) ===
            -- On met à jour le registre interne si le processeur écrit
            if chipselect = '1' and write_n = '0' then
                reg_position <= WriteData(7 downto 0);
            end if;

            -- === LOGIQUE DU SERVOMOTEUR (Votre FSM) ===
            case current_state is
                when READ =>
                    -- On lit la valeur stockée dans le registre Avalon
                    input <= to_integer(unsigned(reg_position));
                    cnt_impulsion <= 0;
                    cnt_intervalle <= 0;
                    current_state <= MESURE;

                when MESURE =>
                    -- Calcul de la durée (Formule linéaire)
                    size_impulsion <= IMPULSION_MIN + (input * (IMPULSION_MAX - IMPULSION_MIN)) / NB_VALEURS;
                    commande <= '1';
                    current_state <= IMPULSION;

                when IMPULSION =>
                    if cnt_impulsion < size_impulsion then
                        commande <= '1';
                        cnt_impulsion <= cnt_impulsion + 1;
                    else
                        commande <= '0';
                        -- On initialise le compteur d'intervalle avec la durée déjà écoulée
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

end architecture;