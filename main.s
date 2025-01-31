.global _start
_start:
	
.data
dimension: .byte 0, 0
num_targets: .byte 0
num_boxes: .byte 0

wall: .byte '|'
player: .byte 'p'
player_on_target: .byte 'P'
target: .byte 'T'
box: .byte 'B'
match: .byte 'M'
empty: .byte ' '
inputs: .byte 'w', 'a', 's', 'd', 'r'
player_loc: .byte 0, 0
player_loc_copy: .byte 0, 0
targets_lrtb: .byte 0, 0, 0, 0
player_data_addr: .word 0
player_names_addr: .word 0

# Constants for LCG
seed: .word 0
m: .word 0x7fffffff
a: .word 1664525
c: .word 1013904223

welcomeMessage: .string "Welcome to Sokoban!\n"
dimensionMessageRow: .string "Enter board width (Min 3): "
dimensionMessageCol: .string "Enter board height (Min 3): "
targetsMessage: .string "Enter # of targets. Max: "
inputMessage: .string "Enter move: "
statusMessage: .string " target(s) left\n"
enterNumOfPlayersMessage: .string "Enter # of players. "
playerTurnMessage: .string "Your turn, Player "
generationMessage: .string "Generating board...\n"
leaderboardMessage: .string "### LEADERBOARD ###"
playerMessage: .string "Player "
semicolon: .string ": "
moves: .string " moves"
newline: .string "\n"

