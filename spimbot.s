.data
# syscall constants
PRINT_STRING	= 4
PRINT_INT = 1
PRINT_CHAR = 11
# spimbot constants
# spimbot constants
VELOCITY      = 0xffff0010
ANGLE         = 0xffff0014
ANGLE_CONTROL = 0xffff0018
BOT_X         = 0xffff0020
BOT_Y         = 0xffff0024

OTHER_BOT_X = 0xffff00a0
OTHER_BOT_Y = 0xffff00a4

FRUIT_SMOOSHED_ACK = 0xffff0064
FRUIT_SMOOSHED_INT_MASK = 0x2000

FRUIT_SMASH = 0xffff0068
FRUIT_SCAN    = 0xffff005c

BONK_MASK     = 0x1000
BONK_ACK      = 0xffff0060

TIMER         = 0xffff001c
TIMER_MASK    = 0x8000
TIMER_ACK     = 0xffff006c

OUT_OF_ENERGY_ACK       = 0xffff00c4
OUT_OF_ENERGY_INT_MASK  = 0x4000

GET_ENERGY = 0xffff00c8

REQUEST_PUZZLE = 0xffff00d0
SUBMIT_SOLUTION = 0xffff00d4

REQUEST_PUZZLE_ACK = 0xffff00d8
REQUEST_PUZZLE_INT_MASK = 0x800

REQUEST_WORD = 0xffff00dc
NODE_SIZE = 12

num:		.word 0 #????global
.align 2
fruit_array: .space 260
puzzle_grid: .space 8192

puzzle_word: .space 128
num_rows:    .space 4
num_cols:    .space 4
counter:     .space 4
flag:	     .space 4  ##determine if puzzle is ready
flag2:	     .space 4  ##determine if we need energy now
amemory:     .space 4
directions:
	.word -1  0
	.word  0  1
	.word  1  0
	.word  0 -1

# Stores the address for the next node to allocate
new_node_address: .word node_memory
# Don't put anything below this just in case they malloc more than 4096
node_memory: .space 4096
.text 
main:

##la	$t0, puzzle grid
##sw	$t0, REQUEST_PUZZLE
##lw	$t0,GET_ENERGY

	li	$t4, FRUIT_SMOOSHED_INT_MASK 		
	or	$t4, $t4, BONK_MASK	
	or	$t4, $t4, REQUEST_PUZZLE_INT_MASK
	or	$t4, $t4, 1	
	mtc0	$t4, $12



	lw	$t0, 0xffff0024($0)		#currY
	li	$t1, 270
	li	$t2, 10				##VELOCITY
	sw	$t2, 0xffff0010($0)		#speed

	li	$t2, 90 			#//vertical!!!!!!
	sw	$t2, 0xffff0014($0)

	li	$t2, 1
	sw	$t2, 0xffff0018
	

vetical:
	sw	$0, VELOCITY
	lw	$t0, BOT_Y
	li	$t1, 270
	
	bge	$t0, $t1, horizontal
	
	sw	$0, VELOCITY
	lw	$t0, BOT_Y
	li	$t1, 290
	
	blt	$t0, $t1, not_go_up
	
	li	$t2, 10				##VELOCITY
	sw	$t2, VELOCITY			#speed

	li	$t2, 270 			#//vertical!!!!!!
	sw	$t2, ANGLE

	li	$t2, 1
	sw	$t2, 0xffff0018
	j	vertical
not_go_up:
	li	$t2, 10				##VELOCITY
	sw	$t2, VELOCITY			#speed

	li	$t2, 90 			#//vertical!!!!!!
	sw	$t2, ANGLE

	li	$t2, 1
	sw	$t2, 0xffff0018
	
	lw	$t0, BOT_Y			#currY
	j	vetical

	li	$t2, 1				##VELOCITY
	sw	$t2, VELOCITY			#speed
	

horizontal:
	sw	$0, VELOCITY
	
	lw	$t0, GET_ENERGY
	li	$t1, 60
	bge	$t0, $t1, skip_puzzle
	la	$t0, puzzle_grid
	sw	$t0, REQUEST_PUZZLE
