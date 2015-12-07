.data
# syscall constants
PRINT_INT = 1
PRINT_STRING = 4
PRINT_CHAR = 11
# spimbot constants
VELOCITY      = 0xffff0010
ANGLE         = 0xffff0014
ANGLE_CONTROL = 0xffff0018
BOT_X         = 0xffff0020
BOT_Y         = 0xffff0024

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

fruit_data:  .space 260
puzzle_grid: .space 8192

puzzle_word: .space 128

num_rows:    .space 4
num_cols:    .space 4
counter:     .space 4
flag:	     .space 4  ##determine if puzzle is ready
flag2:	     .space 4  ##determine if puzzle is been requested

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
	
	li	$t4, FRUIT_SMOOSHED_INT_MASK 		
	or	$t4, $t4, BONK_MASK	
	or	$t4, $t4, TIMER_MASK
	or	$t4, $t4, REQUEST_PUZZLE_INT_MASK
	or	$t4, $t4, OUT_OF_ENERGY_INT_MASK
	or	$t4, $t4, 1				# global interrupt enable
	mtc0	$t4, $12
	
	sw	$0, counter
	sw	$0, flag2
	move 	$s3, $0					# initialize my counter
	
	la	$s0, fruit_data
	sw      $s0, FRUIT_SCAN
	move	$s2, $s0
	
	lw	$t4, BOT_Y
	
while:	
	ble	$t4, 100, conti
	
	li	$t2, 0
	sw	$t2, VELOCITY
	
	li	$t2, 270
	sw	$t2, ANGLE
	
	li	$t2, 1 ##t2 is temporary here
	sw	$t2, ANGLE_CONTROL
	
	li	$t2, 10
	sw	$t2, VELOCITY

	

	
	
move_up:
	lw	$t4, BOT_Y	
	ble	$t4, 100, conti
	j	move_up

conti:	
	li	$t2, 0
	sw	$t2, VELOCITY
	
	
move_horiz:
	la      $t0, fruit_data    	##t0 is the address for our fruit

	sw      $t0, FRUIT_SCAN	
compare:	
	lw	$t4, counter
	bne	$t4, 0, letssmash
	j	compare2
	
letssmash:
	li	$t2, 90
	sw	$t2, ANGLE
	
	li	$t2, 1 
	sw	$t2, ANGLE_CONTROL
	
	##lw	$t4, BOT_Y
	##li	$t2, 50
	##ble	$t4, $t2, compare2
	
	li	$t2, 10
	sw	$t2, VELOCITY
	
	j	compare
	
	
compare2:
	li	$t2, 0
	sw	$t2, VELOCITY
	
	add	$s3, $s3, 1
	add	$s2, $s2, 16
	la	$t2, fruit_data
	add	$t2, $t2, 240
	
	bge	$s2, $t2, gobacktofirstone
	j	compare2Conti
gobacktofirstone:
	move	$s3, $0
	la	$s2, fruit_data
	
compare2Conti:

	lw	$t0, counter
	bne	$t0, 0, letssmash
	lw	$t6, 8($s2)
	
	lw	$t5, BOT_X
	
	##sub	$t7, $t5, $t6
	
	li	$t1, 20
	li	$t2, 280
	ble	$t6, $t1,compare
	bge	$t6, $t2,compare
	
	bgt	$t5, $t6, move_left
	blt	$t5, $t6, move_right
	move	$s4, $0		##stay counter
	beq	$t5, $t6, stay
	
move_left:
	
	li	$t2, 180
	sw	$t2, ANGLE
	
	li	$t2, 1 ##t2 is temporary here
	sw	$t2, ANGLE_CONTROL
	
	li	$t2, 5
	sw	$t2, VELOCITY
	
	
move_l:	
	la      $t0, fruit_data    

	sw      $t0, FRUIT_SCAN	
	
	lw	$t6, 8($s2)
	
	lw	$t5, BOT_X

	bgt	$t5, $t6, move_l
	
	j	compare2Conti
	
move_right:
	

	
	li	$t2, 0
	sw	$t2, ANGLE
	
	li	$t2, 1 ##t2 is temporary here
	sw	$t2, ANGLE_CONTROL
	
	li	$t2, 5
	sw	$t2, VELOCITY
	
move_r:	
	la      $t0, fruit_data    

	sw      $t0, FRUIT_SCAN	
	
	
	
	lw	$t6, 8($s2)
	
	lw	$t5, BOT_X
	sub	$t7, $t5, $t6
	

	blt	$t7, 0, move_r
	
	j	compare2Conti
	