.text
main:
	la t0, seed
	li a7, 30
	ecall
	sw a0, 0(t0)
	
	# Step 1: Welcome the player, get parameters
	li a7, 4
	la a0, welcomeMessage
	ecall
	
	li t2, 3
	lessThanThreeRow:
	li a7, 4
	la a0, dimensionMessageRow
	ecall
	li a7, 5
	ecall
	mv t0, a0
	
	blt a0, t2, lessThanThreeRow
	
	lessThanThreeCol:
	li a7, 4
	la a0, dimensionMessageCol
	ecall
	li a7, 5
	ecall
	mv t1, a0
	
	blt a0, t2, lessThanThreeCol
	
	la t2, dimension
	sb t0, 0(t2)
	sb t1, 1(t2)
	
	mv a0, t0
	mv a1, t1
	
	jal x1, getMin
	srli a0, a0, 1
	mv t0, a0
	
	getTargets:
	li a7, 4
	la a0, targetsMessage
	ecall
	li a7, 1
	mv a0, t0
	ecall
	li a7, 4
	la a0, newline
	ecall
	li a7, 5
	ecall
	addi t1, t0, 1
	bge a0, t1, getTargets
	
	la t1, num_targets
	sb a0, 0(t1)
	
	li a7, 4
	la a0, generationMessage
	ecall
	
	la t0, dimension
	
	lb s0, 0(t0) # # of rows
	lb s1, 1(t0) # # of columns
	
	mul t1, s0, s1 # number of spaces this board has
	slli t1, t1, 2 # number of bytes we need to reserve for this board
	
	li a7, 9
	mv a0, t1
	ecall
	
	mv s2, a0 # address of grid
	
	li a7, 9
	mv a0, t1
	ecall
	
	mv s9, a0 # address of grid copy
	
	# s0, s1, s2 are final
	# s0 = # of rows 
	# s1 = # of cols
	# s2 = address of grid
	
	create_board:
	li s3, 0
	li s4, 0
	
    la t0, player_loc        
    li t1, 0                 
    sb t1, 0(t0)            
    sb t1, 1(t0)            

    la t0, player_loc_copy   
    sb t1, 0(t0)            
    sb t1, 1(t0)            

    la t0, targets_lrtb      
    sb t1, 0(t0)            
    sb t1, 1(t0)            
    sb t1, 2(t0)            
    sb t1, 3(t0)            

    la t0, player_data_addr   
    sw t1, 0(t0)              
   
    la t0, player_names_addr   
    sw t1, 0(t0)                     

    la t0, num_boxes           
    sb t1, 0(t0)  
	
	
	# Step 2: Initialize a board with empty spaces
	init_outer:
		bge s3, s0, init_outer_end
		li s4, 0
	init_inner:
		bge s4, s1, init_inner_end
		mv a0, s3
		mv a1, s4
		jal x1, getOffset
		mv t1, a0
		add a0, s2, a0
		la t0, empty
		lb t0, 0(t0)
		sb t0, 0(a0)
		add t1, s9, t1
		sb t0, 0(t1)
		
		addi s4, s4, 1
		jal x0, init_inner
	init_inner_end:
		addi s3, s3, 1
		jal x0, init_outer
	init_outer_end:
		mv a0, s0
		jal x1, rand
		mv s3, a0
		mv a0, s1
		jal x1, rand
		mv s4, a0
		mv a0, s3
		mv a1, s4
		jal x1, getOffset
		add t0, s2, a0
		add t1, s9, a0
		la t2, player
		lb t2, 0(t2)
		sb t2, 0(t0)
		sb t2, 0(t1)
		la t4, player_loc
		la t5, player_loc_copy
		sb s3, 0(t4)
		sb s4, 1(t4)
		sb s3, 0(t5)
		sb s4, 1(t5)
		
	# Step 3: Place targets on board
	li s3, 0
	la s4, num_targets
	lb s4, 0(s4)
	li s8, 0
	li s10, 200
	target_generation_while:
		addi s8, s8, 1
		beq s3, s4, target_generation_done
		bge s8, s10, create_board
		
		mv a0, s0
		jal x1, rand
		mv s5, a0 # row
		
		mv a0, s1
		jal x1, rand
		mv s6, a0 # column
		
		la a2, target
		lb a2, 0(a2)
		mv a0, s5
		mv a1, s6
		mv a3, s9
		jal x1, setBoard
		
		la a2, target
		lb a2, 0(a2)
		mv a0, s5
		mv a1, s6
		mv a3, s2
		jal x1, setBoard
		
		add s3, s3, a0
		beq a0, x0, target_done
		
		LEFT:
		bne s6, x0, RIGHT
		la t0, targets_lrtb
		lb t2, 0(t0)
		addi t2, t2, 1
		sb t2, 0(t0)
		jal x0, target_done
		
		RIGHT:
		la t0, dimension
		lb t0, 1(t0)
		addi t0, t0, -1
		bne s6, t0, TOP
		la t0, targets_lrtb
		lb t2, 1(t0)
		addi t2, t2, 1
		sb t2, 1(t0)
		jal x0, target_done
		
		TOP:
		bne s5, x0, BOTTOM
		la t0, targets_lrtb
		lb t2, 2(t0)
		addi t2, t2, 1
		sb t2, 2(t0)
		jal x0, target_done
		
		BOTTOM:
		la t0, dimension
		lb t0, 0(t0)
		addi t0, t0, -1
		bne s5, t0, target_done
		la t0, targets_lrtb
		lb t2, 3(t0)
		addi t2, t2, 1
		sb t2, 3(t0)
		
		target_done:
		jal x0, target_generation_while
		
	target_generation_done:
	
	# Step 4: Place boxes on board
	li s3, 0
	la s4, num_targets
	lb s4, 0(s4)
	li s8, 0
	li s10, 200
	box_generation_while:
		addi s8, s8, 1
		beq s3, s4, box_generation_done
		bge s8, s10, create_board
		
		mv a0, s0
		jal x1, rand
		mv s5, a0 # row
		
		mv a0, s1
		jal x1, rand
		mv s6, a0 # column
		
		la a2, box
		lb a2, 0(a2)
		mv a0, s5
		mv a1, s6
		mv a3, s9
		jal x1, setBoard
		
		la a2, box
		lb a2, 0(a2)
		mv a0, s5
		mv a1, s6
		mv a3, s2
		jal x1, setBoard
		beq a0, x0, box_generation_while
		# if board was set, check if it is solvable
		mv a0, s5
		mv a1, s6
		jal x1, isSolvable
		
		bne a0, x0, solvable
		
		notSolvable:
		mv a0, s5
		mv a1, s6
		jal x1, getOffset
		add t0, s2, a0
		add t1, s9, a0
		la t2, empty
		lb t2, 0(t2)
		sb t2, 0(t0)
		sb t2, 0(t1)
		jal x0, box_generation_while

		solvable:
		add s3, s3, a0
		la t0, num_boxes
		lb t1, 0(t0)
		add t1, t1, a0
		sb t1, 0(t0)
		
		jal x0, box_generation_while
		
	box_generation_done:
	
	# Step 5: Begin the game
	la s3, player_data_addr
	la s4, player_names_addr
	
	li a7, 4
	la a0, enterNumOfPlayersMessage
	ecall
	li a7, 5
	ecall
	mv t2, a0
	slli a0, a0, 2
	li a7, 9
	ecall
	sw a0, 0(s3)
	mv a0, t2
	slli a0, a0, 2
	li a7, 9
	ecall
	sw a0, 0(s4)
	
	li t1, 1
	addi t0, t2, 1	
	la s3, player_data_addr
	la s4, player_names_addr
	lw s3, 0(s3)
	lw s4, 0(s4)
	mv t2, s3
	mv t3, s4
	initialize_players_while:
		bge t1, t0, initialize_players_done
		sw x0, 0(t2)
		addi t2, t2, 4
		sw t1, 0(t3)
		addi t3, t3, 4
		
		addi t1, t1, 1
		jal x0, initialize_players_while
	
	initialize_players_done:
	
	li s5, 1
	mv s6, t0
	main_loop:
		beq s5, s6, main_loop_done
		
		li a7, 4
		la a0, playerTurnMessage
		ecall
		li a7, 1
		mv a0, s5
		ecall
		li a7, 4
		la a0, newline
		ecall
		
		jal x1, printBoard
	main_while:
		la t0, num_boxes
		lb t0, 0(t0)
		beq t0, x0, main_while_done
		
		li a7, 1
		mv a0, t0
		ecall
		li a7, 4
		la a0, statusMessage
		ecall
		
		jal x1, move
		
		# if player made a legal move, increment their move count
		beq a0, x0, no_move
		
		la s3, player_data_addr
		la s4, player_names_addr
		lw s3, 0(s3)
		lw s4, 0(s4)
		mv t2, s3
		mv t3, s4
		
		addi t0, s5, -1
		slli t0, t0, 2
		add t1, s3, t0
		lb t2, 0(t1)
		addi t2, t2, 1
		sb t2, 0(t1)
		
		no_move:
		jal x1, printBoard
		jal x0, main_while
	
	main_while_done:
		# restart the game
		li s3, 0 # i
		li s4, 0 # j
		restart_outer:
			bge s3, s0, restart_outer_end
			li s4, 0
		restart_inner:
			bge s4, s1, restart_inner_end
			mv a0, s3
			mv a1, s4
			jal x1, getOffset
			mv t0, a0
			add t1, s2, t0 
			add t2, s9, t0
			lb t2, 0(t2)
			sb t2, 0(t1)
			addi s4, s4, 1
			jal x0, restart_inner
		restart_inner_end:
			addi s3, s3, 1
			jal x0, restart_outer
		restart_outer_end:
		
		la t0, player_loc
		la t1, player_loc_copy
		lb t2, 0(t1)
		lb t3, 1(t1)
		sb t2, 0(t0)
		sb t3, 1(t0)
		
		la t0, num_boxes
		lb t0, 0(t0)
		
		la t1, num_targets
		lb t1, 0(t1)
		la t2, num_boxes
		sb t1, 0(t2)
		
		bne t0, x0, dontChangePlayer
		
		addi s5, s5, 1
		jal x0, main_loop
		
		dontChangePlayer:
		jal x0, main_loop
		
	main_loop_done:
	
	la s3, player_data_addr
	lw s3, 0(s3)
	la s4, player_names_addr
	lw s4, 0(s4)
	
	mv a0, s3
	mv a1, s4
	mv a2, s5
	addi a2, a2, -1
	jal x1, bubbleSort
	
	li t0, 1
	mv t1, s5
	
	li a7, 4
	la a0, leaderboardMessage
	ecall
	la a0, newline
	ecall
	
	leaderboard_while:
	beq t0, t1, leaderboard_done
	
	addi t2, t0, -1
	slli t2, t2, 2
	add t3, s3, t2
	add t4, s4, t2
	
	li a7, 4
	la a0, playerMessage
	ecall
	
	li a7, 1
	lw a0, 0(t4)
	ecall
	
	li a7, 4
	la a0, semicolon
	ecall
	
	li a7, 1
	lw a0, 0(t3)
	ecall
	
	li a7, 4
	la a0, moves
	ecall
	
	li a7, 4
	la a0, newline
	ecall
	
	addi t0, t0, 1
	jal x0, leaderboard_while
	leaderboard_done:
	
	li a7, 10
	ecall


