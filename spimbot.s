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
puzzle_grid: .space 8200
puzzle_word: .space 128
num_rows:    .space 4
num_cols:    .space 4
counter:     .space 4

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

cycle:	
	##li	$t4, 0
	sw	$0, counter
	
	li	$t4, FRUIT_SMOOSHED_INT_MASK 		
	or	$t4, $t4, BONK_MASK	
	or	$t4, $t4, TIMER_MASK
	or	$t4, $t4, REQUEST_PUZZLE_INT_MASK
	or	$t4, $t4, OUT_OF_ENERGY_INT_MASK
	or	$t4, $t4, 1				# global interrupt enable
	mtc0	$t4, $12
	
	li	$t2, 0
	sw	$t2, VELOCITY	
	li	$t2, 90
	sw	$t2, ANGLE	
	li	$t2, 1 					##t2 is temporary here
	sw	$t2, ANGLE_CONTROL
	lw	$t0, GET_ENERGY	
	ble	$t0, 95, we_need_energy
	j	cycle

we_need_energy:
	
	la	$t0, puzzle_grid
	sw 	$t0, REQUEST_PUZZLE
	add	$a0, $t0, 8

	la	$a1, puzzle_word
	li	$a2, 0
	li	$a3, 0
	
	la 	$t0, puzzle_grid
	lw 	$t1, 0($t0)
	sw  	$t1, num_rows
	
	lw 	$t1, 4($t0)
	sw 	$t1, num_cols
	
	jal	search_neighbors
	
	
	
	sw  	$v0, SUBMIT_SOLUTION
	
	move	$a0, $v0
	li     	$v0, PRINT_INT	
	syscall
	
	
	j cycle
	
allocate_new_node:	
	
	lw	$v0, new_node_address
	add	$t0, $v0, NODE_SIZE
	sw	$t0, new_node_address	
	jr	$ra
##allocate new node finished







set_node:	
	# Your code goes here :)
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
	move	$v0, $t0		# Don't forget to replace this!
	jr	$ra
	
##set node finished






remove_node:
	# Your code goes here :)

	add     $t0, $0, $a0    ##t0 serves as curr
rn_loop:	lw	$t1, 0($t0)	##t1 is the value for *curr
	beq	$t1, 0, end
	add	$t2, $0, $t1	##t2 serves as the entry
	
	lw	$t3, 0($t2)     ##t3 is entry->row
	lw	$t4, 4($t2)	##t4 is entry->col
	
	beq	$t3, $a1, equal1
remove_endloop:
	add     $t0, $t2, 8
	j	rn_loop
	
	
if:	
	lw	$t5, 8($t2)	##t5 is the value we are about to store in *curr
	sw	$t5, 0($t0)
	j       end
	
equal1:	
	beq	$t4, $a2, if
	j	remove_endloop
end:	
	jr	$ra
##remove node finished





search_neighbors:
	sub $sp, $sp, 40
	sw  $s0, 0($sp)
	sw  $s1, 4($sp)
	sw  $s2, 8($sp)
	sw  $s3, 12($sp)
	sw  $s4, 16($sp)
	sw  $s5, 20($sp)
	sw  $s6, 24($sp)
	sw  $s7, 28($sp)
	
		
	beq $a1, 0, return_null
	
	li  $t0, 0                  ##t0 serves as int i
	
loop:	bge $t0, 4, return_null

	la  $t7, directions	
	
	mul $t1, $t0, 2
	
	mul $t1, $t1, 4
	
	add $t1, $t1, $t7
	lw  $t2, 0($t1)
	add $t2, $t2, $a2           ##t2 serves as next_row
	
	mul $t1, $t0, 2
	add $t1, $t1, 1
	
	mul $t1, $t1, 4
	
	add $t1, $t1, $t7
	
	lw $t3, 0($t1)
	add $t3, $t3, $a3           ##t3 serves as next_col
	
	lw  $s0, num_rows
	lw  $s1, num_cols
	
	ble $t2, -1, end_of_loop
	bge $t2, $s0, end_of_loop
	ble $t3, -1, end_of_loop
	bge $t3, $s1, end_of_loop
	
	mul $t4, $t2, $s1
	add $t4, $t4, $t3
	add $t4, $t4, $a0
	lbu $t4, 0($t4)
	lbu $t5, 0($a1)
	bne $t4, $t5, end_of_loop
	
	##add $t5, $a1, 1
	lb  $t5, 1($a1)
	beq $t5, 0, jump1
	
	mul $t4, $t2, $s1
	add $t4, $t4, $t3
	add $t4, $t4, $a0
	
	li  $t5, 42
	
	sb  $t5, 0($t4)
	
	## I'll use $t6 as my next_node
	move $s2, $a0
	move $s3, $a1
	move $s4, $a2
	move $s5, $a3 
	move $s6, $ra
	move $s7, $t0 ##i
	sw   $t2, 32($sp)
	sw   $t3, 36($sp)
	
	add  $a1, $a1, 1
	move $a2, $t2
	move $a3, $t3
	jal  search_neighbors
	
	move $t6, $v0
	
	move $a0, $s2
	move $a1, $s3
	move $a2, $s4
	move $a3, $s5 
	move $ra, $s6
	move $t0, $s7
	lw   $t2, 32($sp)
	lw   $t3, 36($sp)
	
	mul $t4, $t2, $s1
	add $t4, $t4, $t3
	add $t4, $t4, $a0
	
	lbu  $t5, 0($a1)
	sb   $t5, 0($t4)
	
	beq  $t6, 0, end_of_loop
	move $s2, $a0
	move $s3, $a1
	move $s4, $a2
	move $s5, $a3 
	move $s6, $ra
	move $s7, $t0 ##i
	sw   $t2, 32($sp)
	sw   $t3, 36($sp)
	
	move $a0, $t2
	move $a1, $t3
	move $a2, $t6
	jal  set_node
	
	move $ra, $s6
	
	lw  $s0, 0($sp)
	lw  $s1, 4($sp)
	lw  $s2, 8($sp)
	lw  $s3, 12($sp)
	lw  $s4, 16($sp)
	lw  $s5, 20($sp)
	lw  $s6, 24($sp)
	lw  $s7, 28($sp)
	
	add  $sp, $sp, 40
	
	jr   $ra
	
	