stay:	
	add	$s4, $s4, 1
	lw	$s3, counter
	
	sw	$0, VELOCITY
	j	cycle
	
cycle_return:
	lw	$t9, 0($s2)	
	la      $t0, fruit_data    	
	sw      $t0, FRUIT_SCAN
	lw	$t6, 0($s2)
	lw	$t8, 12($s2)
	
	bge	$t8, 150, compare
	lw	$t0, counter
	bne	$t0, 0, letssmash
	bne	$t9, $t6, compare
	
	li	$t5, 200
	bge	$s4, $t5, compare
	j	stay
	
cycle:	
	
	lw	$s1, VELOCITY
	sw	$0, VELOCITY	
	lw	$t0, GET_ENERGY	
	ble	$t0, 50, we_need_energy
cycle_end:
	sw	$s1, VELOCITY
	j	cycle_return
		

we_need_energy:	
	lw	$t0, flag2
	bne	$t0, $0, cycle_end 
	
	li	$t0, 1
	sw	$t0, flag2
	la	$t0, puzzle_grid
	sw 	$t0, REQUEST_PUZZLE
	j 	cycle_end
	


.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 68	# space for 4 registers
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
	
	
	
	and	$a0, $k0, FRUIT_SMOOSHED_INT_MASK 	# is there a smooshing interrupt?
	bne	$a0, 0, smooshed_interrupt
	
	and	$a0, $k0, BONK_MASK	# is there a bonk interrupt?                
	bne	$a0, 0, bonk_interrupt
	
	and 	$a0, $k0, TIMER_MASK		# is there a timer interrupt?
	bne 	$a0, 0, timer_interrupt
	
	and 	$a0, $k0, REQUEST_PUZZLE_INT_MASK		# is there a timer interrupt?
	bne 	$a0, 0, puzzle_interrupt
	
	and 	$a0, $k0, OUT_OF_ENERGY_INT_MASK
	bne 	$a0, 0, no_energy
	j	non_intrpt
	
smooshed_interrupt:	
	lw	$t0, counter
	add	$t0, $t0, 1
	sw	$t0, counter
	sw	$a1, FRUIT_SMOOSHED_ACK
letssmash2:
	li	$t2, 90
	sw	$t2, ANGLE
	
	li	$t2, 1 
	sw	$t2, ANGLE_CONTROL
	
	##lw	$t4, BOT_Y
	##li	$t2, 50
	##ble	$t4, $t2, compare2
	
	li	$t2, 10
	sw	$t2, VELOCITY
	
	
	j	interrupt_dispatch	# see if other interrupts are waiting	
	
bonk_interrupt:
	# acknowledge interrupt
	
	

	sw	$a1, FRUIT_SMASH
	sw	$a1, FRUIT_SMASH
	sw	$a1, FRUIT_SMASH
	sw	$0, counter
	sw	$a1, BONK_ACK		
	
relocate:
	li	$a1, 270
	sw	$a1, ANGLE
	
	li	$a1, 1 			##t2 is temporary here
	sw	$a1, ANGLE_CONTROL
	
	li	$a1, 10
	sw	$a1, VELOCITY
	
relocate2:
	lw	$t2, BOT_Y	
	sw	$0, VELOCITY
	ble	$t2, 100, interrupt_dispatch
	li	$a1, 10
	sw	$a1, VELOCITY
	j	relocate2
	

		
	
timer_interrupt:
		
	sw 	$a1, TIMER_ACK	 	# acknowledge interrupt
						
	## more to be added		
					
	lw 	$v0, 0xffff001c($0) 	# current time
	add 	$v0, $v0, 50000		
	sw 	$v0, 0xffff001c($0) 	# request timer in 50000
					
	j 	interrupt_dispatch 	# see if other interrupts are waiting
	
no_energy:
		
	la	$t0, puzzle_grid
	sw 	$t0, REQUEST_PUZZLE
	sw 	$a1, OUT_OF_ENERGY_ACK
	lw	$0, VELOCITY
	j 	interrupt_dispatch 
					
puzzle_interrupt:	
	sw	$0, flag2
	li	$a0, 1
	li	$v0, PRINT_INT
	syscall		
					
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

	jal	search_neighbors

	sw  	$v0, SUBMIT_SOLUTION
	j 	interrupt_dispatch	

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

					
non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING	
	la	$a0, non_intrpt_str	
	syscall				# print out an error message
					# fall through to done
done:
	
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