### HELPER FUNCTIONS ###

# params: a0 = i, a1 = j
# returns: the offset for the location grid[i][j]
getOffset:
	# grid[i][j] = grid at offset 4(i*dimension_col + j)
	li t0, 1
	li t1, 4
	mul	t0, a0, s1 # t4 = i*dimension_col
	add t0, t0, a1 # t4 = i*dimension_col + j
	mul t0, t0, t1 # t4 = 4(i*dimension_col + j)
	mv a0, t0
	jalr x0, 0(x1)
	
# Attempt to set a piece on board.
# params: a0 = row, a1 = col, a2 = piece to set (char), a3 = address of board
# return: a0 = 1 if set was successful, 0 otherwise. 
# A set is successful if the spot (row, col) is empty. 
setBoard:
	addi sp, sp, -20
	sw x1, 0(sp)
	sw s3, 4(sp)
	sw s4, 8(sp)
	sw s5, 12(sp)
	sw s2, 16(sp)
	
	mv s3, a0
	mv s4, a1
	mv s5, a2
	mv s2, a3
	
	jal x1, getOffset
	add a0, s2, a0
	
	lb t0, 0(a0) # piece currently at (row, col)
	la t1, empty
	lb t1, 0(t1) # the empty piece
	
	bne t0, t1, setBoard_noset
	sb s5, 0(a0)
	li a0, 1
	jal x0, setBoard_finish
	setBoard_noset:
		li a0, 0
	setBoard_finish:
		lw s2, 16(sp)
		lw s5, 12(sp)
		lw s4, 8(sp)
		lw s3, 4(sp)
		lw x1, 0(sp)
		addi sp, sp, 20
		jalr x0, 0(x1)
		
