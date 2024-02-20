#!/usr/bin/env python

import argparse
import csv
from io import StringIO
import sys

def appendColumnsCore(inputFH, outputFH, newColumns, appendRowNr=None):
    """
    Appends new columns with constant values using file handles for input and output.
    If a column already exists, its values are updated. Otherwise, a new column is appended.

    :param input_fh: An input file handle (or file-like object).
    :param output_fh: An output file handle (or file-like object).
    :param new_columns: A list of tuples, where each tuple contains the column name and its constant value.
    """
    # Check the first line to see if the header is empty
    first_line = inputFH.readline().strip()
    inputFH.seek(0)  # Reset file handle to start
    if not first_line: # skip file / copy without changes if no header was found
        outputFH.writelines(inputFH.readlines())  # Copy the rest of the file
        return

    # prepare row number header
    if appendRowNr == True:
        appendRowNr = "rowNr"
    rowNrHeader = [str(appendRowNr)] if appendRowNr else []

    # Read header and append new column names
    reader = csv.DictReader(inputFH)
    fieldnames = reader.fieldnames + [colName for colName, _ in newColumns if colName not in reader.fieldnames] + rowNrHeader

    # open target and write new header
    writer = csv.DictWriter(outputFH, fieldnames=fieldnames)
    writer.writeheader()
    
    # Append new column values to each row
    rowNr = 0
    for row in reader:
        rowNr += 1
        for colName, colValue in newColumns:
            row[colName] = colValue
        if len(rowNrHeader)>=1:
            row[rowNrHeader[0]] = str(rowNr)
        writer.writerow(row)

def appendColumnsToCsvFile(filename, newColumns, appendRowNr=None):
    """
    Appends new columns to a CSV file specified by filename.

    :param file_name: The name of the CSV file to modify.
    :param new_columns: A list of tuples, where each tuple contains the column name and its constant value.
    """
    with open(filename, 'r', newline='') as inputFile, open(filename + '.tmp', 'w', newline='') as outputFile:
        appendColumnsCore(inputFile, outputFile, newColumns, appendRowNr=appendRowNr)
    
    # Replace original file with modified one
    import os
    os.replace(filename + '.tmp', filename)

def appendColumnsToCsvString(csvContent, newColumns, appendRowNr=None):
    """
    Appends new columns to CSV content provided as a string and returns the modified CSV as a string.

    :param csv_content: The CSV content as a string.
    :param new_columns: A list of tuples, where each tuple contains the column name and its constant value.
    :return: The modified CSV content as a string.
    
    Example:
    --------
    >>> csv_content = "Name,Age\\nJohn,30\\nJane,25"
    >>> new_columns = [('City', 'New York'), ('Status', 'Active')]
    >>> print(appendColumnsToCsvString(csv_content, new_columns)) # doctest: +NORMALIZE_WHITESPACE
    Name,Age,City,Status
    John,30,New York,Active
    Jane,25,New York,Active
    >>> print(appendColumnsToCsvString(csv_content, [])) # doctest: +NORMALIZE_WHITESPACE
    Name,Age
    John,30
    Jane,25
    >>> print(appendColumnsToCsvString(csv_content, new_columns, appendRowNr="RowNr")) # doctest: +NORMALIZE_WHITESPACE
    Name,Age,City,Status,RowNr
    John,30,New York,Active,1
    Jane,25,New York,Active,2
    >>> print(appendColumnsToCsvString(csv_content, [('Age', 0)], appendRowNr="RowNr")) # doctest: +NORMALIZE_WHITESPACE
    Name,Age,RowNr
    John,0,1
    Jane,0,2
    """
    
    inputFh = StringIO(csvContent)
    outputFh = StringIO()
    appendColumnsCore(inputFh, outputFh, newColumns, appendRowNr=appendRowNr)
    return outputFh.getvalue()

def main():
    # Initialize the argument parser
    parser = argparse.ArgumentParser(description='Append columns to a CSV file.')
    parser.add_argument('--test', action='store_true', help=argparse.SUPPRESS)
    parser.add_argument('-r', '--rowNumberHeader',  type=str, default="rowNumber", help='Column name for the row numbers (header at row 0, first data row at row 1)')
    parser.add_argument('filename', type=str, nargs='?', help='The CSV file to modify. Use --test for doctests.')
    parser.add_argument('columns', nargs='*', help='Column name/value pairs to append.')

    args = parser.parse_args()

    # Handle the --test argument to run doctests
    if args.test:
        import doctest
        doctest.testmod()
        return

    # Check if filename and columns were provided
    if not args.filename or len(args.columns) % 2 != 0:
        parser.print_help()
        sys.exit(1)
    
    # Pair up the 'columns' list into a list of tuples
    newColumns = [(args.columns[i], args.columns[i + 1]) for i in range(0, len(args.columns), 2)]

    # Call the function to append columns
    appendColumnsToCsvFile(args.filename, newColumns, args.rowNumberHeader)

if __name__ == "__main__":
    main()
