# filename: outline_numbered.awk
#   author: Eric Pement
#     date: 2015-01-22 11:41:10 (GMT-0500)
#  version: 1.3
#
#  purpose: GNU awk script to modify files created and saved in GNU Emacs
#           "outline-mode" to a numbered, indented output format. E.g.,
#
#  SAMPLE INPUT      SAMPLE OUTPUT
#  ==============    ===========================
#  * Line 1        | 1. Line 1
#  ** Line 2       |   1.1. Line 2
#  *** Line 3      |     1.1.1. Line 3
#  *** Line 4      |     1.1.2. Line 4
#  **** Line 5     |       1.1.2.1. Line 5
#  ***** Line 6    |         1.1.2.1.1. Line 6
#  ***** Line 7    |         1.1.2.1.2. Line 7
#  ** Line 8       |   1.2. Line 8
#  * Line 9        | 2. Line 9
#  ** Line 10      |   2.1. Line 10
#
# USAGE:  awk [-v option=n ...] -f outline_numbered.awk
#
# OPTION VARIABLES:
#    indent n      - Control number of leading spaces used for indentation
#    period        - Set to 0 if input uses "*." or "**." instead of "*" or "**"
#    ignore_errors - Set to 1 to ignore errors like starting off with "**"
#
# DETAILS:
# "indent" controls the amount of increasing indentation. Default is 2 (indent
# by 2, 4, 6... spaces).. Set indent to 0 to put all numbers flush left. E.g.,
#         awk -v indent=0 -f outline_numbered.awk FILE
#
# "period" controls whether a trailing period (dot) will be added to to the
# output number. This was added because input file may look like:
#         *. Line 1
#         **. Line 2
#         ***. Line 3
#   In these cases, we do not want to print "1..", "1.1..", and "1.1.1..".
#   Set the variable to 0 to suppress the trailing dot so the output will look
#   like "1.", "1.1.", and "1.1.1.". E.g.,
#         awk -v period=0 -f outline_numbered.awk FILE
#
# "ignore_errors" can be set to 1. Default is 0 (i.e., halt if errors found in input)
#         awk -f ignore_errors=1 -v indent=0 outline_numbered.awk FILE
#
# Note: this script can handle any number of asterisks on a line. Lines of
# plain text (no asterisks) in source file are NOT indented.
BEGIN {
  if (ignore_errors == "") ignore_errors = 0   # if not defined, set it to 0
  if (period == "")        period = 1          # if not defined, set it to 1
  if (indent == "")        indent = 2          # if not defined, set it to 2
}

/^\*/ {

  this_len = match($0,/\*([^*]|$)/)   # get number of stars in 1st field
  array[this_len]++                   # increment index of current leaf

  # check for invalid outline levels
  if ( ( this_len - last_len > 1 ) && ignore_errors != 1  ) {

      print "DIAG: value of ignore errors is :", ignore_errors
      
      if (FILENAME == "-" ) {
	  myfile = "(piped from standard input)"
      }
      else {
	  myfile = FILENAME
      }

      if (last_len == "") {
	  last_len = "0"
      }

      if (last_len == 1) {
	  old_num_ast = "1 asterisk"
      }
      else {
	  old_num_ast = last_len " asterisks"
      }

      if (this_len == 1) {
	  new_num_ast = "1 asterisk"
      }
      else {
	  new_num_ast = this_len " asterisks"
      }
    
      error_message = "\a\a"			     \
"************************************************\n" \
"  WARNING! The input file has an invalid number \n" \
"  of asterisks on line " NR ", below.         \n\n" \
"  The previous outline level had " old_num_ast ",  \n" \
"  but the current/next level has " new_num_ast "!\n\n" \
"  One level of indentation was inadvertently    \n" \
"  skipped. Processing halted so you can fix the \n" \
"  input file, \x22"   myfile   "\x22.           \n" \
"************************************************\n" \
">>>\n" \
"Error on Line #" NR " :" ;

      print error_message, $0 > "/dev/stderr"
      exit 1
  }

  if ( this_len < last_len ) {    # if we have moved up a branch...
     for (i = this_len + 1; i <= last_len; i++)
        array[i] = 0;             # .. reset the leaves below us
  }

  for (j=1; j <= this_len; j++){  # build up the string. eg, 2. + 1.
     prefix = prefix array[j] "."
  }

  indent_level = (this_len - 1) * indent
  indentation  = sprintf("%+" indent_level "s", "")

  if ( period == 0 )
      sub(/\.$/, "", prefix)

  sub(/^\*+/, indentation prefix)
  last_len = this_len
  prefix = ""
}
1  # after making the modifications above, print every line
#---[ end ]---
