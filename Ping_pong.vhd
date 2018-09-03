--VHDL VGA PING PONG demo

library IEEE; 
use IEEE.STD_LOGIC_1164.all; 
use IEEE.STD_LOGIC_ARITH.all;

entity PONG is 
PORT (
	VGA_CLK : in std_logic;
	VGA_HS, VGA_VS	: out std_logic;
	VGA_R  : out std_logic;
	VGA_G  : out std_logic;
	VGA_B  : out std_logic;
   
   LeftPaddle : in integer;
   RightPaddle : in integer;

   KB_CLK : in std_logic;
   KB_DATA : in std_logic

);

end PONG;

architecture main of PONG is

component Kbd_ps2 is
    Port ( Clock : in  STD_LOGIC;
           KbdClock : in  STD_LOGIC;
           KbdData : in  STD_LOGIC;
           LPaddleDir : out integer;
           RPaddleDir : out integer;
           GamePaused : out integer);
end component;

 --sygnaly dla monitora
signal halfClock : STD_LOGIC;
--signal vga_clk_signal : std_logic:='0'; 
signal reset : std_logic:='0'; 
signal new_frame : std_logic:='0';

signal hsyncEnable : STD_LOGIC;
signal vsyncEnable : STD_LOGIC;

signal set_red, set_green, set_blue : std_logic;
signal pos_x : integer range 0 to 800:=0;
signal pos_y : integer range 0 to 525:=0;
signal real_x : integer range 0 to 640:=0;
signal real_y : integer range 0 to 480:=0;


--sygnaly dla paletki, ograniczone przez ramki, zdefiniowane w VGA_controler.vhd
signal paddle_x1 : integer range 0 to 640:= 35;
signal paddle_y1 : integer range 0 to 480:= 200;
signal paddle_x2 : integer range 0 to 640:= 590;
signal paddle_y2 : integer range 0 to 480:= 200;

constant paddle_height : integer := 80;
constant paddle_width : integer := 15;
constant lifeBar_height : integer := 5;
constant lifeBar_width : integer := 50;
constant lifeBar_y : integer := 50;
constant leftLifeBar_x : integer := 100;
constant rightLifeBar_x : integer := 540;

signal leftPaddleDir : integer := 0;
signal rightPaddleDir : integer := 0;
signal gamePaused : integer := 0;
--signal freezeGame : STD_LOGIC :='0';

constant maxHp : integer := 3;
signal leftHp : integer := maxHp;
signal rightHp : integer := maxHp;

signal paddleClock : STD_LOGIC;
signal paddleClockCounter : integer range 0 to 100000 :=0;
signal ballClock : STD_LOGIC;
signal ballClockCounter : integer range 0 to 50000 :=0;

signal ball_x : integer range -10 to 650:= 312;
signal ball_y : integer range 0 to 480:= 236;
signal ballSpeed_x : integer range -4 to 4 := 1;
signal ballSpeed_y : integer range -4 to 4 := 1;
constant ballSpeed_max : integer := 4;
--signal reset_ball : STD_LOGIC;

begin


   kbController : Kbd_ps2 port map (VGA_CLK , KB_CLK, KB_DATA, leftPaddleDir, rightPaddleDir, gamePaused); 

	vga_timing : process(vga_clk)
	begin

		if rising_edge(vga_clk) then

		--rysowanie ekranu poziomo

			if (pos_x < 799) then --pozostajemy w linii

				new_frame <= '0';

				pos_x <= pos_x + 1; --przesuwamy sie w prawo
			else
				pos_x <= 0;  --przechodzimy do nowej linii

		--rysowanie ekranu pionowo

				if (pos_y < 524) then
					pos_y <= pos_y + 1; --przesuwamy sie
				else 
					pos_y <= 0;  --zerujemy wysokosc i odswiezamy ekran
					new_frame <= '1';
				end if;
			end if;

