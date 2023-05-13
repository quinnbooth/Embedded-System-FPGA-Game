# Embedded-System-Tank-Game
Multiplayer tank game implemented on the DE1-SoC Cyclone V Board. Based on Battle City for the NES, runs with 2 controllers, uses VGA for video and the WM8731 CODEC for audio.
<br><br>
<p align="center">
  <img src="./media/tank_game.gif" alt="Gameplay" width="480" height="270">
  <br>
  <em>Figure 1: Tank Game VGA Monitor Display.</em>
</p>
<br><br>
<p align="center">
  <img src="./media/fpga.png" alt="FPGA" width="300" height="297">
  <br>
  <em>Figure 2: DE1-SoC Cyclone V FPGA.</em>
</p>

# Authors

👨‍💻 **Quinn Booth** - `qab2004@columbia.edu`

👩‍💻 **Ganesan Narayanan**

👨‍💻 **Ana Maria Rodrigues**

👨‍🏫 **Professor Stephen Edwards** - *Code Skeleton* 

# Table of Contents

- [Introduction](#introduction)
    - [Game Overview & Rules](#gameoverview)
    - [System Architecture](#architecture)
- [Hardware](#hardware)
    - [Graphics](#graphics)
    - [Audio](#audio)
    - [Memory](#memory)
- [Software](#software)
    - [Avalon Bus Interface](#bus)
    - [User Input](#userinput)
        - [Controls Overview](#controls)
        - [Communication Protocol](#protocol)
    - [Game Logic](#gamelogic)
        - [Game Loop](#gameloop)
        - [Tank Movement](#movement)
        - [Collision Detection](#collision)
        - [Bullet Firing](#bullet)
        - [Win Condition](#win)
- [References](#references)

# Introduction <a name="introduction"></a>

### Game Overview & Rules <a name="gameoverview"></a>

Our game of Tanks is a 2-player tank maze game based on the original Tank arcade game developed in 1974 by a subsidiary of Atari. In our game, two players move tanks around in a maze viewed from above, while attempting to shoot the opposing player’s tank. Players use game controllers to control their tank, moving with the arrow buttons and shooting bullets with the A button. Bullets cannot go through walls and when a bullet hits the other player’s tank, it explodes and they gain 100 points. The first player to reach 500 points wins.

Upon startup, Player 1 must select the map to be played. We have designed three different maps for the players to select. Using the up/down arrows on the controller, they can select from the desired stage, with higher number stages being more complex in maze design. To start the game, Player 1 must press the A button. Once a player reaches 500 points and wins, the game is over and the players are taken back to the stage selection screen.

### System Architecture <a name="architecture"></a>
<br><br>
<p align="center">
  <img src="./media/architecture.png" alt="System Architecture" width="400" height="300">
  <br>
  <em>Figure 3: Block Diagram.</em>
</p>

Players control the movement of tanks using game controllers, interfacing with the software controlling the game logic by communicating through the USB protocol. The software then communicates to the FPGA hardware using a device driver, which then handles displaying the graphics for the game on the VGA monitor and decides when to play audio cues. 

The software components involve the main game logic hello.c file, which handles the logic of tank movement, bullet shooting, and scoring. The controller.c file recognizes and initializes inputs from the USB controller controllers so that the game logic can be carried out, communicating through the USB protocol and libusb library. Finally, the vga ball.c file device driver communicates to the vga_module.sv through the Avalon bus interface to update the graphics that will be displayed on the VGA monitor based on the game logic.

The hardware peripherals include the USB controllers, through which players input is passed, and the VGA monitor, which displays the output of the game itself. The hardware consists of on-chip memory ROMs on the FPGA in which all the necessary sprite data will be stored and the vga_ball module file that displays the requisite graphical information based on the screen location on the VGA display. The vga_ball module sends addresses to the ROMs which returns the requested output sprite data. It then communicates with the VGA monitor hardware peripheral to display the graphics. Additionally, we connect earbuds or a speaker to the WM8731 CODEC.

# Hardware <a name="hardware"></a>

### Graphics <a name="graphics"></a>

The main hardware algorithm is the logic to display the graphics. The sprites we used for our graphics are stored in on chip memory ROMs created and configured through the on-chip system memory IP blocks in Platform Designer. The .png images for our sprites (taken from the Battle City game) were converted into .mif memory initialization files to prepopulate the ROMs.

To display the graphics, the addresses to be read from the respective ROMs are determined by the ioctl writes from the device driver and location on the display. The values stored in the ROMs specified by the .mif files are a hex value for each pixel in the image, with each pixel corresponding to an address in memory. This output hex value is used to look-up the values to pass to the VGA RGB signals and determine the color to display on the screen (for a total of 16 different colors) at that current location.

The graphics architecture is shown below. The vga_ball module contains modules to determine the position on the screen and to set the RGB pixel values on the VGA display. Through the Avalon bus interface, 16 bit data is passed from the software using the device drivers to vga_ball.sv to indicate the when and where graphics should be displayed. Using this information and the hcount and count coordinate positions, the vga_ball.sv passes addresses to the instantiated on-chip memory ROMs, which return 8-bit output values that are used to determine the output VGA_R, VGA_G, VGA_B signals to the display. The ROMs are initialized with the memory initialization files that populate the memory contents with the requisite sprite data.
<br><br>
<p align="center">
  <img src="./media/graphics_architecture.png" alt="Graphics Architecture" width="460" height="310">
  <br>
  <em>Figure 4: Graphics Architecture.</em>
</p>

### Audio <a name="audio"></a>

To store the audio files in memory, we had to convert them to a specific formatting. After downloading the .mp3 files we wanted to use in our game, we converted them to .wav files in Audacity. We also swapped the files from stereo to mono (as we will only be playing one stream of audio), cropped them to a desirable length (to save memory), re-sampled the audio at 8 kHz, and converted them to signed 16-bit PCIM binary encoding. The .mp3s were then converted into .mif file format. 

The .mif files were used to prepopulate the on-chip memory ROMs to contain the music data. We modified the Qsys interface such that our audio samples would be properly fed into the WM8731 CODEC. The 3 main components involved were: the altera_up_avalon_audio_pll, the alterra_up_avalon_audio_and_video_config, and the altera_up_avalon_audio IPs. The altera_up_avalon_audio_pll acts as a clock divider. As the CODEC does not operate on our standard 50 MHz, the PLL is needed to create a 12.288 MHz clock frequency, using the 50 MHz clock as a reference. The altera_up_avalon_audio_and_video_config sets up our peripheral audio device – configures the CODEC – given our initialization arguments: left-justified data format, 16 bit length, etc. The altera_up_avalon_audio facilitates a transfer of audio between our WM8731 CODEC and FPGA through right and left channels implemented as FIFOs. Together, these IP blocks gave us a data channel and clock prepared for the line out jack through the Wolfson WM8731 CODEC.

soc_system.qsys contains our final Qsys connections that facilitate audio data transfer between our FPGA and WM8731 CODEC peripheral. vga_ball_0 has avalon_streaming_interfaces for both the left and right channels, with each of these interfaces having a ready, valid, and data signal. These signals are used to judge when the CODEC FIFOs are prepared to accept audio samples. The audio loop waits for the altera_up_avalon_audio IP to send a HIGH ready signal and proceeds to count up to a threshold, slowing our data transfer to an intelligible rate. Once this threshold is met, valid signals go HIGH and depending on the game event, some audio sample is passed to the CODEC through the altera_up_avalon_audio.
<br><br>
<p align="center">
  <img src="./media/audio_architecture.png" alt="Audio Architecture" width="480" height="310">
  <br>
  <em>Figure 5: Audio Architecture.</em>
</p>

### Memory <a name="memory"></a>

The FPGA includes 4450 Kbits of embedded memory. The sprites and audio required for our project are shown in the table below. Note that the value for each pixel in the sprite images was stored as a one byte hex value. Additionally, each audio sample is stored in memory as a signed 16-bit integer to be fed into the WM8731 CODEC. In all, for our sprites we utilized ~183 Kbits of memory, while for our audio we used ~694 Kbits. This totals to ~877 Kbits, which is less than the embedded memory in the FPGA.
<br><br>
<p align="center">
  <img src="./media/memory.png" alt="Memory Considerations" width="500" height="600">
  <br>
  <em>Figure 6: Memory Considerations.</em>
</p>