#########################################################
### Use this script to generate LaTeX code
###
### Author: Pedro T Freidinger (pedrotersetti3@gmail.com)
### License: MIT (github.com/pedroter7/useful_scripts)
#########################################################

import argparse
import sys
import re

def print_error(message, end="\n", flush=True):
    print("Error: {}".format(message), file=sys.stderr, end=end, flush=flush)

def create_parser():
    parser = argparse.ArgumentParser(description="Generate LaTeX code")
    parser.add_argument("--matrix", metavar="ROW", nargs="+", action="append", help="Generates a matrix with the given rows. Each input is a row in which the columns are space-separated. If not enough columns are provided for a row in the matrix, the needed columns are filled with zeros.")
    parser.add_argument("--zeros-matrix", metavar="MxN", help="Generates code for an mxn matrix filled with zeros.")
    parser.add_argument("--eye-matrix", metavar="N", type=int, help="Generates code for an eye matrix of order N.")
    parser.add_argument("--matrix-notation", default="[", help="Symbol to be used to draw the matrix. Default is [ which generates code for a square brackets delimited matrix. Allowed values are (, [, {, |, || or - (for no delimiter). Remember to ident or place these symbols within quotes to avoid shell interpretation.")
    parser.add_argument("--indent", action="store_const", default=False, const=True, help="If this flag is passed, the output is indented.")
    parser.add_argument("--out-file", metavar="FILEPATH", default=None, help="Write the generated code to a file.")
    return parser

def get_latex_matrix_type(symbol_string):
    if symbol_string == "-":
        return "matrix"
    elif symbol_string == "(":
        return "pmatrix"
    elif symbol_string == "[":
        return "bmatrix"
    elif symbol_string == "{":
        return "Bmatrix"
    elif symbol_string == "|":
        return "vmatrix"
    elif symbol_string == "||":
        return "Vmatrix"
    else:
        print_error("Unknown matrix notation, the default (brackets) will be used.")
        return "bmatrix"

def generate_matrix_code_indentend(matrix_type_string, matrix_rows):
    code = "\\begin{{{}}}\n".format(matrix_type_string)
    for row in matrix_rows:
        code += "  {} \\\\\n".format(" & ".join(row))
    code += "\end{{{}}}".format(matrix_type_string)
    return code

def generate_matrix_code_non_indented(matrix_type_string, matrix_rows):
    code = "\\begin{{{}}} ".format(matrix_type_string)
    for row in matrix_rows:
        code += " {} \\\\".format(" & ".join(row))
    code += " \end{{{}}}".format(matrix_type_string)
    return code

def fill_matrix_rows_with_zeros(matrix_rows, up_to=0):
    if up_to < 1:
        up_to = len(max(matrix_rows, key=len))
    for i in range(len(matrix_rows)):
        if len(matrix_rows[i]) < up_to:
            matrix_rows[i] += ['0' for i in range(up_to - len(matrix_rows[i]))]
    return matrix_rows

# ['1 2', '3 4 5 6', '1'] -> [[1, 2, 0, 0], [3, 4, 5, 6], [1, 0, 0, 0]]
def normalize_matrix_string_rows(matrix_rows):
    for i in range(len(matrix_rows)):
        matrix_rows[i] = matrix_rows[i].split()
    return fill_matrix_rows_with_zeros(matrix_rows)

def generate_matrix_code(args):
    latex_matrix_type = get_latex_matrix_type(args.matrix_notation)
    matrix_rows = normalize_matrix_string_rows(args.matrix[0])
    if args.indent:
        return generate_matrix_code_indentend(latex_matrix_type, matrix_rows)
    else:
        return generate_matrix_code_non_indented(latex_matrix_type, matrix_rows)

def get_zeros_matrix_dimensions_from_args(args):
    splitted = args.zeros_matrix.split("x")
    return int(splitted[0]), int(splitted[1])

def build_zeros_matrix_rows_array(lines_number, columns_number):
    matrix_rows = []
    for i in range(lines_number):
        row = ['0' for i in range(columns_number)]
        matrix_rows.append(row)
    return matrix_rows

def build_eye_matrix_rows_array(matrix_order):
    n = matrix_order
    matrix_rows = []
    for i in range(n):
        row = []
        for j in range(n):
            if i == j:
                row.append("1")
            else:
                row.append("0")
        matrix_rows.append(row)
    return matrix_rows

def generate_zeros_matrix_code(args):
    latex_matrix_type = get_latex_matrix_type(args.matrix_notation)
    m,n = get_zeros_matrix_dimensions_from_args(args)
    matrix_rows = build_zeros_matrix_rows_array(m, n)
    if args.indent:
        return generate_matrix_code_indentend(latex_matrix_type, matrix_rows)
    else:
        return generate_matrix_code_non_indented(latex_matrix_type, matrix_rows)

def generate_eye_matrix_code(args):
    latex_matrix_type = get_latex_matrix_type(args.matrix_notation)
    matrix_rows = build_eye_matrix_rows_array(args.eye_matrix)
    if args.indent:
        return generate_matrix_code_indentend(latex_matrix_type, matrix_rows)
    else:
        return generate_matrix_code_non_indented(latex_matrix_type, matrix_rows)

def write_code(code_string, out_file):
    if out_file is not None:
        with open(out_file, 'w') as of:
            of.write(code_string)
    else:
        print(code_string)

def get_code_generator_function_from_args(args):
    # Generate matrix
    if (args.matrix is not None) and (len(args.matrix) > 0):
        return generate_matrix_code
    # Generate zeros matrix
    if (args.zeros_matrix is not None) and bool(re.match(r"^[1-9]\d*x[1-9]\d*$", args.zeros_matrix)):
        return generate_zeros_matrix_code
    # Generate eye matrix
    if (args.eye_matrix is not None) and args.eye_matrix > 0:
        return generate_eye_matrix_code

    return None

def main():
    parser = create_parser()
    args = parser.parse_args()
    generate_code = get_code_generator_function_from_args(args)
    if generate_code is not None:
        generated_code = generate_code(args)
    else:
        parser.print_help()
        sys.exit(1)

    write_code(generated_code, args.out_file)

if __name__ == '__main__':
    main()