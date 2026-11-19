# Python matrix input for Vivado simulation
# Matrix A
A = [
    [ 1,   2 ,  3 ,  4  ],
    [ 5,   6 ,  7 ,  8  ],
    [ 9,   10,  11,  12 ],
    [ 13,  14,  15,  16 ]
]

# Matrix B
B = [
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1]
]


def validate(matrix):
    assert len(matrix) == 4
    assert all(len(row) == 4 for row in matrix)

    for row in matrix:
        for value in row:
            assert isinstance(value, int)
            assert -128 <= value <= 127


def pack_matrix(matrix):
    packed = 0

    for row in range(4):
        for col in range(4):
            index = row * 4 + col
            value = matrix[row][col] & 0xFF
            packed |= value << (8 * index)
    return packed


# Validate matrices
validate(A)
validate(B)

# Pack matrices
packed_a = pack_matrix(A)
packed_b = pack_matrix(B)

# Print hexadecimal outputs directly to terminal
print(f"{packed_a:032X}")
print(f"{packed_b:032X}")