skip_puzzle:	
	li	$t0, 10
	sw	$t0, VELOCITY

	la	$t0, num
	lw	$t0, 0($t0)
	beq	$t0, 1, smash_down

	
	li	$t2, 10##VELOCITY temp
	sw	$t2, VELOCITY



	la	$t5, fruit_array
	sw	$t5, FRUIT_SCAN

fruit_selection:

	lw	$s5, 4($t5) #points target 
	#add	$t5,$t5,16
	#lw	$t0,0($t5)
	#beq	$t0,$0,horizontal
	#bne	$s5,1,fruit_selection ###target point is 1
	#bne	$s5,1,fruit_selection

	#sub	$t5,$t5,16
	lw	$t6, 8($t5)#//target_x,first element SHOULD NOT BE CHANGED
	lw	$t7, 0($t5)#//target_id first element SHOULD NOT BE CHANGED
	lw	$t4, 0xffff0020($0)#currX


	beq	$t4, $t6,equal
	bgt	$t4, $t6,left_while

right_while:	


	li	$t0, 10 ##speed
	sw	$t0, 0xffff0010($0)#speed

	li	$t0, 0 #right
	sw	$t0, 0xffff0014($0)
	li	$t0, 1
	sw	$t0, 0xffff0018


	la	$t5, fruit_array
	sw	$t5, FRUIT_SCAN


	lw	$t1, 0($t5)#id first id of the array

	lw	$t4, 0xffff0020($0)#currX
	beq	$t4, $t6,equal
	bgt	$t4, $t6,equal



exist_right:
	beq	$t1, $0, vetical#NULL , last of array, does not exist,find new
	add	$t5, $t5,16
	lw	$t1, 0($t5)#id of each element in the array
	
	beq	$t1, $t7, exist#id exist
exist:
	sub	$t5, $t5, 16
	lw	$t4, 0xffff0020($0)
	#lw	$s0,8($t4) ###current x
	#lw	$s3,12($t4)
	add	$t5, $t5, 16
	j	exist_right

left_while:
	#j	equal
	li	$t0, 10
	sw	$t0, 0xffff0010($0)#speed

	li	$t0, 180 #left
	sw	$t0, 0xffff0014($0)
	li	$t0, 1
	sw	$t0, 0xffff0018

	la	$t5, fruit_array
	sw	$t5, FRUIT_SCAN
	lw	$t1, 0($t5)#/id
	lw	$t4, 0xffff0020($0)#currX
	beq	$t4, $t6, equal
	#blt	$t4,$t6,equal
	bge	$t4, $t6, equal


exist_left:
	beq	$t1, $0, vetical	#NULL , last of array, does not exist,find new
	add	$t5, $t5, 16
	lw	$t1, 0($t5)		#id

	beq	$t1, $t7, left_while	#id exist
	j	exist_left

equal:
	li	$t0, 0
	sw	$t0, 0xffff0010($0)	#speed

	la	$t5, fruit_array
	sw	$t5, FRUIT_SCAN
	lw	$t1, 0($t5)		#id

	

exist_equal:
	beq	$t1, $0,vetical	#NULL , last of array, does not exist,find new
	add	$t5, $t5, 16
	lw	$t1, 0($t5)		#id

	beq	$t1, $t7, equal		#id exist
	j	exist_equal

	# enable interrupts
	li	$t4, TIMER_MASK		# timer interrupt enable bit
	or	$t4, $t4, BONK_MASK	# bonk interrupt bit
	or	$t4, $t4, 1		# global interrupt enable
	mtc0	$t4, $12		# set interrupt mask (Status register)

	# request timer interrupt
	lw	$t0, TIMER		# read current time
	add	$t0, $t0, 50		# add 50 to current time
	sw	$t0, TIMER		# request timer interrupt in 50 cycles

	li	$a0, 10
	sw	$a0, VELOCITY		# drive


smash_down:
	li	$t2, 10			##VELOCITY
	sw	$t2, 0xffff0010($0)	#speed
	li	$t2, 90 		#//vertical!!!!!!
	sw	$t2, 0xffff0014($0)
	li	$t2, 1
	sw	$t2, 0xffff0018

	la	$t0, num
	lw	$t0, 0($t0)

	beq	$t0, 0, vetical
	j	smash_down


	

.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 16	# space for 4 registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"


