import os
import glob
import numpy as np

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_DIR = os.path.join(SCRIPT_DIR, "input_texture_data")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "output_ctf")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def generate_ctf_files(txt_filename, text_content, Phase, X, Y, Bands, Error, MAD, BC, BS):
    # Read the Euler angles from the txt file
    EA_data = np.genfromtxt(txt_filename, delimiter=" ")

    # Get the number of Euler angle sets (m)
    num_elements, total_columns = EA_data.shape
    # num_sets = total_columns // 3

    # # Directory to save CTF files
    # output_dir = os.path.splitext(txt_filename)[0]
    # if not os.path.exists(output_dir):
    #     os.makedirs(output_dir)
    #
    # # Iterate over each set of Euler angles
    # for i in range(num_sets):
        # Extract the i-th set of Euler angles
    # EA_set = EA_data[:, i * 3:(i + 1) * 3] % 360

    # Generate the CTF filename
    base_name = os.path.splitext(os.path.basename(txt_filename))[0]
    ctf_filename = os.path.join(OUTPUT_DIR, f"{base_name}_HCP.ctf")

    # Write the CTF file
    with open(ctf_filename, "w") as ebsdfile:
        ebsdfile.write(text_content)
        for elem in range(num_elements):
            ebsdfile.write(f'{Phase[elem]:.0f}\t{X[elem]:.4f}\t{Y[elem]:.4f}\t{Bands[elem]:0.0f}\t{Error[elem]:0.0f}\t')
            ebsdfile.write(f'{EA_data[elem, 0]:.4f}\t{EA_data[elem, 1]:.4f}\t{EA_data[elem, 2]:.4f}\t')
            ebsdfile.write(f'{MAD[elem]:.4f}\t{BC[elem]:0.0f}\t{BS[elem]:0.0f}\n')

# Define the text content
text_content = """Channel Text File
Prj relative_example.ctf
Author	taiju
JobMode	Grid
XCells	500
YCells	1000
XStep	10.0000
YStep	10.0000
AcqE1	0.0000
AcqE2	0.0000
AcqE3	0.0000
Euler angles refer to Sample Coordinate system (CS0)!	Mag	0.0000	Coverage	0	Device	0	KV	0.0000	TiltAngle	0.0000	TiltAxis	0	DetectorOrientationE1	0.0000	DetectorOrientationE2	0.0000	DetectorOrientationE3	0.0000	WorkingDistance	0.0000	InsertionDistance	0.0000	
Phases	2
2.900;2.900;2.900	90.000;90.000;90.000	Iron bcc (old)	11	0			Created from mtex
3.700;3.700;3.700	90.000;90.000;90.000	Iron fcc	11	0			Created from mtex
Phase	X	Y	Bands	Error	Euler1	Euler2	Euler3	MAD	BC	BS
"""
Nx = 5000
Ny = 10000

ele_size = 10
x = np.linspace(0, Nx-ele_size, np.round(Nx/ele_size).astype(int))  # If X is between 0 and Nx-1
y = np.linspace(0, Ny-ele_size, np.round(Ny/ele_size).astype(int))  # If Y is between 0 and Ny-1

X, Y = np.meshgrid(x, y)
X = X.flatten()
Y = Y.flatten()
Phase = np.ones(shape=(len(X))) * 2
Bands = np.random.randint(9, 13, size=len(X))
Error = np.zeros(shape=(len(X)))
MAD = np.random.rand(len(X))
BC = np.random.randint(35, 177, size=len(X))
BS = np.random.randint(34, 154, size=len(X))

input_files = glob.glob(os.path.join(INPUT_DIR, 'EG5by10mm*.txt'))
for txt_file in input_files:
    generate_ctf_files(txt_file, text_content, Phase, X, Y, Bands, Error, MAD, BC, BS)

