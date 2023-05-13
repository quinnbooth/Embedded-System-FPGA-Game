/*
 * Avalon memory-mapped peripheral that generates Battle City tank game visuals
 *
 * Contributors:
 *
 * Quinn Booth
 * Columbia University
 *
 * Ganesan Narayanan
 * Columbia University
 *
 * Ana Maria Rodriguez
 * Columbia University
 *
 * Skeleton by:
 * Stephen A. Edwards
 * Columbia University
 *
 */

module vga_ball(input logic        clk,
	        input logic 	   reset,
		input logic [15:0]  writedata,
		input logic 	   write,
		input 		   chipselect,
		input logic [3:0]  address,

		input L_READY,
		input R_READY,
		output logic [15:0] L_DATA,
		output logic [15:0] R_DATA,
		output logic L_VALID,
		output logic R_VALID,

		output logic [7:0] VGA_R, VGA_G, VGA_B,
		output logic 	   VGA_CLK, VGA_HS, VGA_VS,
		                   VGA_BLANK_n,
		output logic 	   VGA_SYNC_n);

   logic [10:0]	   hcount;
   logic [9:0]     vcount;

   logic [7:0] 	   background_r, background_g, background_b;

   logic [15:0]    wall, misc, p1_tankl, p1_tankd, p2_tankl, p2_tankd, p1_bulletl, p1_bulletd, p2_bulletl, p2_bulletd;
	
   vga_counters counters(.clk50(clk), .*);


