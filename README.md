# x86-64 Assembly Calculator

A floating-point calculator written in x86-64 assembly for macOS.

## Features
- Basic arithmetic operations (+, -, *, /)
- Floating-point calculations with 2 decimal places
- Error handling for division by zero
- Input validation for numbers 1-99

## How to Build and Run
```bash
nasm -f macho64 calc.asm -o calc.o
gcc calc.o -o calc
./calc# x86-assembly-calculator
