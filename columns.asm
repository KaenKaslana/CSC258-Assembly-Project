################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    48
# - Display height in pixels:   104
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000


gem_colors:
    .word 0xff0000   #red
    .word 0xff8000   #orange
    .word 0xffff00   #yellow
    .word 0x00ff00   #green
    .word 0x0000ff   #blue
    .word 0x8000ff   #purple

##############################################################################
# Mutable Data
##############################################################################

# Current column
curr_x:      .word 2
curr_y:      .word 0

# Current column gem colours
curr_colors:
    .word 0   #red
    .word 0   #orange
    .word 0   #yellow

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    jal  random_column   #randomize the curr_colors
    jal draw_screen

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    jal  handle_input
    
    # 2a. Check for collisions
    
	# 2b. Update locations (capsules)
	
	# 3. Draw the screen
	jal draw_screen
	
	# 4. Sleep
    
    # 5. Go back to Step 1
    j game_loop
    
# draw_pixel(int x, int y, int color)
# Inputs: $a0 = x, $a1 = y, $a2 = color
draw_pixel:
    lw   $t0, ADDR_DSPL

    mul  $t1, $a1, 24 # y * row(6*4)
    mul  $t2, $a0, 4 # x * 4 bytes per pixel

    add  $t0, $t0, $t1
    add  $t0, $t0, $t2

    sw   $a2, 0($t0) # Store color
    jr   $ra

draw_column:
    # --- Prologue ---
    addiu $sp, $sp, -24
    sw    $fp, 0($sp) #fp+0=old fp
    sw    $ra, 4($sp) #fp+4= ra
    move  $fp, $sp

    #read curr_x, curr_y，and save to stack
    lw    $t0, curr_x
    lw    $t1, curr_y
    sw    $t0, 16($fp) #fp+16=x
    sw    $t1, 20($fp) #fp+20=y

    #i=0 as counter
    li    $t2, 0
    sw    $t2, 12($fp) #fp+12=i

draw_column_loop:
    lw    $t2, 12($fp) # i
    bge   $t2, 3, draw_column_end #if i >= 3, then end

    #use curr_colors[i] as the color
    la    $t0, curr_colors #address
    sll   $t1, $t2, 2 # i*4
    add   $t0, $t0, $t1
    lw    $a2, 0($t0) # color

    #calculate coordinate(x, y+i)
    lw    $a0, 16($fp) #x=curr_x
    lw    $a1, 20($fp) #y=curr_y
    add   $a1, $a1, $t2 #y+i

    #draw that pixel
    jal   draw_pixel

    #i++
    lw    $t2, 12($fp)
    addi  $t2, $t2, 1
    sw    $t2, 12($fp)
    
    #loop
    j     draw_column_loop

draw_column_end:
    # --- Epilogue ---
    lw    $fp, 0($sp)
    lw    $ra, 4($sp)
    addiu $sp, $sp, 24
    jr    $ra

#random_column
random_column:
    li   $t0, 0              # i = 0

init_color_loop:
    bgt  $t0, 2, init_color_done   #if i>2, then end

    #generate random number from 0-5(6 color in total)
    li   $v0, 42
    li   $a0, 0
    li   $a1, 6
    syscall

    # use that number as index and get color from gem_colors
    la   $t1, gem_colors
    mul $t2, $a0, 4 #index*4
    add  $t1, $t1, $t2
    lw   $t3, 0($t1) #t3=the color

    #save to curr_colors[i]
    la   $t4, curr_colors
    mul  $t5, $t0, 4 #i*4
    add  $t4, $t4, $t5
    sw   $t3, 0($t4)

    # i++
    addi $t0, $t0, 1
    j    init_color_loop

init_color_done:
    jr   $ra


# clear_screen: draw 6*13 to black
clear_screen:
    # --- Prologue ---
    addiu $sp, $sp, -20
    sw    $fp, 0($sp) #fp+0=old fp
    sw    $ra, 4($sp) #fp+4=ra
    move  $fp, $sp

    #initialize y = 0 to fp+8
    li    $t0, 0
    sw    $t0, 8($fp) #fp+8=y

