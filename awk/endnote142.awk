#  Emacs file variables: -*- mode:awk; indent-tabs-mode:nil; tab-width:4; -*-
#
# Filename: endnote.awk
#   Author: Eric Pement - eric.pement [=at=] gmail.com
#  Version: 1.42
#     Date: 2012-01-06 09:01:05
#  Purpose: To convert in-text notes and references to endnotes
#    Needs: GNU awk (gawk) or mawk (Michael Brennan's awk)
#
#  Usage: awk [-options] -f endnote.awk source.txt >output.txt
#
#  Options:
#    -v alt_np='str'     # use 'str' (literal) as an alternative note point string
#    -v ignore_errors=1  # do not check for mismatched numbering in endnotes
#    -v ssnotes=1        # omit blank line between notes (default: 1 blank line)
#    -v start=n          # start numbering at 'n' instead of 1
#
BEGIN {
    if ( start && start !~ /^[0-9]+$/ ) {
        print "\aError!\nVariable 'start' was set as " start ", but it",
            "must be an integer.\nQuitting here ...\n" > "/dev/stderr"
        exit 1
    }

    if ( alt_np == "" && alt_np != 0 ) {
        print "\aError!\nOption switch 'alt_np' was used, but it does not",
            "have a value assigned to it.\nThe syntax must be",
            "'-v alt_np=\"string\"', where \"string\" is interpreted as",
            "a string literal.\nQuitting here ...\n" > "/dev/stderr"
        exit 1
    }
    # else, alt_np was defined on the command line with a non-empty value

    # Use start to set an initial note number other than 1
    i_TextCount = i_RefCount = ( start ? start - 1 : 0 )

    # quote special chars in alternate note points; fewer chars than in perl
    gsub(/[.?*+([$\\]/, "\\&", alt_np)
}

# main body
{  b_BlankLine = $0 ~ /^[ \t]*$/ ? "Y" : "" }

# Within the note block
/^[ \t]*\[\[/, /]][ \t]*$/ {  # Range op "," also matches 1 line

    if ( /^[ \t]*\[\[/ ) i_LLcount++      # count [[ marker
    if ( /^[ \t]*\[\[[ \t]*$/ ) next      # skip lone [[ markers
    if ( /^(\.\.|\?\?|%)/ ) next          # skip comment lines
    sub(/^[ \t]*\[\[ ?/, "", $0)          # strip leading [[

    # Increment note block: (optional spaces), 1-4 pound signs, period
    # gensub would be easier here, since it supports backreferences, but I want this
    # to be compatible with mawk ...
    if ( match($0, /^[ \t]*#+\./) ) {
        sub(/^[ \t]*/, "_=SPLIT=_&")
        sub(/#+\./, ++i_RefCount ".", $0)
    }

    # Is the closing marker, ]], on this line?
    if ( sub(/[ \t]*]][ \t]*$/, "", $0) ) {
        i_RRcount++
        i_BlockEndLineNum = NR
        s_Refs = s_Refs $0 "\n"
    }
    else {
        s_Refs = s_Refs $0 "\n"     # store line in the accumulator
    }
    next
}

# Not in the note block ...
{
    if ( NR == (i_BlockEndLineNum + 1) && b_BlankLine && b_BlankBeforeBlock )
        next

    # match standard [##] markers
    while ( match($0, /\[#+]/) ) {
        sub(/\[#+]/, "[" ++i_TextCount "]", $0)    # increment [#]
    }

    # match alternate markers
    if ( alt_np ) {
        while ( match($0, alt_np) ) {
            sub(alt_np, ++i_TextCount, $0)
        }
    }

    # NB: Must be positioned _after_ the if(NR==...) block above
    b_BlankBeforeBlock = $0 ~ /^[ \t]*$/ ? "Y" : ""
    print $0
}

function printEndnotes(a_notes,      i_Counter) {

    i_Counter = 0
    if ( ssnotes ~ /^[1YyTt]$/ ) {     # single-spaced
        for (item in a_notes) {
            sub(/\n+$/, "", a_notes[item])
            i_Counter++
        }
    }
    else {                             # double-spaced
        for (item in a_notes) {
            sub(/\n+$/, "\n", a_notes[item])
            i_Counter++
        }
    }

    for (i=2; i <= i_Counter; i++) {   # because the 1st note is always blank
        print a_notes[i]
    }

}

END {

    if ( i_TextCount == i_RefCount || ignore_errors ) {   # note points/bodies match

        # Convert to array to handle single- or double-spacing on output
        if (s_Refs) {
            split(s_Refs, notes, /_=SPLIT=_/)
        }

        # print ENDNOTES header only if notes exist
        if ( i_RefCount ) {
            print "\n---------\nENDNOTES:\n";
            printEndnotes(notes);
            print "[end of file]";
        }

        if ( i_LLcount != i_RRcount && ignore_errors != 1 ) {
            print "================"
            print "    WARNING     "
            print "================"
            print "There were",$i_LLcount,"Left Note Block Markers and",$i_RRcount,"Right note block markers."
            print "Examine your output carefully, because there may be a formatting error."
            print "=======================================================================\n"
        }
    }
    else {       # note points and note bodies do NOT match
        i_body = i_TextCount - start;
        i_refs = i_RefCount - start;

        print "\a\a\n\n"
        print "================"
        print "  FATAL ERROR!  "
        print "================"
        print "Note points in the body and References at the end do not match!"
        print "There are",$i_body,"Note points in the body text and",$i_refs,"References"
        print "for those",$i_body,"notes. The Endnote section will not be printed."
        print "Quitting here ..."
    }
}
#---end of script---