# prints the grid
# void
printBoard:
	addi sp, sp, -12
	sw x1, 0(sp)
	sw s3, 4(sp)
	sw s4, 8(sp)
	
	li a7, 4
	la a0, newline 
	ecall
	
	li s3, 0 # i
	li s4, 0 # j
	
	printBoard_outer:
		bge s3, s0, printBoard_outer_end
		li a7, 11
		# print left wall
		la a0, wall
		lb a0, 0(a0)
		ecall
		li s4, 0
	
	printBoard_inner:
		bge s4, s1, printBoard_inner_end
		
		# print left space
		la a0, empty
		lb a0, 0(a0)
		ecall
		
		# print piece at (i, j)
		mv a0, s3
		mv a1, s4
		jal x1, getOffset
		add a0, s2, a0
		lb a0, 0(a0)
		ecall
		
		addi s4, s4, 1
		jal x0, printBoard_inner
	
	printBoard_inner_end:
		addi s3, s3, 1
		
		# print space to the right
		la a0, empty
		lb a0, 0(a0)
		ecall
		
		# print right wall, go to next line
		la a0, wall
		lb a0, 0(a0)
		ecall
		li a7, 4
		la a0, newline
		ecall
		
		jal x0, printBoard_outer
	
	printBoard_outer_end:
		lw s4, 8(sp)
		lw s3, 4(sp)
		lw x1, 0(sp)
		addi sp, sp, 12
		jalr x0, 0(x1)
		
# gets input from the user and makes the appropriate move.
# returns: 1 if the user made a legal move, 0 otherwise. 
move:
	addi sp, sp, -4
	sw x1, 0(sp)
	
	li a7, 4
	la a0, newline
	ecall
	la a0, inputMessage
	ecall
	
	li a7, 12
	ecall
	
	mv t1, a0
	
	li a7, 4
	la a0, newline
	ecall
	
	mv a0, t1
	la t0, inputs
	
	W:
	lb t1, 0(t0)
	bne a0, t1, A
	li a0, -1
	li a1, 0
	jal x1, move2
	jal x0, default
	A:
	lb t1, 1(t0)
	bne a0, t1, S
	li a0, 0
	li a1, -1
	jal x1, move2
	jal x0, default
	S:
	lb t1, 2(t0)
	bne a0, t1, D
	li a0, 1
	li a1, 0
	jal x1, move2
	jal x0, default
	D:
	lb t1, 3(t0)
	bne a0, t1, R
	li a0, 0
	li a1, 1
	jal x1, move2
	jal x0, default
	R:
	lb t1, 4(t0)
	bne a0, t1, default
	jal x0, main_while_done
	
	default:
	lw x1, 0(sp)
	addi sp, sp, 4
	jalr x0, 0(x1)

# params: a0 = drow, a1 = dcol
# Attempts to make a move in direction (drow, dcol). 
# returns 1 if this user made a legal move, 0 otherwise.
move2:
	addi sp, sp, -28
	sw x1, 0(sp)
	sw s3, 4(sp)
	sw s4, 8(sp)
	sw s5, 12(sp)
	sw s6, 16(sp)
	sw s7, 20(sp)
	sw s8, 24(sp)
	
	la t2, player_loc
	lb s3, 0(t2)
	lb s4, 1(t2)
	add s3, s3, a0 # player_row + drow
	add s4, s4, a1 # player_col + dcol
	
	mv s5, a0 # drow
	mv s6, a1 # dcol
	
	# check if move is on this board
	mv a0, s3
	mv a1, s4
	jal x1, isValidCoordinate
	beq a0, x0, endMove
	
	# determine the trailing piece
	la t0, player_loc
	lb a0, 0(t0)
	lb a1, 1(t0)
	jal x1, getOffset
	add a0, s2, a0
	lb t0, 0(a0)
	la s7, empty
	lb s7, 0(s7)
	la t1, player_on_target
	lb t1, 0(t1)
	la t2, target
	lb t2, 0(t2)
	PLAYER_TARGET:
	bne t0, t1, MATCH
	mv s7, t2
	jal x0, EMPTY
	MATCH:
	la t1, match
	lb t1, 0(t1)
	bne t0, t1, EMPTY
	mv s7, t1
	jal x0, EMPTY
	EMPTY:
	
	# we have a few cases for moving the player
	mv a0, s3
	mv a1, s4
	jal x1, getOffset
	add a0, s2, a0
	lb t0, 0(a0)
	
	# case 1: new location is empty
	CASE1:
	la t1, empty
	lb t1, 0(t1)
	bne t0, t1, CASE2
	mv a0, s3
	mv a1, s4
	la a2, player
	lb a2, 0(a2)
	mv a3, s7
	jal x1, setPlayer
	li a0, 1
	jal x0, endMove
	
	# case 2: new location is box
	CASE2:
	la t1, box
	lb t1, 0(t1)
	bne t0, t1, CASE3
	mv a0, s3
	add a0, a0, s5
	mv a1, s4
	add a1, a1, s6
	jal x1, setBox
	beq a0, x0, didntSetBoxCase2
	
	mv a0, s3
	mv a1, s4
	la a2, player
	lb a2, 0(a2)
	mv a3, s7
	jal x1, setPlayer
	li a0, 1
	jal x0, endMove
	didntSetBoxCase2:
	li a0, 0
	jal x0, endMove
	
	# case 3: new location is target
	CASE3:
	la t1, target
	lb t1, 0(t1)
	bne t0, t1, CASE4
	mv a0, s3
	mv a1, s4
	la a2, player_on_target
	lb a2, 0(a2)
	mv a3, s7
	jal x1, setPlayer
	li a0, 1
	jal x0, endMove
	
	# case 4: new location is match
	CASE4:
	la t1, match
	lb t1, 0(t1)
	bne t0, t1, endMove
	mv a0, s3
	add a0, a0, s5
	mv a1, s4
	add a1, a1, s6
	jal x1, setBox
	beq a0, x0, didntSetBoxCase4
	
	mv a0, s3
	mv a1, s4
	la a2, player_on_target
	lb a2, 0(a2)
	mv a3, s7
	jal x1, setPlayer
	la t0, num_boxes
	lb t1, 0(t0)
	addi t1, t1, 1
	sb t1, 0(t0)
	li a0, 1
	jal x0, endMove
	
	didntSetBoxCase4:
	li a0, 0
	jal x0, endMove
	
		
	endMove:
	lw s8, 24(sp)
	lw s7, 20(sp)
	lw s6, 16(sp)
	lw s5, 12(sp)
	lw s4, 8(sp)
	lw s3, 4(sp)
	lw x1, 0(sp)
	addi sp, sp, 28
	jalr x0, 0(x1)
	
