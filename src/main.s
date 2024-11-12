.equ    STDIN,          0
.equ    STDOUT,         1
.equ    SYS_READ,       63
.equ    SYS_WRITE,      64
.equ    SYS_EXIT,       93
.equ    BUFFER_SIZE,    12                  # int + newline + null character

.section .rodata
n_label:    .asciz  "n: "
sum_label:  .asciz  "\t\tSum: "
end:        .asciz  "\n"

.data
buffer:     .space  BUFFER_SIZE

.text
.global main

main:
    la      a0, n_label                     # a0: prompt for n
    jal     inputInt                        # a0: value of n
    blt     a0, zero, exit                  # Exit on negative value of n.
    jal     sumSeries                       # Add the series up to n (a0).
    jal     printInt                        # Print the sum (a0).

# int sumSeries : Return sum of integers between 1 and n (inclusive)
# a0 <int value> : the integer
sumSeries:
    li      t0, 1                           # t0: 1
    beqz    a0, sumSeriesExit               # Base case: n = 0
    beq     a0, t0, sumSeriesExit           # Base case: n = 1

    addi    sp, sp, -8                      # Prepare stack for 2 registers.
    sw      ra, 4(sp)                       # Place the return address last.
    sw      a0, 0(sp)                       # Place the value of n first.

    addi    a0, a0, -1                      # a0: n - 1
    jal     sumSeries                       # a0: value of sumSeries(n - 1)

    lw      ra, 4(sp)                       # Restore previous return address.
    lw      t0, 0(sp)                       # Restore given value of n.
    add    a0, t0, a0                       # Add n + sumSeries(n - 1)

    sumSeriesExit:
        ret

# int printInt : Print given integer as a string
# a0 <int value> : the integer
printInt:
    mv      s1, ra                          # s1: saved return address
    la      t0, buffer                      # t0: buffer pointer
    addi    t0, t0, BUFFER_SIZE             # Move buffer pointer to very end.
    addi    t0, t0, -1                      # Point to last byte on buffer.
    sb      zero, 0(t0)                     # Place a null character.
    li      t1, 10                          # t1: decimal place multiplier

    li      t4, 0                           # t4: negation flag ('-' -> true)
    bge     a0, zero, printIntLoop          # Only negate if flagged.
    li      t4, '-'                         # t4: negative sign
    sub     a0, zero, a0                    # a0: absolute value of integer

    printIntLoop:
        # It's a good thing the user input is perfect, just saying.
        addi    t0, t0, -1                  # Fill buffer backwards.
        rem     t2, a0, t1                  # t2: last digit value
        addi    t2, t2, 48                  # t2: last digit representation
        sb      t2, 0(t0)                   # Place the digit representation.
        div     a0, a0, t1                  # One less power of ten to go.
        bnez    a0, printIntLoop            # Loop if anything is left.
    printIntNegate:
        beqz    t4, printIntWrite           # Only negate if flagged.
        addi    t0, t0, -1                  # Prepare to prepend.
        sb      t4, 0(t0)                   # Prepend a negative sign.
    printIntWrite:
        mv      a0, t0                      # a0: offset buffer address
        jal     print
    printIntExit:
        mv      ra, s1                      # ra: restored return address
        ret

# int inputInt : Prompt user for an integer
# a0 <string *prompt> : the prompt address
inputInt:
    mv      s1, ra                          # s1: saved return address
    jal     print                           # Print the prompt.
    jal     readInt                         # Read the (integer) input.
    mv      ra, s1                          # ra: restored return address
    ret

# int readInt : Read integer from user input
readInt:
    li      a7, SYS_READ                    # a7: system call
    li      a0, STDIN                       # a0: file descriptor
    la      a1, buffer                      # a1: buffer address
    li      a2, BUFFER_SIZE                 # a2: buffer size
    ecall

    li      a0, 0                           # a0 (return)
    la      t0, buffer                      # t0: buffer address
    li      t1, '\n'                        # t1: newline character
    li      t2, 10                          # t2: decimal place multiplier

    lb      t3, 0(t0)                       # t3: current character code
    li      t4, '-'                         # t4: negative sign
    bne     t3, t4, readIntLoop             # Don't flag if not negative.
    li      t4, 0                           # t4: negation flag (0 -> true)
    addi    t0, t0, 1                       # Move on to the digits.

    readIntLoop:
        lb      t3, 0(t0)                   # t3: current character code
        beq     t3, t1, readIntNegate       # Stop at newlines.
        beqz    t3, readIntNegate           # Stop at null characters.
        addi    t3, t3, -48                 # t3: current digit
        mul     a0, a0, t2                  # Update place values.
        add     a0, a0, t3                  # a0 (return): entered integer
        addi    t0, t0, 1                   # Move to next character.
        j       readIntLoop                 # Continue loop.
    readIntNegate:
        bnez    t4, readIntExit             # Only negate if flagged.
        sub     a0, zero, a0                # Negate the calculated integer.
    readIntExit:
        ret

# int print : Print the given string
# a0 <string *value> : the string address
print:
    mv      s0, ra                          # s0: saved return address

    mv      a1, a0                          # a1: string address
    jal     measureString
    mv      a2, a0                          # a2: length of string

    li      a7, SYS_WRITE                   # a7: system call
    li      a0, STDOUT                      # a0: file descriptor

    ecall

    mv      ra, s0                          # ra: restored return address
    ret

# int measureString : Get length of given string
# a0 <string *value> : the string address
measureString:
    li      t0, 0                           # t0: counter
    measureStringLoop:
        lb      t1, 0(a0)                   # t1: current character
        beqz    t1, measureStringExit       # Stop counting at null character.
        addi    t0, t0, 1                   # Increment counter.
        addi    a0, a0, 1                   # Move to next character.
        j       measureStringLoop           # Continue loop.
    measureStringExit:
        mv      a0, t0                      # a0 (return): length of string
        ret

exit:
    li      a0, 0                           # a0: exit code
    li      a7, SYS_EXIT                    # a7: system call
    ecall