.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at		# Save $at                               
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers                  
	sw	$a1, 4($k0)
	sw	$a2, 8($k0)
	sw	$a3, 12($k0)		# by storing them to a global variable     
	sw	$t0, 16($k0)
	sw	$t1, 20($k0)
	sw	$v0, 24($k0)
	
	
	sw	$ra, 28($k0)
	
	sw	$s0, 32($k0)
	sw	$s1, 36($k0)
	sw	$s2, 40($k0)
	sw	$s3, 44($k0)
	sw	$s4, 48($k0)
	sw	$s5, 52($k0)
	sw	$s6, 56($k0)
	sw	$s7, 60($k0)
	
	sw	$sp, 64($k0)

	mfc0	$k0, $13		# Get Cause register                       
	srl	$a0, $k0, 2                
	and	$a0, $a0, 0xf		# ExcCode field                            
	bne	$a0, 0, non_intrpt         

interrupt_dispatch:			# Interrupt:                             
	mfc0	$k0, $13		# Get Cause register, again                 
	beq	$k0, 0, done		# handled all outstanding interrupts     

	and	$a0, $k0, BONK_MASK	# is there a bonk interrupt?                
	bne	$a0, 0, bonk_interrupt   

	and 	$a0,$k0,FRUIT_SMOOSHED_INT_MASK
	bne	$a0,0,smoosh_interrupt
	
	and 	$a0, $k0, REQUEST_PUZZLE_INT_MASK		# is there a timer interrupt?
	bne 	$a0, 0, puzzle_interrupt

	# add dispatch for other interrupt types here.

	li	$v0, PRINT_STRING	# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall 
	j	done

bonk_interrupt:
	lw	$t0, num
smash_fruit:
	beq	$t0, $0, ack
	
	sw	$a0, FRUIT_SMASH
	sub	$t0, $t0,1
	
	j	smash_fruit	
ack:
	sw	$0,  num
	sw	$a1, BONK_ACK		# acknowledge interrupt
	##sw	$zero, VELOCITY		# ???
	
	li	$t2, 270 		
	sw	$t2, ANGLE
	li	$t2, 1
	sw	$t2, ANGLE_CONTROL
	sw	$0, VELOCITY
	
smash_up:
	li	$t2, 10			
	sw	$t2, VELOCITY
	
	lw	$t0, BOT_Y		#currY
	li	$t1, 270
	
	ble	$t0, $t1, here

	##lw	$t0, 0xffff0024($0)	#currY
	j	smash_up		##problem!!!


here:
	j	interrupt_dispatch	# see if other interrupts are waiting


smoosh_interrupt:
	la	$a3,num
	lw	$t0,0($a3)
	add	$t0,$t0,1	
	sw	$t0,0($a3) #not sure about this
	sw	$a1, FRUIT_SMOOSHED_ACK
	j	interrupt_dispatch
puzzle_interrupt:			
	
	lw	$s5, VELOCITY
	sw	$0, VELOCITY
				
	sw	$a1, REQUEST_PUZZLE_ACK # acknowledge interrupt
	la	$t0, puzzle_word
	sw	$t0, REQUEST_WORD
	
	la 	$t0, puzzle_grid
	lw 	$t1, 0($t0)
	sw  	$t1, num_rows
	
	lw 	$t1, 4($t0)
	sw 	$t1, num_cols
	
	add	$a0, $t0, 8
	la	$a1, puzzle_word
	li	$a2, 0
	li	$a3, 0
	
	jal	solve_puzzle
	
	bne	$v0, $0, sn_finished 
	
	la	$t0, puzzle_grid
	sw	$t0, REQUEST_PUZZLE
	j 	interrupt_dispatch
	
sn_finished:	
	sw  	$v0, SUBMIT_SOLUTION
	move	$a0, $v0
	li	$v0, PRINT_INT
	syscall
	
	li	$a0, ' '
	li	$v0, PRINT_CHAR
	syscall
	
	sw	$s5, VELOCITY
	
	
	j 	interrupt_dispatch		

non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING
	la	$a0, non_intrpt_str
	syscall				# print out an error message
	# fall through to done
allocate_new_node:		
	lw	$v0, new_node_address
	add	$t0, $v0, NODE_SIZE
	sw	$t0, new_node_address	
	jr	$ra
	##allocate new node finished

