# filename: defined_vars.awk
#     date: 2013-05-17
#
# This script shows how to test whether the user tried to pass a variable
# to awk on the command line as:
#
#    awk -v var="$something"      # UNIX syntax
#    awk -v var="%something%"     # Windows/CMD syntax
#
# We want to halt the script if the variable was empty (blank), which
# might occur if the variable was undefined or if its name was misspelled.
# We want to continue the script if the variable was defined (not blank).
#
#    awk -v var      # is not a scriptable case, because both GNU awk
#                    # and mawk (Mike Brennan's awk) will abort with a
#                    # syntax error message if this occurs.
#
# In the test case below, it is okay for the variable to not be used at
# all, but if an attempt was made to define the variable "var", its value
# cannot be empty.
#
BEGIN {
  if ( var==0 && var=="" )
    print "INFO : 'var' was not used on the command line. This is okay."
  else if ( var=="" )
    print "ERROR: 'var' was used on the command line, but it cannot be blank."
  else
    print "INFO : 'var' was passed on the cmd line with a value of (" var ")."
}
