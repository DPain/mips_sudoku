.data
newline:.asciiz "\n"			# useful for printing commands
star:   .asciiz "*"
board1: .word 128 511 511 16 511 511 4 2 511 64 511 4 1 511 511 8 511 511 1 2 511 511 511 256 511 511 128 32 16 511 511 256 4 511 128 511 511 256 511 511 511 511 511 1 511 511 128 511 32 2 511 511 256 4 2 511 511 8 511 511 511 32 64 511 511 32 511 511 128 1 511 2 511 64 8 511 511 32 511 511 16
board2: .word 128 8 256 16 32 64 4 2 1 64 32 4 1 128 2 8 16 256 1 2 16 4 8 256 32 64 128 32 16 1 64 256 4 2 128 8 4 256 2 128 16 8 64 1 32 8 128 64 32 2 1 16 256 4 2 1 128 8 4 16 256 32 64 16 4 32 256 64 128 1 8 2 256 64 8 2 1 32 128 4 16
	
.text
# main function
main:
	sub		 $sp, $sp, 4
	sw		  $ra, 0($sp) # save $ra on stack
	
	# Our global variables
	li		  $s0, 9
	mult		$s0, $s0
	mflo		$s1

	# test singleton (true case)
	li  $a0, 0x010
	jal singleton
	move		$a0, $v0
	jal print_int_and_space
	# this should print 1

	# test singleton (false case)
	li  $a0, 0x10b
	jal singleton
	move		$a0, $v0
	jal print_int_and_space
	# this should print 0

	# test get_singleton 
	li  $a0, 0x010
	jal get_singleton
	move		$a0, $v0
	jal print_int_and_space
	# this should print 4

	# test get_singleton 
	li  $a0, 0x008
	jal get_singleton
	move		$a0, $v0
	jal print_int_and_space
	# this should print 3

	# test board_done (true case)
	la  $a0, board2
	jal board_done
	move		$a0, $v0
	jal print_int_and_space
	# this should print 1
	
	# test board_done (false case)
	la  $a0, board1
	jal board_done
	move		$a0, $v0
	jal print_int_and_space
	# this should print 0

	# print a newline
	li  $v0, 4
	la  $a0, newline
	syscall	 

	# test print_board
	la  $a0, board1
	jal print_board

	# should print the following:
	# 8**5**32*
	# 7*31**4**
	# 12***9**8
	# 65**93*8*
	# *9*****1*
	# *8*62**93
	# 2**4***67
	# **6**81*2
	# *74**6**5

	lw		  $ra, 0($sp)	 # restore $ra from stack
	add		 $sp, $sp, 4
	jr  $ra

print_int_and_space:
	li		  $v0, 1		  # load the syscall option for printing ints
	syscall					 # print the element

	li		  $a0, 32		 # print a black space (ASCII 32)
	li		  $v0, 11		 # load the syscall option for printing chars
	syscall					 # print the char
	
	jr	  $ra				 # return to the calling procedure

print_newline:
	li  $v0, 4		  # at the end of a line, print a newline char.
	la  $a0, newline
	syscall		 
	jr  $ra

print_star:
	li  $v0, 4		  # print a "*"
	la  $a0, star
	syscall
	jr  $ra
	
	
# ALL your code goes below this line.
#
# We will delete EVERYTHING above the line; DO NOT delete 
# the line.
#
# ---------------------------------------------------------------------
	
## bool singleton(int value) {  // This function checks whether
##   return (value != 0) && !(value & (value - 1));
## }
singleton:
	beq	 $a0, $0, false
	
	addi	$t0, $a0, -1
	and	 $t0, $t0, $a0

	bne	 $t0, $0, false

	# true
	li	  $v0, 1
	j	   end_if

	# false
	false:
		li	  $v0, 0
	end_if:
		jr  $ra


