library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity telemetre is
    port (
        clk  : in  std_logic;        
        rst_n : in  std_logic;        -- reset actif à 0) (KEY0)
        echo : in  std_logic;
        trig  : out std_logic;
        read_n : in std_logic;
        chipselect : in std_logic;
        readdata : out std_logic_vector(31 downto 0);        
        dist_cm  : out std_logic_vector(9 downto 0)
    );
end entity;

architecture rtl of telemetre is

    type state_type is (IDLE, SEND_TRIG, WAIT_ECHO, MEASURE, WAIT_EN_CYCLE);
    signal current_state : state_type;

    constant CYCLES_10US   : integer := 500;
    constant CYCLES_60MS   : integer := 3000000;
    constant CYCLES_PER_CM : integer := 2900;

    signal tick_counter : integer range 0 to 3000000 := 0;
    signal counter_avalon : integer := 0;
    signal cm_counter   : integer range 0 to 5000 := 0;
    signal dist_counter : integer range 0 to 1023 := 0;
    signal dist_avalon : std_logic_vector(31 downto 0) := (others => '0');
    signal dist_reg     : std_logic_vector(9 downto 0) := (others => '0');
    
    -- AJOUT 1 : Signaux de synchronisation
    signal echo_sync_1 : std_logic := '0';
    signal echo_sync_2 : std_logic := '0';

begin

    -- readdata <= std_logic_vector(resize(unsigned(dist_reg), 32)) when (chipselect = '1' and read_n = '0')
       readdata <= std_logic_vector(dist_avalon) when (chipselect = '1' and read_n = '0')
                else (others => '0');

    -- AJOUT 2 : Processus de synchronisation dédié
    -- Cela rend le signal "echo" propre pour l'horloge 50MHz
    process(clk)
    begin
        if rising_edge(clk) then
            echo_sync_1 <= echo;       -- Première barrière
            echo_sync_2 <= echo_sync_1; -- Deuxième barrière (signal stable)
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            current_state <= IDLE;
            trig <= '0';
            dist_reg <= (others => '0');
            tick_counter <= 0;
            counter_avalon <= 0;         -- counter_avalon
            cm_counter <= 0;
            dist_counter <= 0;
        elsif rising_edge(clk) then
            
            -- Compteur global
            if current_state /= IDLE and tick_counter < CYCLES_60MS then
                tick_counter <= tick_counter + 1;
            end if;

            case current_state is
                
                when IDLE =>
                    tick_counter <= 0;
                    counter_avalon <= 0;
                    current_state <= SEND_TRIG;

                when SEND_TRIG =>
                    trig <= '1';
                    if tick_counter >= CYCLES_10US then 
                        trig <= '0';
                        current_state <= WAIT_ECHO;
                    end if;

                when WAIT_ECHO =>
                    trig <= '0';
                    if tick_counter > 2000000 then -- Timeout pas d'écho
                         current_state <= WAIT_EN_CYCLE;
                    -- AJOUT 3 : On utilise echo_sync_2 au lieu de echo
                    elsif echo_sync_2 = '1' then
                        cm_counter <= 0;
                        dist_counter <= 0;
                        current_state <= MEASURE;
                    end if;

                when MEASURE =>
                    -- AJOUT 4 : Condition de sécurité (Timeout)
                    -- Si on dépasse les 60ms, on force l'arrêt même si echo est encore à 1
                    if echo_sync_2 = '1' and tick_counter < CYCLES_60MS then
                        
                        if cm_counter < CYCLES_PER_CM - 1 then
                            counter_avalon <= counter_avalon + 1;    -- counter avalon  
                            cm_counter <= cm_counter + 1;
                        else
                            cm_counter <= 0;
                            if dist_counter < 1023 then
                                dist_counter <= dist_counter + 1;
                            end if;
                        end if;
                    else
                        -- Fin de mesure (echo est tombé OU timeout atteint)
                        -- On ne change dist_counter que si c'était une vraie fin de mesure
                        if echo_sync_2 = '0' then
                            -- counter_avalon <= counter_avalon + CYCLES_PER_CM; -- counter avalon
                            dist_counter <= dist_counter + 1; -- compensation
                        end if;
                        
                        current_state <= WAIT_EN_CYCLE;
                    end if;

                when WAIT_EN_CYCLE =>
                    dist_reg <= std_logic_vector(to_unsigned(dist_counter, 10));
                    dist_avalon <= std_logic_vector(to_unsigned(counter_avalon, 32));

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