//////// AUDIO ///////////////////////////////////////////////////////

	logic [13:0] jingle_address;
	logic [15:0] jingle_data;
	soc_system_jingle_sound(.address(jingle_address),.clk(clk),.clken(1),.reset_req(0),.readdata(jingle_data));

	logic [13:0] explode_address;
	logic [15:0] explode_data;
	soc_system_explode_sound(.address(explode_address),.clk(clk),.clken(1),.reset_req(0),.readdata(explode_data));

	logic [13:0] crawl_address;
	logic [15:0] crawl_data;
	soc_system_crawl_sound(.address(crawl_address),.clk(clk),.clken(1),.reset_req(0),.readdata(crawl_data));

	logic [14:0] shoot_address;
	logic [15:0] shoot_data;
	soc_system_shoot_sound(.address(shoot_address),.clk(clk),.clken(1),.reset_req(0),.readdata(shoot_data));

	reg [11:0] counter;
	logic playing_jingle;
	logic playing_explode;
	logic playing_crawl;
	logic playing_bullet1;
	logic playing_bullet2;
	logic playing_initial_jingle;

	logic jingle_ready;
	logic explode_ready;
	logic bullet1_ready;
	logic bullet2_ready;

	always_ff @(posedge clk) begin

		if (reset) begin

			counter <= 0;
			L_VALID <= 0;
			R_VALID <= 0;
			playing_jingle <= 0;
			playing_explode <= 0;
			playing_crawl <= 0;
			playing_bullet1 <= 0;
			playing_bullet2 <= 0;
			playing_initial_jingle <= 1;
			jingle_address <= 0;
			explode_address <= 0;
			crawl_address <= 0;
			shoot_address <= 0;
			jingle_ready <= 1;
			explode_ready <= 1;
			bullet1_ready <= 1;
			bullet2_ready <= 1;

		end
		else if (L_READY == 1 && R_READY == 1 && counter < 3125) begin

			counter <= counter + 1;
			L_VALID <= 0;
			R_VALID <= 0;

		end
		else if (L_READY == 1 && R_READY == 1 && counter >= 3125) begin

			counter <= 0;
			L_VALID <= 1;
			R_VALID <= 1;

			// Play the opening jingle on boot
			if (playing_initial_jingle == 1) begin

				if (jingle_address > 15000) begin
					jingle_address <= 0;
					playing_initial_jingle <= 0;
				end
				else begin
					jingle_address <= jingle_address + 1;
				end
				L_DATA <= jingle_data;
				R_DATA <= jingle_data;

			end

			// After the initial jingle, handle audio on game events
			else begin

				// Setting Flags

				if (wall_on == 1'b1 && jingle_ready == 1'b1) begin

					if (playing_explode == 0 && playing_bullet1 == 0 && playing_bullet2 == 0) begin

						playing_jingle <= 1;
						playing_explode <= 0;
						playing_bullet1 <= 0;
						playing_bullet2 <= 0;	
				
						jingle_ready <= 0;

					end

				end
				else if (explosion_on == 1'b1 && explode_ready == 1'b1) begin
		
					if (playing_jingle == 0 && playing_bullet1 == 0 && playing_bullet2 == 0) begin

						playing_jingle <= 0;
						playing_explode <= 1;
						playing_bullet1 <= 0;
						playing_bullet2 <= 0;	
				
						explode_ready <= 0;
					
					end
	
				end
				else if (bullet1_on == 1'b1 && bullet1_ready == 1'b1) begin

					if (playing_jingle == 0 && playing_explode == 0 && playing_bullet2 == 0) begin

						playing_jingle <= 0;
						playing_explode <= 0;
						playing_bullet1 <= 1;
						playing_bullet2 <= 0;	

						bullet1_ready <= 0;

					end

				end
				else if (bullet2_on == 1'b1 && bullet2_ready == 1'b1) begin

					if (playing_jingle == 0 && playing_bullet1 == 0 && playing_explode == 0) begin	
				
						playing_jingle <= 0;
						playing_explode <= 0;
						playing_bullet1 <= 0;
						playing_bullet2 <= 1;	

						bullet2_ready <= 0;

					end

				end
				
				// These _on flags represent when in game events are "on" or occuring
				// Only allow the audio to play again once they drop to 0, so that there is 1 audio per event

				if (wall_on == 1'b0) begin

					jingle_ready <= 1;

				end

				if (explosion_on == 1'b0) begin

					explode_ready <= 1;

				end

				if (bullet1_on == 1'b0) begin

					bullet1_ready <= 1;

				end

				if (bullet2_on == 1'b0) begin

					bullet2_ready <= 1;

				end
				

				// Playing Audio

				if (playing_jingle == 1) begin
					if (jingle_address > 15000) begin
						jingle_address <= 0;
						playing_jingle <= 0;
					end
					else begin
						jingle_address <= jingle_address + 1;
					end
					L_DATA <= jingle_data;
					R_DATA <= jingle_data;

				end
				else if (playing_explode == 1) begin
					if (explode_address > 15000) begin
						explode_address <= 0;
						playing_explode <= 0;
					end
					else begin
						explode_address <= explode_address + 1;
					end
					L_DATA <= explode_data;
					R_DATA <= explode_data;
				end
				else if (playing_bullet1 == 1) begin
					if (shoot_address > 15000) begin
						shoot_address <= 0;
						playing_bullet1 <= 0;
					end
					else begin
						shoot_address <= shoot_address + 1;
					end
					L_DATA <= shoot_data;
					R_DATA <= shoot_data;
				end
				else if (playing_bullet2 == 1) begin
					if (shoot_address > 15000) begin
						shoot_address <= 0;
						playing_bullet2 <= 0;
					end
					else begin
						shoot_address <= shoot_address + 1;
					end
					L_DATA <= shoot_data;
					R_DATA <= shoot_data;
				end

			end

		end
		else begin

			L_VALID <= 0;
			R_VALID <= 0;

		end
	end

//////// AUDIO ///////////////////////////////////////////////////////


   always_ff @(posedge clk)
     if (reset) begin
      background_r <= 8'h00;
      background_g <= 8'h00;
      background_b <= 8'h00;
	    // set any default values needed for startup
     end 
     else if (chipselect && write)
       case (address)
        4'h0 : wall <= writedata;
        4'h1 : misc <= writedata;
        4'h2 : p1_tankl <= writedata;
        4'h3 : p1_tankd <= writedata;
        4'h4 : p2_tankl <= writedata;
        4'h5 : p2_tankd <= writedata;
        4'h6 : p1_bulletl <= writedata;
        4'h7 : p1_bulletd <= writedata;
        4'h8 : p2_bulletl <= writedata;
        4'h9 : p2_bulletd <= writedata;
       endcase

    logic [11:0] p1tank_address;
    logic [7:0] p1tank_output;
    soc_system_p1tank_unit p1tank_unit(.address(p1tank_address),.clk(clk),.clken(1),.reset_req(0),.readdata(p1tank_output));
    logic [1:0] p1tank_en;

    logic [9:0] p1tank_x;
    logic [9:0] p1tank_y;
    logic [1:0] p1tank_dir;

    logic [11:0] p2tank_address;
    logic [7:0] p2tank_output;
    soc_system_p2tank_unit p2tank_unit(.address(p2tank_address),.clk(clk),.clken(1),.reset_req(0),.readdata(p2tank_output));
    logic [1:0] p2tank_en;

    logic [9:0] p2tank_x;
    logic [9:0] p2tank_y;
    logic [1:0] p2tank_dir;

    logic [9:0] map_address;
    logic [7:0] map_output;
    soc_system_map_unit map_unit(.address(map_address),.clk(clk),.clken(1),.reset_req(0),.readdata(map_output));
    logic [1:0] map_en;

    logic [1:0] map_num;

    logic [9:0] wall_address;
    logic [7:0] wall_output;
    soc_system_wall_unit wall_unit(.address(wall_address),.clk(clk),.clken(1),.reset_req(0),.readdata(wall_output));
    logic [1:0] wall_en;
    logic wall_on;

    logic [4:0] tile32_x;
    logic [4:0] tile32_y;

    logic [12:0] score_address;
    logic [7:0] score_output;
    soc_system_score_unit score_unit(.address(score_address),.clk(clk),.clken(1),.reset_req(0),.readdata(score_output));
    logic [1:0] score_en;
    logic score1_on;
    logic score2_on;

    logic [10:0] stage_address;
    logic [7:0] stage_output;
    soc_system_stage_unit stage_unit(.address(stage_address),.clk(clk),.clken(1),.reset_req(0),.readdata(stage_output));
    logic [1:0] stage_en;

    logic [5:0] tile16_x;
    logic [5:0] tile16_y;

    logic [10:0] num_address;
    logic [7:0] num_output;
    soc_system_num_unit num_unit(.address(num_address),.clk(clk),.clken(1),.reset_req(0),.readdata(num_output));
    logic [1:0] num_en;

    logic [1:0] stage_num;

    logic [2:0] p1_score;
    logic [2:0] p2_score;

    logic [9:0] p1bullet_x;
    logic [9:0] p1bullet_y;
    logic [9:0] p2bullet_x;
    logic [9:0] p2bullet_y;

    logic [9:0] bullet1_xdif;
    logic [9:0] bullet1_ydif;
    logic [9:0] bullet2_xdif;
    logic [9:0] bullet2_ydif;

    logic [1:0] p1bullet_en;
    logic [1:0] p2bullet_en;

    logic bullet1_on;
    logic bullet2_on;
    
    logic [10:0] ending_address;
    logic [7:0] ending_output;
    soc_system_ending_unit ending_unit(.address(ending_address),.clk(clk),.clken(1),.reset_req(0),.readdata(ending_output));
    logic [1:0] ending_en;
    logic ending_on;

    logic [11:0] explosion_address;
    logic [7:0] explosion_output;
    soc_system_explosion_unit explosion_unit(.address(explosion_address),.clk(clk),.clken(1),.reset_req(0),.readdata(explosion_output));
    logic [1:0] explosion_en;
    logic explosion_on;

    logic [9:0] explosion_x;
    logic [9:0] explosion_y;
    logic [1:0] explosion_num;
    

    // ptank_dir:
    // 2'b0 --> up
    // 2'b1 --> down
    // 2'b2 --> left
    // 2'b3 --> right

    always_comb begin
	
      p1tank_x = p1_tankl[15:8] << 2;
      p1tank_y = p1_tankl[7:0] << 2;
      p1tank_dir = p1_tankd[15:14];

      p2tank_x = p2_tankl[15:8] << 2;
      p2tank_y = p2_tankl[7:0] << 2;
      p2tank_dir = p2_tankd[15:14];

      tile32_x = hcount[10:1] >> 5;
      tile32_y = vcount[9:0] >> 5;

      tile16_x = hcount[10:1] >> 4;
      tile16_y = vcount[9:0] >> 4;

      stage_num = wall[15:14];

      p1_score = wall[13:11];
      p2_score = wall[10:8];

      p1bullet_x = p1_bulletl[15:8] << 2;
      p1bullet_y = p1_bulletl[7:0] << 2;

      p2bullet_x = p2_bulletl[15:8] << 2;
      p2bullet_y = p2_bulletl[7:0] << 2;

      bullet1_xdif = (p1bullet_x > hcount[10:1]) ? (p1bullet_x - hcount[10:1]) : (hcount[10:1] - p1bullet_x);
      bullet1_ydif = (p1bullet_y > vcount[9:0]) ? (p1bullet_y - vcount[9:0]) : (vcount[9:0] - p1bullet_y);

      bullet2_xdif = (p2bullet_x > hcount[10:1]) ? (p2bullet_x - hcount[10:1]) : (hcount[10:1] - p2bullet_x);
      bullet2_ydif = (p2bullet_y > vcount[9:0]) ? (p2bullet_y - vcount[9:0]) : (vcount[9:0] - p2bullet_y);

      explosion_x = misc[15:9] << 3;
      explosion_y = misc[8:2] << 3;

      explosion_num = wall[7:6];

      ending_on = wall[5];
      explosion_on = wall[4];
      score1_on = wall[3];
      wall_on = wall[2];
      score2_on = wall[1];

      bullet1_on = p1_bulletd[15];
      bullet2_on = p2_bulletd[15];

      map_num = misc[1:0];

      map_en = 2'b1;

      if (map_num == 2'b00)
	map_address = tile32_x + tile32_y * 20;
      else if (map_num == 2'b01)
        map_address = tile32_x + tile32_y * 20 + 300;
      else
        map_address = tile32_x + tile32_y * 20 + 600;

    end

    always_ff @(posedge clk) begin

      if (hcount[10:1] >= p1tank_x && hcount[10:1] <= (p1tank_x + 10'd31) && vcount[9:0] >= p1tank_y && vcount[9:0] <= (p1tank_y + 10'd31) ) begin
        
        p1tank_en <= 2'b1;
	
	case(p1tank_dir)
	 2'b00 : p1tank_address <= hcount[10:1] - p1tank_x + (vcount[9:0] - p1tank_y) * 32;
         2'b01 : p1tank_address <= hcount[10:1] - p1tank_x + (vcount[9:0] - p1tank_y) * 32 + 1024;
         2'b10 : p1tank_address <= hcount[10:1] - p1tank_x + (vcount[9:0] - p1tank_y) * 32 + 2048;
         2'b11 : p1tank_address <= hcount[10:1] - p1tank_x + (vcount[9:0] - p1tank_y) * 32 + 3072;
	endcase
      
      end

      else begin

        p1tank_en <= 2'b0;

      end

    end

    always_ff @(posedge clk) begin

      if (hcount[10:1] >= p2tank_x && hcount[10:1] <= (p2tank_x + 10'd31) && vcount[9:0] >= p2tank_y && vcount[9:0] <= (p2tank_y + 10'd31) ) begin
        
        p2tank_en <= 2'b1;
	
	case(p2tank_dir)
	 2'b00 : p2tank_address <= hcount[10:1] - p2tank_x + (vcount[9:0] - p2tank_y) * 32;
         2'b01 : p2tank_address <= hcount[10:1] - p2tank_x + (vcount[9:0] - p2tank_y) * 32 + 1024;
         2'b10 : p2tank_address <= hcount[10:1] - p2tank_x + (vcount[9:0] - p2tank_y) * 32 + 2048;
         2'b11 : p2tank_address <= hcount[10:1] - p2tank_x + (vcount[9:0] - p2tank_y) * 32 + 3072;
	endcase
      
      end

      else begin

        p2tank_en <= 2'b0;

      end

    end


    always_ff @(posedge clk) begin

      if (hcount[10:1] >= explosion_x && hcount[10:1] <= (explosion_x + 10'd31) && vcount[9:0] >= explosion_y && vcount[9:0] <= (explosion_y + 10'd31) && explosion_on == 1'b1) begin
        
        explosion_en <= 2'b1;
	
	case(explosion_num)
	       2'b00 : explosion_address <= hcount[10:1] - explosion_x + (vcount[9:0] - explosion_y) * 32;
         2'b01 : explosion_address <= hcount[10:1] - explosion_x + (vcount[9:0] - explosion_y) * 32 + 1024;
         2'b10 : explosion_address <= hcount[10:1] - explosion_x + (vcount[9:0] - explosion_y) * 32 + 2048;
	endcase
      
      end

      else begin

        explosion_en <= 2'b0;

      end

    end


    always_ff @(posedge clk) begin

      if (tile32_x >= 6'd9 && tile32_x <= 6'd10 && tile32_y == 6'd7 && ending_on == 1'b1) begin
              
        ending_en <= 2'b1;
        ending_address <= hcount[5:1] + vcount[4:0] * 32 + (tile32_x - 6'd9) * 1024;
      
      end

      else begin

        ending_en <= 2'b0;

      end

    end



    always_ff @(posedge clk) begin

      if (tile16_x >= 6'd17 && tile16_x <= 6'd21 && tile16_y == 6'd0) begin
              
        stage_en <= 2'b1;
        stage_address <= hcount[4:1] + vcount[3:0] * 16 + (tile16_x - 6'd17) * 256;
      
      end

      else begin

        stage_en <= 2'b0;

      end

    end


    always_ff @(posedge clk) begin

      if (tile16_x == 6'd22 && tile16_y == 6'd0) begin
              
        num_en <= 2'b1;

        case(stage_num)
          2'b00 : num_address <= hcount[4:1] + vcount[3:0] * 16 + 256;
          2'b01 : num_address <= hcount[4:1] + vcount[3:0] * 16 + 512;
          2'b10 : num_address <= hcount[4:1] + vcount[3:0] * 16 + 768;
          //2'b11 : num_address <= hcount[4:1] + vcount[3:0] * 16 + 1024;
        endcase
      
      end

      else begin

        num_en <= 2'b0;

      end

    end


    always_ff @(posedge clk) begin

      if (tile32_x == 5'd2 && tile32_y == 5'd0 && score1_on == 1'b1) begin
              
        score_en <= 2'b1;

        case(p1_score)
          3'b000 : score_address <= hcount[5:1] + vcount[4:0] * 32;
          3'b001 : score_address <= hcount[5:1] + vcount[4:0] * 32 + 1024;
          3'b010 : score_address <= hcount[5:1] + vcount[4:0] * 32 + 2048;
          3'b011 : score_address <= hcount[5:1] + vcount[4:0] * 32 + 3072;
          3'b100 : score_address <= hcount[5:1] + vcount[4:0] * 32 + 4096;
        endcase
      
      end

      else if (tile32_x == 5'd17 && tile32_y == 5'd0 && score2_on == 1'b1) begin
              
        score_en <= 2'b1;

        case(p2_score)
          3'b000 : score_address <= hcount[5:1] + vcount[4:0] * 32;
          3'b001 : score_address <= hcount[5:1] + vcount[4:0] * 32 + 1024;
          3'b010 : score_address <= hcount[5:1] + vcount[4:0] * 32 + 2048;
          3'b011 : score_address <= hcount[5:1] + vcount[4:0] * 32 + 3072;
          3'b100 : score_address <= hcount[5:1] + vcount[4:0] * 32 + 4096;
        endcase
      
      end

      else begin

        score_en <= 2'b0;

      end

    end


    always_ff @(posedge clk) begin

      if ( (bullet1_xdif < 5) && (bullet1_ydif < 5) && bullet1_on == 1'b1) begin

        p1bullet_en <= 2'b1;

      end

      else begin

        p1bullet_en <= 2'b0;

      end

    end

    always_ff @(posedge clk) begin

      if ( (bullet2_xdif < 5) && (bullet2_ydif < 5) && bullet2_on == 1'b1) begin

        p2bullet_en <= 2'b1;

      end

      else begin

        p2bullet_en <= 2'b0;

      end

    end

    /*
    always_ff @(posedge clk) begin

        map_en <= 2'b1;

        case(map_num)
          2'b00 : map_address <= tile32_x + tile32_y * 20;
          2'b01 : map_address <= tile32_x + tile32_y * 20 + 300;
          2'b10 : map_address <= tile32_x + tile32_y * 20 + 600;
        endcase

    end
    */

    always_ff @(posedge clk) begin

      if (map_en && map_output && wall_on == 1'b1) begin

        wall_en <= 2'b1;
        wall_address <= hcount[5:1] + vcount[4:0] * 32;

      end

      else begin

        wall_en <= 2'b0;

      end

    end


   // This is where the colors of the screen are being set
   always_comb begin
      {VGA_R, VGA_G, VGA_B} = {background_r, background_g, background_b};
      if (VGA_BLANK_n ) begin
	if (explosion_en) begin
          case (explosion_output)
            8'h00 : {VGA_R, VGA_G, VGA_B} = {8'hf0, 8'hf0, 8'hf0};
            8'h01 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'ha0, 8'ha0};
            8'h02 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'hb0};
            8'h03 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'ha0};
            8'h04 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h30, 8'h20};
            8'h05 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h20, 8'h20};
            8'h06 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'he0, 8'h90};
            8'h07 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h20};
            8'h08 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h10};
            8'h09 : {VGA_R, VGA_G, VGA_B} = {8'h90, 8'h40, 8'h00};
            8'h0a : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h60};
            8'h0b : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h00};
            8'h0c : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h00, 8'h00};
            8'h0d : {VGA_R, VGA_G, VGA_B} = {8'h50, 8'h00, 8'h70};
            8'h0e : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h40, 8'h40};
            8'h0f : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'h00};
          endcase
        end
        else if (ending_en) begin
          case (ending_output)
            8'h00 : {VGA_R, VGA_G, VGA_B} = {8'hf0, 8'hf0, 8'hf0};
            8'h01 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'ha0, 8'ha0};
            8'h02 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'hb0};
            8'h03 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'ha0};
            8'h04 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h30, 8'h20};
            8'h05 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h20, 8'h20};
            8'h06 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'he0, 8'h90};
            8'h07 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h20};
            8'h08 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h10};
            8'h09 : {VGA_R, VGA_G, VGA_B} = {8'h90, 8'h40, 8'h00};
            8'h0a : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h60};
            8'h0b : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h00};
            8'h0c : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h00, 8'h00};
            8'h0d : {VGA_R, VGA_G, VGA_B} = {8'h50, 8'h00, 8'h70};
            8'h0e : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h40, 8'h40};
            8'h0f : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'h00};
          endcase
        end
        else if (p1tank_en) begin
          case (p1tank_output)
            8'h00 : {VGA_R, VGA_G, VGA_B} = {8'hf0, 8'hf0, 8'hf0};
            8'h01 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'ha0, 8'ha0};
            8'h02 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'hb0};
            8'h03 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'ha0};
            8'h04 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h30, 8'h20};
            8'h05 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h20, 8'h20};
            8'h06 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'he0, 8'h90};
            8'h07 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h20};
            8'h08 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h10};
            8'h09 : {VGA_R, VGA_G, VGA_B} = {8'h90, 8'h40, 8'h00};
            8'h0a : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h60};
            8'h0b : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h00};
            8'h0c : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h00, 8'h00};
            8'h0d : {VGA_R, VGA_G, VGA_B} = {8'h50, 8'h00, 8'h70};
            8'h0e : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h40, 8'h40};
            8'h0f : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'h00};
          endcase
        end
	      else if (p2tank_en) begin
          case (p2tank_output)
            8'h00 : {VGA_R, VGA_G, VGA_B} = {8'hf0, 8'hf0, 8'hf0};
            8'h01 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'ha0, 8'ha0};
            8'h02 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'hb0};
            8'h03 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'ha0};
            8'h04 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h30, 8'h20};
            8'h05 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h20, 8'h20};
            8'h06 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'he0, 8'h90};
            8'h07 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h20};
            8'h08 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h10};
            8'h09 : {VGA_R, VGA_G, VGA_B} = {8'h90, 8'h40, 8'h00};
            8'h0a : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h60};
            8'h0b : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h00};
            8'h0c : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h00, 8'h00};
            8'h0d : {VGA_R, VGA_G, VGA_B} = {8'h50, 8'h00, 8'h70};
            8'h0e : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h40, 8'h40};
            8'h0f : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'h00};
          endcase
        end
        else if (wall_en) begin
          case (wall_output)
            8'h00 : {VGA_R, VGA_G, VGA_B} = {8'hf0, 8'hf0, 8'hf0};
            8'h01 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'ha0, 8'ha0};
            8'h02 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'hb0};
            8'h03 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'ha0};
            8'h04 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h30, 8'h20};
            8'h05 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h20, 8'h20};
            8'h06 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'he0, 8'h90};
            8'h07 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h20};
            8'h08 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h10};
            8'h09 : {VGA_R, VGA_G, VGA_B} = {8'h90, 8'h40, 8'h00};
            8'h0a : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h60};
            8'h0b : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h00};
            8'h0c : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h00, 8'h00};
            8'h0d : {VGA_R, VGA_G, VGA_B} = {8'h50, 8'h00, 8'h70};
            8'h0e : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h40, 8'h40};
            8'h0f : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'h00};
          endcase
        end
        else if (stage_en) begin
          case (stage_output)
            8'h00 : {VGA_R, VGA_G, VGA_B} = {8'hf0, 8'hf0, 8'hf0};
            8'h01 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'ha0, 8'ha0};
            8'h02 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'hb0};
            8'h03 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'ha0};
            8'h04 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h30, 8'h20};
            8'h05 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h20, 8'h20};
            8'h06 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'he0, 8'h90};
            8'h07 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h20};
            8'h08 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h10};
            8'h09 : {VGA_R, VGA_G, VGA_B} = {8'h90, 8'h40, 8'h00};
            8'h0a : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h60};
            8'h0b : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h00};
            8'h0c : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h00, 8'h00};
            8'h0d : {VGA_R, VGA_G, VGA_B} = {8'h50, 8'h00, 8'h70};
            8'h0e : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h40, 8'h40};
            8'h0f : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'h00};
          endcase
        end
        else if (num_en) begin
          case (num_output)
            8'h00 : {VGA_R, VGA_G, VGA_B} = {8'hf0, 8'hf0, 8'hf0};
            8'h01 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'ha0, 8'ha0};
            8'h02 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'hb0};
            8'h03 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'ha0};
            8'h04 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h30, 8'h20};
            8'h05 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h20, 8'h20};
            8'h06 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'he0, 8'h90};
            8'h07 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h20};
            8'h08 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h10};
            8'h09 : {VGA_R, VGA_G, VGA_B} = {8'h90, 8'h40, 8'h00};
            8'h0a : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h60};
            8'h0b : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h00};
            8'h0c : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h00, 8'h00};
            8'h0d : {VGA_R, VGA_G, VGA_B} = {8'h50, 8'h00, 8'h70};
            8'h0e : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h40, 8'h40};
            8'h0f : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'h00};
          endcase
        end
        else if (score_en) begin
          case (score_output)
            8'h00 : {VGA_R, VGA_G, VGA_B} = {8'hf0, 8'hf0, 8'hf0};
            8'h01 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'ha0, 8'ha0};
            8'h02 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'hb0};
            8'h03 : {VGA_R, VGA_G, VGA_B} = {8'ha0, 8'ha0, 8'ha0};
            8'h04 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h30, 8'h20};
            8'h05 : {VGA_R, VGA_G, VGA_B} = {8'hb0, 8'h20, 8'h20};
            8'h06 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'he0, 8'h90};
            8'h07 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h20};
            8'h08 : {VGA_R, VGA_G, VGA_B} = {8'he0, 8'h90, 8'h10};
            8'h09 : {VGA_R, VGA_G, VGA_B} = {8'h90, 8'h40, 8'h00};
            8'h0a : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h60};
            8'h0b : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h60, 8'h00};
            8'h0c : {VGA_R, VGA_G, VGA_B} = {8'h60, 8'h00, 8'h00};
            8'h0d : {VGA_R, VGA_G, VGA_B} = {8'h50, 8'h00, 8'h70};
            8'h0e : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h40, 8'h40};
            8'h0f : {VGA_R, VGA_G, VGA_B} = {8'h00, 8'h00, 8'h00};
          endcase
        end
        else if (p1bullet_en) begin
            {VGA_R, VGA_G, VGA_B} = {8'hff, 8'hf6, 8'h33};
        end
        else if (p2bullet_en) begin
            {VGA_R, VGA_G, VGA_B} = {8'hd8, 8'hd8, 8'hd8};
        end
      end
   end
       
endmodule

module vga_counters(
 input logic 	     clk50, reset,
 output logic [10:0] hcount,  // hcount[10:1] is pixel column
 output logic [9:0]  vcount,  // vcount[9:0] is pixel row
 output logic 	     VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_n, VGA_SYNC_n);

/*
 * 640 X 480 VGA timing for a 50 MHz clock: one pixel every other cycle
 * 
 * HCOUNT 1599 0             1279       1599 0
 *             _______________              ________
 * ___________|    Video      |____________|  Video
 * 
 * 
 * |SYNC| BP |<-- HACTIVE -->|FP|SYNC| BP |<-- HACTIVE
 *       _______________________      _____________
 * |____|       VGA_HS          |____|
 */
   // Parameters for hcount
   parameter HACTIVE      = 11'd 1280,
             HFRONT_PORCH = 11'd 32,
             HSYNC        = 11'd 192,
             HBACK_PORCH  = 11'd 96,   
             HTOTAL       = HACTIVE + HFRONT_PORCH + HSYNC +
                            HBACK_PORCH; // 1600
   
   // Parameters for vcount
   parameter VACTIVE      = 10'd 480,
             VFRONT_PORCH = 10'd 10,
             VSYNC        = 10'd 2,
             VBACK_PORCH  = 10'd 33,
             VTOTAL       = VACTIVE + VFRONT_PORCH + VSYNC +
                            VBACK_PORCH; // 525

   logic endOfLine;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          hcount <= 0;
     else if (endOfLine) hcount <= 0;
     else  	         hcount <= hcount + 11'd 1;

   assign endOfLine = hcount == HTOTAL - 1;
       
   logic endOfField;
   
   always_ff @(posedge clk50 or posedge reset)
     if (reset)          vcount <= 0;
     else if (endOfLine)
       if (endOfField)   vcount <= 0;
       else              vcount <= vcount + 10'd 1;

   assign endOfField = vcount == VTOTAL - 1;

   // Horizontal sync: from 0x520 to 0x5DF (0x57F)
   // 101 0010 0000 to 101 1101 1111
   assign VGA_HS = !( (hcount[10:8] == 3'b101) &
		      !(hcount[7:5] == 3'b111));
   assign VGA_VS = !( vcount[9:1] == (VACTIVE + VFRONT_PORCH) / 2);

   assign VGA_SYNC_n = 1'b0; // For putting sync on the green signal; unused
   
   // Horizontal active: 0 to 1279     Vertical active: 0 to 479
   // 101 0000 0000  1280	       01 1110 0000  480
   // 110 0011 1111  1599	       10 0000 1100  524
   assign VGA_BLANK_n = !( hcount[10] & (hcount[9] | hcount[8]) ) &
			!( vcount[9] | (vcount[8:5] == 4'b1111) );

   /* VGA_CLK is 25 MHz
    *             __    __    __
    * clk50    __|  |__|  |__|
    *        
    *             _____       __
    * hcount[0]__|     |_____|
    */
   assign VGA_CLK = hcount[0]; // 25 MHz clock: rising edge sensitive
   
endmodule
