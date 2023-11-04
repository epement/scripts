# filename: 2line.awk
#   author: Eric Pement
#     date: 2011-11-18, 2012-04-03
#
#  purpose:
#    Print lines from input file/stream only if REGEX1 and REGEX2 appear
#    on TWO CONSECUTIVE lines. If REGEX1 and REGEX2 match multiple
#    contiguous lines, do not print any line twice.  Each line will be
#    prefixed with a line number. It is okay for REGEX1 and REGEX2 to
#    be the same pattern or string.
#
#  options:
#    -v TWICE=1        Print same line twice if REGEX2 also matches REGEX1
#    -v IGNORECASE=1   Case-insensitive matching
#    -v NO_NUMS=1      Omit line numbers from output
#
# note:
#    This script avoids slurping the entire file into a buffer.
#
BEGIN {
    if ( REGEX1 == "" || REGEX2 == "" ) {
        print "ERROR! Search patterns REGEX1 and REGEX2 cannot be blank." 
        print "Usage:"
        print "    awk -v REGEX1=pattern1 -v REGEX2=pattern2 -f 2line.awk [file1 ...]"
        print "\nQuitting here ..."
        skip = 1
        exit
    }
    i_counter = 0
}

$0 ~ REGEX2 {

    if ( i_lastMatch && i_lastMatch + 1 == NR ) {  # i_lastMatch must be nonzero
    
        # print the buffer
        if ( TWICE )
            print s_lastMatch
        else if ( !(i_lastMatch in a_Printed) )
            print s_lastMatch
            
            
        if ( !(NR in a_Printed) ) {
            if ( NO_NUMS )
                printf("%s\n", $0)
            else
                printf("Line#% 3i: %s\n", NR, $0)
        }
            
        i_counter++                     # count the matches
        print "(" i_counter ")---\n"    # cosmetic separator
        
        a_Printed[i_lastMatch]++        # track if this line has been printed
        a_Printed[NR]++                 # same array, only using current line

        if ( $0 ~ REGEX1 ) {            # does this line also match REGEX1? 
            i_lastMatch = NR
            s_lastMatch = NO_NUMS ? sprintf("%s", $0) : sprintf("Line#% 3i: %s", NR, $0) 
        }
        next
    }
}

$0 ~ REGEX1 {
    i_lastMatch = NR
    s_lastMatch = NO_NUMS ? sprintf("%s", $0) : sprintf("Line#% 3i: %s", NR, $0)
}

END {

    match_pl = i_counter == 1 ? "match" : "matches"
    if (skip != 1)
        printf( "      %i %s found.\n", i_counter, match_pl)
		}
#------[ end of file ]------
