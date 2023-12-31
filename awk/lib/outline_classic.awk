# filename: outline_classic.awk
#   author: Eric Pement
#     date: 22 March 2001, 2023-11-01
#  version: 1.1
#
#  purpose: GNU awk script to modify files created and saved in GNU Emacs
#           "outline-mode" into classic indented, outline format. E.g.,
#
#  INPUT FILE        OUTPUT FILE
#  ==============    ===================
#  * Line 1        | A. Line 1
#  ** Line 2       |   1. Line 2
#  *** Line 3      |     a. Line 3
#  *** Line 4      |     b. Line 4
#  **** Line 5     |       (1) Line 5
#  ***** Line 6    |         (a) Line 6
#  ***** Line 7    |         (b) Line 7
#  ** Line 8       |   2. Line 8
#  * Line 9        | B. Line 9
#  ** Line 10      |   1. Line 10
#
# USAGE: awk [-v num=n] -f outline_classic.awk [file]
#
# OPTION: variable "num" determines amount of increasing indentation.
# Default is 2 (indent by 2, 4, 6, 8... spaces), but this controlled by
# the -v switch from the command line. E.g.,
#
#       awk -v num=4 -f outline_classic11.awk yourfile.txt
#
# Note: this script expects a maximum of five asterisks (*) on a line.
# Lines of plain text (no asterisks) in source file are NOT indented.
BEGIN {
  if (num == "") num = 2            # if num is not defined, set it to 2
  split("ABCDEFGHIJKLMNOPQRSTUVWXYZ",Lev1,"")
  split("abcdefghijklmnopqrstuvwxyz",Lev3,"")
  split("abcdefghijklmnopqrstuvwxyz",Lev5,"")
}

/^\*/ {

  this_len = match($0,/\*([^*]|$)/);  # get number of stars in 1st field
  array[this_len]++;                  # increment index of current leaf

  if ( this_len - last_len > 1 ) {    # check for invalid outline levels
    if (FILENAME == "-" ) myfile = "(piped from standard input)"
    else                  myfile = FILENAME

    error_message = "\a\a" \
"************************************************\n" \
"  WARNING! The input file has an invalid number \n" \
"  of asterisks on line " NR ", below.         \n\n" \
"  The previous outline level had " last_len " asterisks,  \n" \
"  but the current/next level has " this_len " asterisks!\n\n" \
"  You have inadvertently skipped one level of   \n" \
"  indentation. Processing halted so you can fix \n" \
"  the input file, \x22"   myfile   "\x22.       \n" \
"************************************************\n" \
">>>\n" \
"Error on Line #" NR " :" ;

    print error_message, $0 > "/dev/stderr" ;
    exit 1;
  }

  if ( this_len < last_len ) {    # if we have moved up a branch...
     for (i = this_len + 1; i <= last_len; i++)
        array[i] = 0;             # .. reset the leaves below us
  }

  for (j=1; j <= this_len; j++){  # build up the prefix string
     if      (j == 1)   prefix = Lev1[array[j]] "."
     else if (j == 2)   prefix = array[j] "."
     else if (j == 3)   prefix = Lev3[array[j]] "."
     else if (j == 4)   prefix = "(" array[j] ")"
     else if (j == 5)   prefix = "(" Lev5[array[j]] ")"
  }

  indent_level = (this_len - 1) * num ;
  indentation  = sprintf("%+" indent_level "s", "") ;

  sub(/^\*+/, indentation prefix) ;
  last_len = this_len ;
  prefix = "" ;
}
{ print }
# --- end of script ---