# sets updated_piece to (row, col), sets trailing_piece to original location
# params: a0 = row, a1 = col, a2 = updated_piece, a3 = trailing_piece
# void
setPlayer:
	addi sp, sp, -20
	sw x1, 0(sp)
	sw s3, 4(sp)
	sw s4, 8(sp)
	sw s5, 12(sp)
	sw s6, 16(sp)
	
	mv s3, a0
	mv s4, a1
	mv s5, a2
	mv s6, a3
	
	# set player's current spot to trailing_piece
	la t0, player_loc
	lb a0, 0(t0)
	lb a1, 1(t0)
	jal x1, getOffset
	add a0, s2, a0
	sb s6, 0(a0)
	
	# set player's new spot to updated_piece
	mv a0, s3
	mv a1, s4
	jal x1, getOffset
	add a0, s2, a0
	sb s5, 0(a0)
	
	#update player_loc
	la t0, player_loc
	sb s3, 0(t0)
	sb s4, 1(t0)
	
	lw s6, 16(sp)
	lw s5, 12(sp)
	lw s4, 8(sp)
	lw s3, 4(sp)
	lw x1, 0(sp)
	addi sp, sp, 20
	jalr x0, 0(x1)
	
# sets a box at (row, col). If (row, col) is occupied by a target, it becomes a match.
# params: a0 = row, a1 = col
# returns 1 if set was successful, 0 otherwise. 
setBox:
	addi sp, sp, -16
	sw x1, 0(sp)
	sw s3, 4(sp)
	sw s4, 8(sp)
	sw s5, 12(sp)
	
	mv s3, a0
	mv s4, a1
	
	jal x1, isValidCoordinate
	beq a0, x0, setBox_end
	mv a0, s3
	mv a1, s4
	jal x1, getOffset
	add a0, s2, a0
	lb s5, 0(a0)
	
	la t0, target
	lb t0, 0(t0)
	la t1, empty
	lb t1, 0(t1)
	
	beq s5, t0, setBox_case1
	beq s5, t1, setBox_case2
	li a0, 0
	jal x0, setBox_end
	
	setBox_case1:
	la t2, match
	lb t2, 0(t2)
	sb t2, 0(a0)
	la t2, num_boxes
	lb t3, 0(t2)
	addi t3, t3, -1
	sb t3, 0(t2)
	li a0, 1
	jal x0, setBox_end
	
	setBox_case2:
	la t2, box
	lb t2, 0(t2)
	sb t2, 0(a0)
	li a0, 1
	jal x0, setBox_end

	
	setBox_end:
	lw s5, 12(sp)
	lw s4, 8(sp)
	lw s3, 4(sp)
	lw x1, 0(sp)
	addi sp, sp, 16
	jalr x0, 0(x1)