set_node:	
	sub     $sp, $sp, 16
	sw      $a0, 0($sp)
	sw      $a1, 4($sp)
	sw      $a2, 8($sp)
	sw      $ra, 12($sp)
	jal     allocate_new_node
	move    $t0, $v0
	
	lw      $a0, 0($sp) 
	lw      $a1, 4($sp)
	lw      $a2, 8($sp)
	lw      $ra, 12($sp)
	
	sw      $a0, 0($t0)
	sw	$a1, 4($t0)
	sw	$a2, 8($t0)
	
	add     $sp, $sp, 16
	move	$v0, $t0		
	jr	$ra
	
##set node finished



## Node *
## search_neighbors(char *puzzle, const char *word, int row, int col) {
##     if (word == NULL) {
##         return NULL;
##     }
##     for (int i = 0; i < 4; i++) {
##         int next_row = row + directions[i][0];
##         int next_col = col + directions[i][1];
##         // boundary check
##
##
##
##				
##		if ( next row == num_rows ){
##			next row = 0;
##			next col ++;
##		}
##
##		if ( next col == num cols){
##			next col = 0;
##			next row ++;
##		}
##
##
##
##		
##     *    if ((next_row > -1) && (next_row < num_rows) && (next_col > -1) &&
##             (next_col < num_cols)) {
##             if (puzzle[next_row * num_cols + next_col] == *word) {
##                 if (*(word + 1) == '\0') {
##                     return set_node(next_row, next_col, NULL);
##                 }
##                 // mark the spot on puzzle as visited
##                 puzzle[next_row * num_cols + next_col] = '*';
##                 // search for next char in the word
##                 Node *next_node =
##                     search_neighbors(puzzle, word + 1, next_row, next_col);
##                 // unmark
##                 puzzle[next_row * num_cols + next_col] = *word;
##                 // if there is a valid neighbor, return the linked list
##                 if (next_node) {
##                     return set_node(next_row, next_col, next_node);
##                 }
##             }
##         }
##     }
##     return NULL;
## }


search_neighbors:
	bne	$a1, 0, sn_main		# !(word == NULL)
	li	$v0, 0			# return NULL (data flow)
	jr	$ra			# return NULL (control flow)

sn_main:
	sub	$sp, $sp, 36
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)
	sw	$s7, 32($sp)

	move	$s0, $a0		# puzzle
	move	$s1, $a1		# word
	move	$s2, $a2		# row
	move	$s3, $a3		# col
	li	$s4, 0			# i

sn_loop:
	mul	$t0, $s4, 8		# i * 8
	lw	$t1, directions($t0)	# directions[i][0]
	add	$s5, $s2, $t1		# next_row
	lw	$t1, directions+4($t0)	# directions[i][1]
	add	$s6, $s3, $t1		# next_col

	lw	$t0, num_rows		# my new code goes here
	bne	$t0, $s5, skip1		##
	li	$s5, 0			##
	add	$s6, $s6, 1
	
					##
skip1:					##
	lw	$t0, num_cols		##
	bne	$t0, $s6, skip2		##
	li	$s6, 0			##
	add	$s5, $s5, 1
skip2:

	ble	$s5, -1, sn_next	# !(next_row > -1)
	lw	$t0, num_rows
	bge	$s5, $t0, sn_next	# !(next_row < num_rows)
	ble	$s6, -1, sn_next	# !(next_col > -1)
	lw	$t0, num_cols
	bge	$s6, $t0, sn_next	# !(next_col < num_cols)

	mul	$t0, $s5, $t0		# next_row * num_cols
	add	$t0, $t0, $s6		# next_row * num_cols + next_col
	add	$s7, $s0, $t0		# &puzzle[next_row * num_cols + next_col]
	lb	$t0, 0($s7)		# puzzle[next_row * num_cols + next_col]
	lb	$t1, 0($s1)		# *word
	bne	$t0, $t1, sn_next	# !(puzzle[next_row * num_cols + next_col] == *word)

	lb	$t0, 1($s1)		# *(word + 1)
	bne	$t0, 0, sn_search	# !(*(word + 1) == '\0')
	move	$a0, $s5		# next_row
	move	$a1, $s6		# next_col
	li	$a2, 0			# NULL
	jal	set_node		# $v0 will contain return value
	j	sn_return