jump1:	
	move $s2, $a0
	move $s3, $a1
	move $s4, $a2
	move $s5, $a3 
	move $s6, $ra
	move $s7, $t0 ##i
	sw   $t2, 32($sp)
	sw   $t3, 36($sp)
	
	move $a0, $t2
	move $a1, $t3
	li   $a2, 0
	
	
	jal  set_node

	
	
	move $ra, $s6
	
	lw  $s0, 0($sp)
	lw  $s1, 4($sp)
	lw  $s2, 8($sp)
	lw  $s3, 12($sp)
	lw  $s4, 16($sp)
	lw  $s5, 20($sp)
	lw  $s6, 24($sp)
	lw  $s7, 28($sp)
	
	add $sp, $sp, 40
	jr   $ra
	
	
end_of_loop:
	add $t0, $t0, 1
	j   loop
	
return_null:
	
	
	li	$v0, 0	
	
	lw  $s0, 0($sp)
	lw  $s1, 4($sp)
	lw  $s2, 8($sp)
	lw  $s3, 12($sp)
	lw  $s4, 16($sp)
	lw  $s5, 20($sp)
	lw  $s6, 24($sp)
	lw  $s7, 28($sp)
	
	add     $sp, $sp, 40		# Don't forget to replace this!
	jr	$ra
##search neighbour finished



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
	sw	$a1, 4($k0)		# by storing them to a global variable     
	sw	$t0, 8($k0)
	sw	$t1, 12($k0)
	
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
	j	interrupt_dispatch	# see if other interrupts are waiting	
	
	
bonk_interrupt:
	sw	$a1, FRUIT_SMASH
	sw	$a1, FRUIT_SMASH
	sw	$a1, FRUIT_SMASH
	lw	$t0, counter
	
	sub	$t0, $t0, 3
	
	sw	$t0, counter
	sw	$a1, BONK_ACK		# acknowledge interrupt
	
	sw	$0, VELOCITY		
	
relocate:
	li	$a1, 270
	sw	$a1, ANGLE
	
	li	$a1, 1 			##t2 is temporary here
	sw	$a1, ANGLE_CONTROL
	
	li	$a1, 10
	sw	$a1, VELOCITY
	
	lw	$t4, BOT_Y	
	ble	$t4, 280, interrupt_dispatch
	j	relocate
	
		
	
timer_interrupt:
		
	sw 	$a1, TIMER_ACK	 	# acknowledge interrupt
						
	## more to be added		
					
	lw 	$v0, 0xffff001c($0) 	# current time
	add 	$v0, $v0, 50000		
	sw 	$v0, 0xffff001c($0) 	# request timer in 50000
					
	j 	interrupt_dispatch 	# see if other interrupts are waiting
	
no_energy:
	sw 	$a1, OUT_OF_ENERGY_ACK	##acknowledge interrupt
	
	j 	interrupt_dispatch 
					
puzzle_interrupt:			
									
	la	$t0, puzzle_word	
	sw	$t0, 0xffff00dc($0)	
					
	sw	$a1, REQUEST_PUZZLE_ACK # acknowledge interrupt
	
	
	j 	interrupt_dispatch	
					
non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING	
	la	$a0, non_intrpt_str	
	syscall				# print out an error message
	# fall through to done

done:
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Restore saved registers
	lw	$a1, 4($k0)
	lw	$t0, 8($k0)
	lw	$t1, 12($k0)
.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret
