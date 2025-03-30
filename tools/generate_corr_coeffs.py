import csv

output_file = "../source/correlatorsine_lookup.txt"  # Output sine file name

def compute_coeff(n):
    print(n)
    preamble = "110100100011"
    coeff = ""
    for i in range(12):
        for j in range(n//12):
            coeff += preamble[i]
        if i < n%12:
            coeff += preamble[i]
    return coeff


SAMP_PER_SYMB    = 8
FREQ_DEV         = 0.22
SPACING          = 2

nom_regs = SAMP_PER_SYMB*6
max_regs = nom_regs/(1-FREQ_DEV)
min_regs = nom_regs/(1+FREQ_DEV)

coefficients = []
lengths = []

# Generate nominal coefficients
coefficients.append(compute_coeff(nom_regs))
# Generate coefficients up to max_reg
n = nom_regs
while n < max_regs:
    n += SPACING
    coefficients.append(compute_coeff(n))
max_regs = len(coefficients[-1])
# Generate coefficients up to min_reg
n = nom_regs
while n > min_regs:
    n -= SPACING
    coefficients.insert(0,compute_coeff(n))
min_regs = len(coefficients[0])

print(coefficients)
print(nom_regs)
print(max_regs)
print(min_regs)

with open(sine_table_file, mode='w') as sine_table:
    for t in range(LOOKUP_LENGTH):
        sine_value_num = round(math.sin((t+0.5)/LOOKUP_LENGTH/2*math.pi)*2**(DATA_WIDTH-1))
        sine_value_str = format(int(sine_value_num), "024b")
        sine_table.write(sine_value_str + "\n")


# print("Generating step sizes...")
# with open(midi_table_file, mode='r') as midi_table, open(step_table_file, 'w', ) as step_table:
#     reader = csv.reader(midi_table)
#     for row in reader:
#         frequency = float(row[1])
#         step_size_num = 4 * LOOKUP_LENGTH / SAMPLE_FREQUENCY * frequency    # Calculate step size number for each freq
#         step_size_str = format(int(step_size_num*(2**CNTR_WIDTH)), "016b")  # Convert to binary string
#         step_table.write(step_size_str + "\n")
#         #print(step_size_num)

# print("Generating sine values...")
# with open(sine_table_file, mode='w') as sine_table:
#     for t in range(LOOKUP_LENGTH):
#         sine_value_num = round(math.sin((t+0.5)/LOOKUP_LENGTH/2*math.pi)*2**(DATA_WIDTH-1))
#         sine_value_str = format(int(sine_value_num), "024b")
#         sine_table.write(sine_value_str + "\n")
#         #print(sine_value_num)