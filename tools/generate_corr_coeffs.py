import csv
import math

prea_coeffs_output_file  = "../source/detect_preamble/correlator_coeffs.txt"
prea_lengths_output_file = "../source/detect_preamble/correlator_lengths.txt"
prea_scaling_output_file = "../source/detect_preamble/correlator_scaling.txt"

bits_coeffs_output_file  = "../source/detect_bits/correlator_coeffs.txt"
bits_lengths_output_file = "../source/detect_bits/correlator_lengths.txt"

SAMP_PER_SYMB    = 10
FREQ_DEV         = 0.22
SPACING          = 4
SCALING_BITS     = 10

def compute_prea_coeff(n):
    print(n)
    preamble = "110100100011"
    coeff = ""
    for i in range(12):
        add_one = n%12//2
        add_two = n%12-add_one
        for j in range(n//12):
            coeff += preamble[i]
        if i < add_one:
            coeff += preamble[i]
        if i > 5 and i < 6 + add_two:
            coeff += preamble[i]
    return coeff

def compute_bits_coeff(n):
    coeff = ""
    for i in range(n):
        if i < n//2:
            coeff += "1"
        else:
            coeff += "0"
    return coeff

def float_to_bin(n, bits = 10):
    int_lsb = str(int(n) % 2)  # Extract integer part
    frac_part = n - int(n)     # Extract fractional part

    frac_bin = []
    for _ in range(bits-1):
        frac_part *= 2
        bit = int(frac_part)
        frac_bin.append(str(bit))
        frac_part -= bit

    return int_lsb + "_" + ''.join(frac_bin)  # Return LSB + fixed-length binary fraction

nom_regs = SAMP_PER_SYMB*6
max_regs = (nom_regs/(1-FREQ_DEV))
min_regs = (nom_regs/(1+FREQ_DEV))

bits_coefficients = []
bits_lengths = []

prea_coefficients = []
prea_lengths = []
prea_scaling = []

# Generate nominal coefficients
prea_coefficients.append(compute_prea_coeff(nom_regs))
bits_coefficients.append(compute_bits_coeff(SAMP_PER_SYMB))

# Generate coefficients up to max_reg
n = nom_regs
while n < max_regs:
    n += SPACING
    prea_coefficients.append(compute_prea_coeff(n))
    bits_coefficients.append(compute_bits_coeff(round(n/6)))

# Generate coefficients up to min_reg
n = nom_regs
while n > min_regs:
    n -= SPACING
    prea_coefficients.insert(0,compute_prea_coeff(n))
    bits_coefficients.insert(0,compute_bits_coeff(round(n/6)))


max_prea_length = len(prea_coefficients[-1])
max_bits_length = len(bits_coefficients[-1])

prea_lengths_bits = math.ceil(math.log2(max_prea_length))
prea_scaling_bits = SCALING_BITS
for coeff in prea_coefficients:
    prea_lengths.append(format(len(coeff), f'0{prea_lengths_bits}b'))
    prea_scaling.append(float_to_bin(max_prea_length/len(coeff), bits = prea_scaling_bits))

bits_lengths_bits = math.ceil(math.log2(max_bits_length))
for coeff in bits_coefficients:
    bits_lengths.append(format(len(coeff), f'0{bits_lengths_bits}b'))

print("BANKS: "+ str(len(prea_coefficients)))
print("PREAMBLE MAX LENGTH: " + str(max_prea_length))
print("SYMBOLS MAX LENGTH: " + str(max_bits_length))
print("SCALING BITS: " + str(SCALING_BITS))

print(prea_coefficients)
print(prea_lengths)
print(prea_scaling)

print(bits_coefficients)
print(bits_lengths)

with open(prea_coeffs_output_file, 'w') as f:
    for coeff in prea_coefficients:
        f.write(coeff + '\n')

with open(prea_lengths_output_file, 'w') as f:
    for length in prea_lengths:
        f.write(length + '\n')

with open(prea_scaling_output_file, 'w') as f:
    for scaling in prea_scaling:
        f.write(scaling + '\n')

with open(bits_coeffs_output_file, 'w') as f:
    for coeff in bits_coefficients:
        f.write(coeff + '\n')

with open(bits_lengths_output_file, 'w') as f:
    for length in bits_lengths:
        f.write(length + '\n')
