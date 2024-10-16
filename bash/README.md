# scripts for bash

## exp
 A high-precision command-line calculator (requires bc)

 Contains embedded help by using the "--help" switch.

## list_each_field

 Given 1 or more lines of delimited input (e.g., CSV file), put each field
  on a separate line and prefix the line with the correct field number.
  - Fields containing only spaces or tabs are treated as empty fields.
  - This tool does not handle embedded or quoted delimiters. To do that, use
  GNU awk with --csv or perl with Text::CSV

```
Usage:  list_each_field [-v options] [delimited_data]

Options:  -v delim='x'      # use 'x' for delimiter instead of comma
          -v hideEmpty=1    # do not show empty fields or blank lines
          -v numberLines=1  # include line numbers with output
          -v startWith=0    # number fields beginning with 0 instead of 1

  Use "\t", "\f", "\v", "\a" for TAB (^I), FF (^L), VT (^K), BEL (^G)

Example:
  $ echo aXb | tr "X" "\t" | list_each_field -v delim="\t"
  [0001]: <a>
  [0002]: <b>

  $ echo 'foo,  bar, ,,ham and eggs   , ,  ' | list_each_field
  [0001]: <foo>
  [0002]: <  bar>
  [0003]: [empty]
  [0004]: [empty]
  [0005]: <ham and eggs   >
  [0006]: [empty]
  [0007]: [empty]

  $ echo 'foo,  bar, ,,ham and eggs   , ,  ' | list_each_field -v hideEmpty=1 -v startWith=0
  [0000]: <foo>
  [0001]: <  bar>
  [0004]: <ham and eggs   >
```

# multi-column-match

multi-column-match v1.5 - A tool to find duplicate or unique records

  Given input data with 2 or more columns (fields), where the columns are
  already sorted, pass a list of fields that should form a unique key. The
  list passed via -f does not have to be in the same sort-order sequence,
  but it must contain the same field numbers. Field numbers begin with 1.

  By default, multi-column-match returns only lines with duplicate entries
  for each key, prefixed by a count of the duplicates for the key. This
  example located 2 records with the same key (of 3 fields):

      2 records:                  # Here, the key was -f "1,2,4"
      LN   white  dove    AM
      LN   white  flag    AM

  Input may come from a file on the command line or from standard input.

```
Usage:  multi-column-match -f "field,list" [-options] [input_file]

REQUIRED:
  -f "4,3,7,..."  Comma-separated list of field numbers, in any order

Options:
  -a        Show all lines, not just blocks of duplicates
  -b        Include blank lines (if any) from the input stream
  -F "sep"  Field separator (default: 1 or more spaces or tabs)
  -h        Show basic help
  -H        Show basic help plus Option Notes
  -l        Use last line of a duplicate set, plus all unique lines
  -n        No numbers for duplicate sets; wrap sets in "((" and "))"
  -t        Use top/first line of duplicates, plus all unique lines
  -u        Show unique, non-duplicated records only
  -v        Verbose output, add summary at end
  -z        Begin field numbers with zero (0), not one (1)
```

# nonasc
Bash script to look for different kinds of "non-ASCII" characters in an input file. 

```
nonasc v2.1b -
  Look for non-printable chars in input. Valid chars are regex[ -~] (0x20-0x7E),
  TAB, CR, and LF. Control codes or graphic chars are considered "non-ASCII".
  Input files are not changed. Exit code 0 if pure ASCII or nonzero otherwise.

Usage: nonasc [-switches] [file1 file2* ...]
  Multiple files are allowed. If filename is omitted, read from standard input.
  If no switches are used, look for non-printing chars and display the first 2
  lines of non-printing chars, if any. Hits are shown as yellow-on-red.

Switches:
   -d   Dump the ENTIRE input file in both hex and ASCII to the screen
        WITHOUT CHECKING FOR INVALID CHARS. Works on pure binary files.
        Long files should be piped through a file pager (e.g., "less").
        Use the -x switch to limit the output to NN lines.
        -d is not compatible with -r or -t; if both are used, -d prevails.

   -r   Include CR  (Ctrl-M, \015, \d13, 0x0D) as invalid char.
   -t   Include TAB (Ctrl-I, \011, \d09, 0x09) as invalid char.
   -z   Allow Ctrl-Z (0x0A), but only at EOF.

 -x NN  Print a maximum of NN lines of output for each file.
        If -d is used, display the first NN lines of hex/ASCII output.
        If -d is omitted, display a max of NN lines of invalid input.

 -h, -?, --help    Display this help message
```

# paragrep

perl script to search within paragraphs, and print the entire paragraph if the search expression is found within it. Written in bash, but calls perl to do the heavy lifting.