# params: a0 = row, a1 = col
# checks if move at (row, col) is within the bounds of the board. 
# returns: 1 if move is valid, 0 otherwise. 
isValidCoordinate:
	li t0, 0
	bge a0, s0, false
	bge a1, s1, false
	blt a0, x0, false
	blt a1, x0, false
	li t0, 1
	
	false:
	mv a0, t0
	jalr x0, 0(x1)
	
# Determines if placing a box at (row, col) makes the board unsolvable. 
# params: a0 = row, a1 = col
# returns: 1 if solvable, 0 otherwise.
isSolvable:
	addi sp, sp, -20
	sw x1, 0(sp)
	sw s3, 4(sp)
	sw s4, 8(sp)
	sw s5, 12(sp)
	sw s6, 16(sp)
	
	mv s3, a0
	mv s4, a0
	
	jal x1, isCorner
	bne a0, x0, cannotBeSolved
	
	mv a0, s3
	mv a0, s4
	jal x1, getEdge
	mv s5, a0
	li t0, -1
	beq a0, t0, canBeSolved
	la t0, targets_lrtb
	add t0, t0, a0
	lb t0, 0(t0)
	
	beq t0, x0, cannotBeSolved
	la s6, box
	lb s6, 0(s6)
	
	case_0_1:
	li t0, 0
	li t0, 1
	beq s5, t0, _0_1
	beq s5, t1, _0_1
	jal x0, case_2_3
	_0_1:
		mv a0, s3
		mv a1, s4
		addi a0, a0, -1
		jal x1, getOffset
		add a0, s2, a0
		lb a0, 0(a0)
		
		beq a0, s6, cannotBeSolved
		
		mv a0, s3
		mv a1, a4
		addi a0, s0, 1
		jal x1, getOffset
		add a0, s2, a0
		lb a0, 0(a0)
		
		beq a0, s6, cannotBeSolved
		
		la t0, targets_lrtb
		add t0, t0, s5
		lb t1, 0(t0)
		addi t1, t1, -1
		sb t1, 0(t0)
		jal x0, canBeSolved
	
	case_2_3:
	li t0, 2
	li t1, 3
	beq s5, t0, _2_3
	beq s5, t1, _2_3
	jal x0, cannotBeSolved
	_2_3:
		mv a0, s3
		mv a1, s4
		addi a1, a1, -1
		jal x1, getOffset
		add a0, s2, a0
		lb a0, 0(a0)
		
		beq a0, s6, cannotBeSolved
		
		mv a0, s3
		mv a1, s4
		addi a1, a1, 1
		jal x1, getOffset
		add a0, s2, a0
		lb a0, 0(a0)
		
		beq a0, s6, cannotBeSolved
	
		la t0, targets_lrtb
		add t0, t0, s5
		lb t1, 0(t0)
		addi t1, t1, -1
		sb t1, 0(t0)
	
	canBeSolved:
	li a0, 1
	jal x0, canBeSolved2
	
	cannotBeSolved:
	li a0, 0
	canBeSolved2:
	lw s6, 16(sp)
	lw s5, 12(sp)
	lw s4, 8(sp)
	lw s3, 4(sp)
	lw x1, 0(sp)
	addi sp, sp, 20
	jalr x0, 0(x1)
	
	
# gets which edge the piece at (row, col) is on.
# params: a0 = row, a1 = col
# returns: 0 if left edge, 1 if right edge, 2 if top edge, 3 if bottom edge, -1 if not on an edge. 
getEdge:
	la t2, dimension
	lb t0, 0(t2)
	lb t1, 1(t2)
	addi t0, t0, -1
	addi t1, t1, -1

	left:
	bne a1, x0, right
	li a0, 0
	jalr x0, 0(x1)
	
	right:
	bne a1, t1, top
	li a0, 1
	jalr x0, 0(x1)
	
	top:
	bne a0, x0, bottom
	li a0, 2
	jalr x0, 0(x1)
	
	bottom:
	bne a0, t0, notAnEdge
	li a0, 3
	jalr x0, 0(x1)

	notAnEdge:
	li a0, -1
	jalr x0, 0(x1)
	
	
