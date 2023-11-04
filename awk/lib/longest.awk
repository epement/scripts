# filename: longest.awk
#   author: Eric Pement
#     date: 2015-05-18 11:09:16 (GMT-0400)
# requires: GNU awk, due to ARGIND variable and nextfile command.
#
#  purpose: locate and display the longest line in a file or standard input
#
# Revision history:
# -----------------
# 2003-03-12: Added an EOL marker (Ctrl-Q, which looks like "<" on Windows).
# 2003-06-03: Option to suppress display of the longest line.
# 2005-08-29: Option to show TAB as a graphics character. Show filename on the
#   summary line, show CR as a paragraph symbol. Try to skip nontext files.
# 2007-10-11: Option to suppress display of the stats and omit the EOL marker.
# 2012-08-20: Detect active OS and choose appropriate symbol for TAB,EOL,CR.
# 2014-02-13: Added uname/getline and changed symbols used for TAB,EOL,CR.
# 2015-05-18: Added ANSI colors for Unix terminal
#
# Usage:
#    gawk -f longest.awk [-v varname=value] [file1 file2 file3 ...]
#
# Optional variable names and values:
#    stats_only=1   Only show statistics, suppress line display
#    line_only=1    Only show the line, suppress statistics
#    show_tabs=1    Display tabs as symbol (o.s. dependent)
#
# NOTE:
#   On a Cygwin system, gawk.exe is apparently stripping the CR preceding
#   LF and not passing it to awk, maybe trying to be nice to Windows files.
#
BEGIN {
    # Define some symbols, depending on the OS. Unix/Cygwin preferred
    "uname" | getline uname_output
    close("uname")

    # ANSI escape codes. Sequence is:  ESC [ {attribute}; {text-color}; {bkgd-color} m
    # Attributes: 00=none  01=bold 04=underscore 05=blink 07=reverse 08=concealed 
    # Text color: 30=black 31=red  32=green 33=yellow 34=blue 35=magenta 36=cyan 37=white
    # Bkgd color: 40=black 41=red  42=green 43=yellow 44=blue 45=magenta 46=cyan 47=white
    if ( uname_output ) {
	TAB = "\033[35;43m\\t\033[0m"
	 CR = "\033[35;43m\\r\033[0m"    # octal \033 = ESC
	EOL = "\033[35;43m<<\033[0m"     # magenta on yellow
    }
    else if ( ENVIRON["OS"] ~ /Windows_NT/ ) {
	TAB = "\004"   # octal 04 = 0x04 = dec 04 = diamond symbol in Windows
	 CR = "\024"   # octal 24 = 0x14 = dec 20 = paragraph symbol in Windows
        EOL = "\021"   # octal 21 = 0x11 = dec 17 = left-pointing triangle in Win
    }
    else {
	TAB = "{TAB}"
	 CR = "{CR}"
	EOL = "{<<}"
    }

    # Routine to silently skip over unreadable files. Copied from
    # Effective Awk Programming, "Checking for Readable Data Files"
    for (i = 1; i < ARGC; i++) {
        if (ARGV[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=.*/ || ARGV[i] == "-")
            continue # assignment or standard input
        else if ((getline junk < ARGV[i]) < 0) # unreadable
            delete ARGV[i]
        else
            close(ARGV[i]);
    }
}

# Only if FILENAME was passed on the cmd line, execute this block:

FILENAME {
    # Skip certain binary files. This will still miss some cases.
    myfile = tolower(FILENAME)
    if (myfile ~ /\.(com|exe|dll|zip|msi|sfx|7z|gz|wav|mp3|swf|pdf|hlp|chm|gif|jpg|bmp|ico|psd|png)$/) {
        print "Skipping " myfile " because it is not a text file ..."
        nextfile
    }
}

length($0) > m2 {
    m1 = $0             # save the longest line
    m2 = length($0)     # save the length
    m3 = FILENAME       # save the name of the file with the longest line
    m4 = NR             # save the line number
}

END {  # After all input has been read ...

    sub(/^-$/, "STDIN", m3)   # show source as STDIN if used

    # line_only and stats_only are mutually exclusive. If line_only is
    # defined and stats_only is undefined, suppress this block. But if
    # both are present, display the block.
    #
    # In other words, display the block if: (1) both are defined,
    # (2) neither is defined, or (3) stats_only is defined and
    # line_only is undefined.
    if ( line_only && !stats_only ) {
        # do nothing
    }
    else {

        if (ARGIND > 1)
            print "Total of " ARGIND " files examined.";

        print "Total lines:", NR "."
        print "Line #" m4, "of", m3, "has", m2, "characters."

    }

    gsub(/\x0D/, CR, m1)             # Display special CR marker to all

    if ( show_tabs )
        gsub(/\t/, TAB, m1)          # If show_tabs is set, display TAB marker

    if (!line_only && !stats_only)   # If neither option is set, show the ruler
        print "1---5---10----5---20----5---30----5---40----5---50----5---60----5---70---75";

    if (line_only && !stats_only)
        print m1                     # If "line_only", do not add the EOL marker
    else if (!line_only && !stats_only)
        print m1 EOL                 # else, add the EOL marker

}
#--- end of script ---