## int get_singleton(int value) {
##   for (int i = 0 ; i < GRID_SQUARED ; ++ i) {
##	   if (value == (1<<i)) {
##			  return i;
##	   }
##   }
##   return 0;
## }
get_singleton:
	li  $t0, 0

	for_a:
		slt	 $t1, $t0, $s0
		li	  $t3, 1
		bne	 $t1, $t3, end_for_a
		li	  $t2, 1
		sllv	$t2, $t2, $t0
		
		bne	 $a0, $t2, incr_for_a
		j	   end_for_a
	incr_for_a:
		addi	$t0, $t0, 1
		j	   for_a
	end_for_a:
		add	 $v0, $t0, $0
		jr $ra


## bool
## board_done(int board[GRID_SQUARED][GRID_SQUARED]) {
##   for (int i = 0 ; i < GRID_SQUARED ; ++ i) {
##	   for (int j = 0 ; j < GRID_SQUARED ; ++ j) {
##			  if (!singleton(board[i][j])) {
##				return false;
##			  }
##	   }
##   }
##   return true;
## }

board_done:
	#$t0 = i
	li  $t0, 0
	
	for_b:
		slt	 $t1, $t0, $s1
		li	  $t2, 1
		bne	 $t1, $t2, end_for_b
		
		# Multiply i by 4 to calculate the offset for ptr address from the base address to access the element
		sll		$t3, $t0, 2
		# Address of the element that will be accessed
		add		$t3, $a0, $t3
		
		# Prep code to call singleton function
		addi	$sp, $sp, -12	# $sp = $sp + -12
		sw		$ra, 0($sp)		# store $ra into sp(0)
		sw		$a0, 4($sp)		# store the base address
		sw		$t0, 8($sp)		# store the ctr
		
		# Load arguement and call function
		lw		$a0, 0($t3)
		jal		singleton
		
		# Post code for singleton function
		lw		$ra, 0($sp)		# restore $ra
		lw		$a0, 4($sp)		# restore $a0
		lw		$t0, 8($sp)		# restore the ctr
		addi	$sp, $sp, 12	# $sp = $sp + 12
		
		# Checks if accessed element is empty
		beq		$v0, $0, return_b
		
		j	   incr_for_b
		
	incr_for_b:
		addi	$t0, $t0, 1
		j	   for_b
	end_for_b:
		li		$v0, 1
		j	   return_b
	return_b:
		jr $ra
	
## void
## print_board(int board[GRID_SQUARED][GRID_SQUARED]) {
##   for (int i = 0 ; i < GRID_SQUARED ; ++ i) {
##	   for (int j = 0 ; j < GRID_SQUARED ; ++ j) {
##			  int value = board[i][j];
##			  char c = '*';
##			  if (singleton(value)) {
##				c = get_singleton(value) + '1';
##			  }
##			  printf("%c", c);
##	   }
##	   printf("\n");
##   }
## }

print_board:
    li $t7, 42

    #$t0 = i
	li  $t0, 0
	
	for_c:
		slt	 $t1, $t0, $s1
		li	  $t2, 1
		bne	 $t1, $t2, end_for_c
		
		# Multiply i by 4 to calculate the offset for ptr address from the base address to access the element
		sll		$t3, $t0, 2
		# Address of the element that will be accessed
		add		$t3, $a0, $t3
		
		# Prep code to call singleton function
		addi	$sp, $sp, -12	# $sp = $sp + -12
		sw		$ra, 0($sp)		# store $ra into sp(0)
		sw		$a0, 4($sp)		# store the base address
		sw		$t0, 8($sp)		# store the ctr
		
		# Load arguement and call function
		lw		$a0, 0($t3)
		jal		singleton
        
        # Either prints star or the value
		beq		$v0, $0, print_null
        
		jal     get_singleton
        # Adding offset of 1
		addi	$a0, $v0, 1
        li		$v0, 1		# system call #1 - print int
		syscall				# execute
        
        load:
            # Post code for singleton function
            lw		$ra, 0($sp)		# restore $ra
            lw		$a0, 4($sp)		# restore $a0
            lw		$t0, 8($sp)		# restore the ctr
            addi	$sp, $sp, 12	# $sp = $sp + 12
            
		j incr_for_c
		
	incr_for_c:
		addi	$t0, $t0, 1
		j	   for_c
	end_for_c:
		li		$v0, 1
		j	   return_c
    print_null:
        jal print_star
        
        j load
	return_c:
		jr $ra