--pusty ekran w zakresie FP+BP+Sync
			if ( (pos_x >= 0 and pos_x < 144) or (pos_x >= 784 and pos_x < 800) or (pos_y>= 0 and pos_y < 35) or (pos_y>= 515 and pos_y < 525)) then
				set_red <= '0';
				set_green <= '0';
				set_blue <= '0';

			--widoczna czesc ekranu		
			else
			--rysowanie ramki o grubosci 5 pix
				if ( (real_x >= 0 and real_x< 5 ) or (real_y >= 0 and real_y < 5 ) or (real_x >= 635 and real_x < 640 ) or (real_y >= 475 and real_y < 480 ) ) then
					if(real_y >= 160 and real_y <320) then
						set_red <= '0'; --bramka
						set_green <= '0';
						set_blue <= '0';
					else
						-- R+G+B == bialy kolor
						set_red <= '1';
						set_green <= '1';
						set_blue <= '1';
					end if;
				else
					set_red <= '0'; --wewnatrz ramki pole jest czarne
					set_green <= '0';
					set_blue <= '0';
					--rysowanie paletek
					if ( (real_x >= paddle_x1 and real_x < paddle_x1 + 15) and (real_y >= paddle_y1 and real_y < paddle_y1 + 80) ) then
						set_red <= '1';
					elsif ( (real_x >= paddle_x2 and real_x < paddle_x2 + 15) and (real_y >= paddle_y2 and real_y < paddle_y2 + 80) ) then
						set_blue <= '1';
					--rysowanie pileczki
					elsif ((real_x >=ball_x and real_x <ball_x+8) and (real_y >= ball_y and real_y <ball_y+8)) then
						set_green <= '1';
					--rysowanie paskow zycia
					elsif (real_x >= leftLifeBar_x and real_x < leftLifeBar_x + leftHp * lifeBar_width) and (real_y >= lifeBar_y and real_y < lifeBar_y + lifeBar_height) then
                  set_green <= '1';
					elsif (real_x < rightLifeBar_x and real_x >= rightLifeBar_x - rightHp * lifeBar_width) and (real_y >= lifeBar_y and real_y < lifeBar_y + lifeBar_height) then
						set_green <= '1';
					end if;       
				end if;		
			end if;	
		end if;
	end process;
   
   MoveLeftPaddle : process(paddleClock)
   begin
      if paddleClock'event and paddleClock = '1' then
         if paddle_y1 + leftPaddleDir > 5 and paddle_y1 + leftPaddleDir < 475 - paddle_height then
            paddle_y1 <= paddle_y1 + leftPaddleDir;
         end if;
      end if;   
   
   end process MoveLeftPaddle;
   
   MoveRightPaddle : process(paddleClock)
   begin
      if paddleClock'event and paddleClock = '1' then
         if paddle_y2 + rightPaddleDir > 5 and paddle_y2 + rightPaddleDir < 475 - paddle_height then
            paddle_y2 <= paddle_y2 + rightPaddleDir;
         end if;
      end if;
   end process MoveRightPaddle;
   
   MoveBall : process(ballClock)
   begin
      if ballClock'event and ballClock = '1' then
         if leftHp = 0 or rightHp = 0 then
            ball_x <= 320;
            ball_y <= 240;
            ballSpeed_x <= 1;
            ballSpeed_y <= 1;
            leftHp <= maxHp;
            rightHp <= maxHp;
         else
            if ball_x + 8 > paddle_x2 and ball_x < paddle_x2 + paddle_width and ball_y + 8 > paddle_y2 and ball_y < paddle_y2 + paddle_height then
               if ballSpeed_x > 0 then
                  ball_x <= paddle_x2 - 8;
               elsif ballSpeed_x < 0 then
                  ball_x <= paddle_x2 + paddle_width;
               end if;
               ballSpeed_y <= (ball_y - (paddle_y2 + paddle_height / 2)) / 16;
               ballSpeed_x <= ballSpeed_y - ballSpeed_max / 2;
            elsif ball_x < paddle_x1 + paddle_width and ball_x + 8 > paddle_x1 and ball_y + 8 > paddle_y1 and ball_y < paddle_y1 + paddle_height then
               if ballSpeed_x > 0 then
                  ball_x <= paddle_x1 - 8;
               elsif ballSpeed_x < 0 then
                  ball_x <= paddle_x1 + paddle_width;
               end if;
               ballSpeed_y <= (ball_y - (paddle_y1 + paddle_height / 2)) / 16;
               ballSpeed_x <= ballSpeed_max / 2 - ballSpeed_y;
            elsif (ball_x + ballSpeed_x < 6 and ball_x + ballSpeed_x > -3) and (ball_y < 160 or ball_y > 320 - 8) then
               ball_x <= 5;
               ballSpeed_x <= -ballSpeed_x;
            elsif (ball_x + ballSpeed_x > 634 - 8 and ball_x + ballSpeed_x < 640 - 8) and (ball_y < 160 or ball_y > 320 - 8) then
               ball_x <= 635 - 8;
               ballSpeed_x <= -ballSpeed_x;
            elsif ball_x < -5 then
               leftHp <= leftHp - 1;
               ball_x <= 320;
               ball_y <= 240;
               ballSpeed_x <= 1;
               ballSpeed_y <= 1;
               --reset_ball <= '1';
            elsif ball_x > 645 then
               rightHp <= rightHp - 1;
               ball_x <= 320;
               ball_y <= 240;
               ballSpeed_x <= 1;
               ballSpeed_y <= 1;
               --reset_ball <= '1';
            else
               ball_x <= ball_x + ballSpeed_x;
            end if;
            if ball_y < 5 then
               ballSpeed_y <= -ballSpeed_y;
               ball_y <= 5;
            elsif ball_y > 475 then
               ballSpeed_y <= -ballSpeed_y;
               ball_y <= 475;
            else
               ball_y <= ball_y + ballSpeed_y;
            end if;
            if ballSpeed_x = 0 then
               if ball_x < 320 then
                  ballSpeed_x <= 1;
               elsif ball_x >= 320 then
                  ballSpeed_x <= -1;
               end if;
            end if;
         end if;   
      end if;
   end process MoveBall;
	
	--RestartGame : process(freezeGame)
	--begin
		--if freezeGame = '1' then
			--if gamePaused = 1 then
				--freezeGame <= '0';
			--end if;
		--end if;	
	--end process RestartGame;
   
-- Half the clock
	clockScaler : process(vga_clk)
	begin
		if vga_clk'event and vga_clk = '1' then
			halfClock <= not halfClock;
		end if;
	end process clockScaler;
   
   paddleClockScaler : process(vga_clk)
   begin
      if vga_clk'event and vga_clk = '1' then
         paddleClockCounter <= paddleClockCounter + 1;
         
         if paddleClockCounter = 100000 then
            paddleClock <= not paddleClock;
            paddleClockCounter <= 0;
         end if;
      end if;
   end process paddleClockScaler;
   
   ballClockScaler : process(vga_clk)
   begin
      if vga_clk'event and vga_clk = '1' then
         ballClockCounter <= ballClockCounter + 1;
         
         if ballClockCounter = 50000 then
            ballClock <= not ballClock;
            ballClockCounter <= 0;
         end if;
      end if;
   end process ballClockScaler;
	
	vgaSync : process(halfClock, pos_x, pos_y)
	begin
		if halfClock'event and halfClock = '1' then
			if pos_x > 0 and pos_x < 97 then
				hsyncEnable <= '0';
			else
				hsyncEnable <= '1';
			end if;
			
			if (pos_y > 0 and pos_y < 3) then
				vsyncEnable <= '0';
			else
				vsyncEnable <= '1';
			end if;
		end if;
	end process vgaSync;
	
	-- VGA Controller
	draw : process(pos_x, pos_y, halfClock)
	begin
		if halfClock'event and halfClock = '1' then
			VGA_HS <= hsyncEnable;
			VGA_VS <= vsyncEnable;
		
			if (real_x < 640 and real_y < 480) then
				VGA_R <= set_red;
				VGA_G <= set_green;
				VGA_B <= set_blue;
			else
				VGA_R <= '0';
				VGA_G <= '0';
				VGA_B <= '0';
			end if;
		end if;
	end process draw;
   
   calculateOffset : process(pos_x,pos_y)
   begin
      real_x <= pos_x -144;
      real_y <= pos_y -35;
      end process calculateOffset;

end main;