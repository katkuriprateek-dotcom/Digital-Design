import serial
import time

# Change COM port according to your computer
PORT = "COM3"
BAUD = 9600

# Matrix A
A = [
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12],
    [13, 14, 15, 16]
]

# Matrix B
B = [
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12],
    [13, 14, 15, 16]
]

def validate(matrix):
    assert len(matrix) == 4
    assert all(len(row) == 4 for row in matrix)

    for row in matrix:
        for value in row:
            assert -128 <= value <= 127

validate(A)
validate(B)

# Convert signed values to 8-bit two's complement
data = []

for matrix in (A, B):
    for row in matrix:
        for value in row:
            data.append(value & 0xFF)

assert len(data) == 32

with serial.Serial(PORT, BAUD, timeout=2) as ser:

    time.sleep(0.2)

    ser.write(bytes(data))
    ser.flush()

    print("Matrix A and B transmitted.")
    print("Total bytes:", len(data))
