library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity telemetre is
    port (
        clk  : in  std_logic;        
        rst_n : in  std_logic;        -- reset actif à 0) (KEY0)
        echo : in  std_logic;
        trig  : out std_logic;        
        dist_cm  : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of telemetre is

    type state_type is (IDLE, SEND_TRIG, WAIT_ECHO, MEASURE, WAIT_EN_CYCLE);
    signal current_state : state_type;

    -- Constantes (équivalent en tour de boucle des temps critiques de notre telemètre)
    constant CYCLES_10US   : integer := 500;  
    constant CYCLES_60MS   : integer := 3000000;
    constant CYCLES_PER_CM : integer := 2900;

    -- Compteurs
    signal tick_counter : integer range 0 to 3000000 := 0;
    signal cm_counter   : integer range 0 to 5000 := 0;    
    signal dist_counter : integer range 0 to 1023 := 0;    
    signal dist_reg     : std_logic_vector(9 downto 0) := (others => '0');

begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
            trig <= '0';
            dist_reg <= (others => '0');
            tick_counter <= 0;
            cm_counter <= 0;
            dist_counter <= 0;
            
        elsif rising_edge(clk) then
            
            -- COMPTEUR GLOBAL : Il tourne tout le temps sauf en IDLE
            if current_state /= IDLE and tick_counter < CYCLES_60MS then
                tick_counter <= tick_counter + 1;
            end if;

            case current_state is
                
                when IDLE =>
                    tick_counter <= 0;
                    current_state <= SEND_TRIG;

                when SEND_TRIG =>
                    trig <= '1';
                    -- On utilise le compteur global qui vient de commencer
                    if tick_counter >= CYCLES_10US then 
                        trig <= '0';
                        current_state <= WAIT_ECHO;
                    end if;

                when WAIT_ECHO =>
                    trig <= '0';
                    -- Si on attend trop longtemps (40ms sans écho), on force la fin
                    if tick_counter > 2000000 then -- ~40ms de timeout (on peut négliger CYCLES_10US ici)
                         current_state <= WAIT_EN_CYCLE;
                    elsif echo = '1' then
                        cm_counter <= 0;
                        dist_counter <= 0;
                        current_state <= MEASURE;
                    end if;

                when MEASURE =>
                    if echo = '1' then
                        -- Logique de mesure de distance (inchangée)
                        if cm_counter < CYCLES_PER_CM - 1 then      -- Quand on sort de ce "if", on a mesuré un cm
                            cm_counter <= cm_counter + 1;
                        else
                            cm_counter <= 0;
                            if dist_counter < 1023 then
                                dist_counter <= dist_counter + 1;
                            end if;
                        end if;
                    else
                        dist_counter <= dist_counter + 1; -- on rajoute une incrémentation pour compenser le tour de clock perdu par le changemant d'état de la MAE
                        current_state <= WAIT_EN_CYCLE;
                        -- IMPORTANT : On ne reset PAS tick_counter ici !
                    end if;

                when WAIT_EN_CYCLE =>
                    -- On met à jour la sortie ici pour que la dernière incrémentation soient prise en compte
                    dist_reg <= std_logic_vector(to_unsigned(dist_counter, 10));
                    -- On attend que le compteur global atteigne les 60ms
                    if tick_counter >= CYCLES_60MS then
                        current_state <= IDLE;
                    end if;

                when others =>
                    current_state <= IDLE;
            end case;
        end if;
    end process;

    dist_cm <= dist_reg;
end architecture;