outer_y_loop:
    lw    $t0, 8($fp)          #t0=y
    bgt   $t0, 12, clear_done  #if y>12, then end

    #save x=0 to fp+12
    li    $t1, 0
    sw    $t1, 12($fp) # fp+12= x

inner_x_loop:
    lw    $t1, 12($fp) # t1 = x
    bgt   $t1, 5, next_row #if x>5 then to next row

    #use draw_pixel
    move  $a0, $t1 #a0=x
    lw    $a1, 8($fp) #a1=y
    li    $a2, 0x000000 #black
    jal   draw_pixel

    #x++
    lw    $t1, 12($fp)
    addi  $t1, $t1, 1
    sw    $t1, 12($fp)
    j     inner_x_loop

next_row:
    #y++
    lw    $t0, 8($fp)
    addi  $t0, $t0, 1
    sw    $t0, 8($fp)
    j     outer_y_loop

clear_done:
    # --- Epilogue ---
    lw    $fp, 0($sp)
    lw    $ra, 4($sp)
    addiu $sp, $sp, 20
    jr    $ra

# handle_input:
handle_input:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)

wait_for_key:
    lw    $t0, ADDR_KBRD #t0=keyboard
    lw    $t1, 0($t0) #status
    beq   $t1, $zero, wait_for_key

    lw    $t2, 4($t0)

    #read x and y
    lw    $t3, curr_x
    lw    $t4, curr_y

    #wasdq
    li    $t5, 0x77           # 'w'
    li    $t6, 0x61           # 'a'
    li    $t7, 0x73           # 's'
    li    $t8, 0x64           # 'd'
    li    $t9, 0x71           # 'q'

    beq   $t2, $t5, key_W
    beq   $t2, $t6, key_A
    beq   $t2, $t7, key_S
    beq   $t2, $t8, key_D
    beq   $t2, $t9, key_Q

    j     release_wait        # 其他键直接忽略

#key w: go up
key_W:
    addi  $t4, $t4, -1        # y--
    blt   $t4, 0, clamp_W_min
    j     clamp_done_Y
clamp_W_min:
    li    $t4, 0
    j     clamp_done_Y

#key s: go down
key_S:
    addi  $t4, $t4, 1         # y++
    li    $s0, 10
    bgt   $t4, $s0, clamp_S_max
    j     clamp_done_Y
clamp_S_max:
    li    $t4, 10
    j     clamp_done_Y

clamp_done_Y:
    j     release_wait

#key a: left
key_A:
    addi  $t3, $t3, -1        # x--
    blt   $t3, 0, clamp_A_min
    j     clamp_done_X
clamp_A_min:
    li    $t3, 0
    j     clamp_done_X

#key d: right
key_D:
    addi  $t3, $t3, 1         # x++
    li    $s0, 5
    bgt   $t3, $s0, clamp_D_max
    j     clamp_done_X
clamp_D_max:
    li    $t3, 5
    j     clamp_done_X

clamp_done_X:
    j     release_wait

#key q: end program
key_Q:
    li    $v0, 10
    syscall

#wait till key release，then save to curr_x / curr_y
release_wait:
release_loop:
    lw    $t1, 0($t0)
    bne   $t1, $zero, release_loop

    sw    $t3, curr_x
    sw    $t4, curr_y

    lw    $ra, 0($sp)
    addiu $sp, $sp, 4
    jr    $ra

#draw_screen
draw_screen:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)

    jal   clear_screen
    jal   draw_column

    lw    $ra, 0($sp)
    addiu $sp, $sp, 4
    jr    $ra

# delay loop
delay:
    li   $t1, 50000

delay_loop:
    addi $t1, $t1, -1
    bne  $t1, $zero, delay_loop
    jr   $ra