# Determines if this location is a corner.
# params: a0 = row, a1 = col
# returns: 1 if corner, 0 otherwise.
isCorner:
	la t2, dimension
	lb t0, 0(t2)
	addi t0, t0, -1
	lb t1, 1(t2)
	addi t1, t1, -1
	
	case_one:
	bne a0, x0, case_two
	bne a1, x0, case_two
	jal x0, isACorner
	case_two:
	bne a0, x0, case_three
	bne a1, t1, case_three
	jal x0, isACorner
	case_three:
	bne a0, t0, case_four
	bne a1, x0, case_four
	jal x0, isACorner
	case_four:
	bne a0, t0, notACorner
	bne a1, t1, notACorner
	jal x0, isACorner
	
	notACorner:
	li a0, 0
	jalr x0, 0(x1)
	
	isACorner:
	li a0, 1
	jalr x0, 0(x1)
	
# return the minimum of two numbers
# params: a0 = number1, a0 = number2
getMin:
	blt a0, a1, num1
	mv a0, a1
	jalr x0, 0(x1)
	num1:
	jalr x0, 0(x1)

# Sort an array at address a0, perform the same sbaps on array at address a1
# Precondition: both arrays have the same length
# params: a0 = array address, a1 = array address, a2 = length of both arrays
bubbleSort:
	li t0, 0 # i
	mv t1, a2 # len
	addi t1, t1, -1
	li t2, 0 # j

	
	sort_outer:
		beq t0, t1, sort_outer_done
		li t2, 0
	sort_inner:
		beq t2, t1, sort_inner_done
		
		mv t3, t2
		addi t4, t2, 1
		
		slli t3, t3, 2
		slli t4, t4, 2
		
		add t5, a0, t3
		add t6, a0, t4
		
		lw x15, 0(t5)
		lw x16, 0(t6)
		
		blt x15, x16, no_sbap
		sw x15, 0(t6)
		sw x16, 0(t5)
		
		add t5, a1, t3
		add t6, a1, t4
		
		lw x15, 0(t5)
		lw x16, 0(t6)
		
		sw x15, 0(t6)
		sw x16, 0(t5)
		
		no_sbap:
		addi t2, t2, 1
		jal x0, sort_inner
	sort_inner_done:
		addi t0, t0, 1
		jal x0, sort_outer
	
	sort_outer_done:
	jalr x0, 0(x1)

# Linear Congruential Generator
# Thomson, W. E. A Modified Congruence Method of Generating Pseudo-random Numbers (1958) Retrieved 10/18/2024
# https://doi.org/10.1093/comjnl/1.2.83

# return a random number between 0 (inclusive) and value in a0 (exclusive)
rand:
	addi sp, sp, -20
	sw s3, 0(sp)
	sw s4, 4(sp)
	sw s5, 8(sp)
	sw s6, 12(sp)
	sw x1, 16(sp)
	
	la s3, m
	lw s3, 0(s3)
	la s4, a
	lw s4, 0(s4)
	la s5, c
	lw s5, 0(s5)
	mv s6, a0
	
	jal x1, LCG
	
	remu a0, a0, s6
	li a7, 32
	ecall
	
	lw x1, 16(sp)
	lw s6, 12(sp)
	lw s5, 8(sp)
	lw s4, 4(sp)
	lw s3, 0(sp)
	addi sp, sp, 20
	jalr x0, 0(x1)

LCG:
	addi sp, sp, -4
	sw x1, 0(sp)

	la t0, seed
	lw a0, 0(t0)

	mul a0, s4, a0
	add a0, a0, s5
	remu a0, a0, s3
	
	sw a0, 0(t0)

	lw x1, 0(sp)
	addi sp, sp, 4
	
	jalr x0, 0(x1)
	