sn_search:
	li	$t0, '*'
	sb	$t0, 0($s7)		# puzzle[next_row * num_cols + next_col] = '*'
	move	$a0, $s0		# puzzle
	add	$a1, $s1, 1		# word + 1
	move	$a2, $s5		# next_row
	move	$a3, $s6		# next_col
	jal	search_neighbors
	lb	$t0, 0($s1)		# *word
	sb	$t0, 0($s7)		# puzzle[next_row * num_cols + next_col] = *word
	beq	$v0, 0, sn_next		# !next_node
	move	$a0, $s5		# next_row
	move	$a1, $s6		# next_col
	move	$a2, $v0		# next_node
	jal	set_node
	j	sn_return

sn_next:
	add	$s4, $s4, 1		# i++
	blt	$s4, 4, sn_loop		# i < 4
	
	li	$v0, 0			# return NULL (data flow)

sn_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	lw	$s7, 32($sp)
	add	$sp, $sp, 36
	jr	$ra
##search neighbour finished

solve_puzzle:
	sub	$sp, $sp, 24
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)

	move	$s0, $a0		# puzzle
	move	$s1, $a1		# word

	lb	$t0, 0($s1)		# word[0]
	beq	$t0, 0, sp_true		# word[0] == '\0'

	li	$s2, 0			# row = 0

sp_row_for:
	lw	$t0, num_rows
	bge	$s2, $t0, sp_false	# !(row < num_rows)

	li	$s3, 0			# col = 0

sp_col_for:
	lw	$t0, num_cols
	bge	$s3, $t0, sp_row_next	# !(col < num_cols)

	move	$a0, $s0		# puzzle
	move	$a1, $s2		# row
	move	$a2, $s3		# col
	jal	get_char		# $v0 = current_char
	lb	$t0, 0($s1)		# target_char = word[0]
	bne	$v0, $t0, sp_col_next	# !(current_char == target_char)

##	move	$a0, $s0		# puzzle
##	move	$a1, $s2		# row
##	move	$a2, $s3		# col
##	li	$a3, '*'
##	jal	set_char

	move	$a0, $s0		# puzzle
	add	$a1, $s1, 0		# word + 1
	move	$a2, $s2		# row
	move	$a3, $s3		# col
	jal	search_neighbors
	move	$s4, $v0		# exist

##	move	$a0, $s0		# puzzle
##	move	$a1, $s2		# row
##	move	$a2, $s3		# col
##	lb	$a3, 0($s1)		# word[0]
##	jal	set_char

	bne	$s4, 0, sp_true		# if (exist)

sp_col_next:
	add	$s3, $s3, 1		# col++
	j	sp_col_for

sp_row_next:
	add	$s2, $s2, 1		# row++
	j	sp_row_for

sp_false:
	li	$v0, 0			# false
	j	sp_done

sp_true:
	move	$v0, $s4		# true

sp_done:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	add	$sp, $sp, 24
	jr	$ra

get_char:
	lw	$v0, num_cols
	mul	$v0, $a1, $v0	# row * num_cols
	add	$v0, $v0, $a2	# row * num_cols + col
	add	$v0, $a0, $v0	# &array[row * num_cols + col]
	lb	$v0, 0($v0)	# array[row * num_cols + col]
	jr	$ra

set_char:
	lw	$v0, num_cols
	mul	$v0, $a1, $v0	# row * num_cols
	add	$v0, $v0, $a2	# row * num_cols + col
	add	$v0, $a0, $v0	# &array[row * num_cols + col]
	sb	$a3, 0($v0)	# array[row * num_cols + col] = c
	jr	$ra



done:
	la	$k0, chunkIH
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Get some free registers                  
	lw	$a1, 4($k0)
	lw	$a2, 8($k0)
	lw	$a3, 12($k0)		
	lw	$t0, 16($k0)
	lw	$t1, 20($k0)
	lw	$v0, 24($k0)
	lw	$ra, 28($k0)
	
	lw	$s0, 32($k0)
	lw	$s1, 36($k0)
	lw	$s2, 40($k0)
	lw	$s3, 44($k0)
	lw	$s4, 48($k0)
	lw	$s5, 52($k0)
	lw	$s6, 56($k0)
	lw	$s7, 60($k0)
	
	lw	$sp, 64($k0)

.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret
