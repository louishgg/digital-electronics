library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Pong game
entity pong is
    generic(
        -- Constants
        SCREEN_WIDTH: integer := 7;
        SCREEN_HEIGHT: integer := 5;
        PADDLE_WIDTH: integer := 2;
        PADDLE_Y: integer := 0;
        NUMBER_LIVES: integer := 3);
    Port(
        -- Input signals
        CLK_SLOW: in STD_LOGIC;
        CLK_FAST: in STD_LOGIC;

        MOVE_LEFT: in STD_LOGIC;
        MOVE_RIGHT: in STD_LOGIC;

        START: in STD_LOGIC;

        -- Output signals
        LED_ROW: out STD_LOGIC_VECTOR(SCREEN_HEIGHT - 1 downto 0);
        LED_COL: out STD_LOGIC_VECTOR(SCREEN_WIDTH - 1 downto 0);

        LED_LIVES: out STD_LOGIC_VECTOR(NUMBER_LIVES - 1 downto 0));
end pong;

architecture behavioral of pong is
    -- Internal signals for game logic
    signal BALL_X: integer range 0 to SCREEN_WIDTH - 1 := 0;
    signal BALL_Y: integer range 0 to SCREEN_HEIGHT - 1 := SCREEN_HEIGHT - 1;

    signal PADDLE_X: integer range 0 to SCREEN_WIDTH - PADDLE_WIDTH := 0;

    signal RAND_X: integer range 0 to SCREEN_WIDTH - 1 := 0;

    type direction is (up, down);
    signal BALL_DIRECTION: direction := down;

    type state is (game_start, game_play, game_over);
    signal GAME_STATE: state := game_start;

    signal LIVES: integer range 0 to NUMBER_LIVES := NUMBER_LIVES;
     
begin
    -- Random number generator process
    random: process(CLK_FAST)
    begin
        if rising_edge(CLK_FAST) then
            -- Playing the game
            if GAME_STATE = game_play then
                if(RAND_X = SCREEN_WIDTH - 1) then
                    RAND_X <= 0;
                else 
                    RAND_X <= RAND_X + 1;
                end if; 
            end if;
        end if;
    end process random;
    
    
    -- Paddle movement process
    paddle_movement: process(CLK_SLOW)
    begin
        if rising_edge(CLK_SLOW) then
            -- Playing the game
            if GAME_STATE = game_play then
                if MOVE_LEFT = '0' then
                    if not (PADDLE_X = 0) then
                        PADDLE_X <= PADDLE_X - 1;
                    end if;
                elsif MOVE_RIGHT = '0' then
                    if not (PADDLE_X = SCREEN_WIDTH - PADDLE_WIDTH) then
                        PADDLE_X <= PADDLE_X + 1;
                    end if;
                end if;
            end if;
        end if;
    end process paddle_movement;

    -- Ball movement process
    ball_movement: process(CLK_SLOW)
    begin
        if rising_edge(CLK_SLOW) then
            -- Playing the game
            if GAME_STATE = game_play then
                if BALL_Y = 0 then
                    -- Paddle colision
                    if BALL_X = PADDLE_X or BALL_X = PADDLE_X+1 then
                        BALL_DIRECTION <= up;
                        BALL_Y <= BALL_Y + 1;
                    -- Bottom colision
                    else
                        LIVES <= LIVES - 1;
                        BALL_X <= RAND_X;
                        BALL_Y <= SCREEN_HEIGHT - 1;
                    end if;
                -- Top colision
                elsif BALL_Y = SCREEN_HEIGHT then
                    BALL_DIRECTION <= down;
                    BALL_X <= RAND_X;
                    BALL_Y <= BALL_Y - 1;
                -- No colision
                else
                    case BALL_DIRECTION is
                        when up =>
                            BALL_Y <= BALL_Y + 1;
                        when down =>
                            BALL_Y <= BALL_Y - 1;
                    end case;
                end if;
            end if;

            -- Set up the game for restart
            if GAME_STATE = game_start then
                BALL_Y <= SCREEN_HEIGHT - 1;
                LIVES <= NUMBER_LIVES;
            end if;
        end if;
    end process ball_movement;

    -- Display process
    display: process(CLK_FAST)
        -- Counter to display alternatively
        variable COUNTER : integer range 0 to 3 := 0;
    begin
        if rising_edge(CLK_FAST) then
            case GAME_STATE is
                -- Ready to play the game
                when game_start =>
                    -- Initialize control signals to draw "P"
                    if COUNTER = 3 then
                        LED_COL <= "0010000";
                        LED_ROW <= "10000";
                        COUNTER := 0;
                    end if;
                      
                    if COUNTER = 2 then
                        LED_COL <= "0001100";
                        LED_ROW <= "01011";
                    end if;
                      
                    if COUNTER = 1 then
                        LED_COL <= "0010100";
                        LED_ROW <="00011";
                    end if;

                    COUNTER:= COUNTER + 1;
                -- Playing the game
                when game_play =>
                    if LIVES /= 0 then
                        if COUNTER = 3 then
                            -- Paddle display
                            LED_COL <= "0000000"; 
                            LED_ROW <= "11110";

                            -- Set control signals for paddle
                            LED_COL(PADDLE_X) <= '1';
                            LED_COL(PADDLE_X + 1) <= '1'; -- Paddle width is 2

                            COUNTER := 0;
                        else
                            -- Ball display
                            LED_COL <= "0000000"; 
                            LED_ROW <= "11111";

                            -- Set control signals for ball
                            LED_COL(BALL_X) <= '1';
                            LED_ROW(BALL_Y) <= '0';

                            COUNTER := COUNTER + 1;
                        end if;
                    end if;
                -- Game lost  
                when game_over =>
                    -- Initialize control signals to draw a cross
                    if COUNTER = 3 then
                        LED_COL <= "0100010";
                        LED_ROW <= "01110";
                        COUNTER := 0;
                    end if;
                    
                    if COUNTER = 2 then
                        LED_COL <= "0010100";
                        LED_ROW <= "10101";                             
                    end if;

                    if COUNTER = 1 then
                        LED_COL <= "0001000";
                        LED_ROW <= "11011";
                    end if;
                    
                    COUNTER := COUNTER + 1;
            end case;
        end if;
    end process display;
     
    state_management: process(CLK_SLOW)
    begin
        if rising_edge(CLK_SLOW) then
            case GAME_STATE is
            
                -- Ready to play the game
                when game_start =>
                    -- Start the game  
                    if START = '0' then
                        GAME_STATE <= game_play;
                    end if;
                    
                -- Playing the game
                when game_play =>  
                    -- Lives management
                    for i in 0 to NUMBER_LIVES - 1 loop
                        if i < LIVES then
                            LED_LIVES(i) <= '1';
                        else
                            LED_LIVES(i) <= '0';
                        end if;
                    end loop;
                    
                    -- Game lost
                    if LIVES = 0 then
                        GAME_STATE <= game_over;
                    end if;

                    -- Reset the game
                    if START = '0' then
                        GAME_STATE <= game_start; 
                    end if;
     
               -- Game lost
               when game_over =>
                    -- Reset the game
                    if START = '0' then
                        GAME_STATE <= game_start;
                    end if;
            end case;
        end if;
    end process state_management;
end architecture behavioral;