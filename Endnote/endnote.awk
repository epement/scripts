#!/usr/bin/awk -f
#  Emacs file variables: -*- mode:awk; indent-tabs-mode:nil; tab-width:4; -*-
#
# Filename: endnote.awk
#   Author: Eric Pement
#  Version: 1.45
#     Date: 2026-01-10 01:40:31 (UTC-0500)
# Copyleft: Free software under the terms of the GNU GPLv3
#  Purpose: To convert in-text notes and references to endnotes
#    Needs: any modern awk (gawk, mawk, BWK awk)
#
#  Usage:
#     endnote [-options] source.txt [>output.txt]          # Unix shell
#     awk -f endnote [-options] source.txt [>output.txt]   # Windows/CMD shell
#
#  Options:
#    -v alt_nm='str'     # use 'str' (literal) as an alternate note marker
#    -v ignore_errors=1  # do not check for mismatched numbering in endnotes
#    -v ssnotes=1        # omit blank line between notes (default: 1 blank line)
#    -v start=n          # start numbering at 'n' instead of 1
#
# Windows users must enter "str" (double quotes) in the top option, above.
#
# Terms:
#   Note Marker: A string in the file to be replaced by incrementing numbers.
#   Note: A line or paragraph of text that corresponds to each Note Marker,
#       beginning with 1 to 4 pound signs, followed by period, followed by text
#       that the Note will consist of. The leading pound signs will be replaced
#       with incrementing numbers matching the Note Markers.
#   Note Block: A pair of double brackets [[...]] which contains one or more
#       Notes and/or nonprinting comments.
#
# Default Note Markers:  [#], [##], [###], etc.
#
# The note marker (pound signs in square brackets) can be changed with the
# 'alt_nm' variable. Note that this affects only the markers in the main text
# body. It does not change the markers in the Note Block. If the marker is
# changed to an @ symbol, the Note Blocks will still use "#." to increment.
#
# Note Blocks may be either of the following:
#   [[ #. Single-line style. Opening brackets must appear in column #1. ]]
# or:
#   [[
#   ##. From 1 to 4 pound signs, followed by a period, followed by content.
#   ##. Multiple references may occur within a double-bracket [[...]] span.
#   ##. Each reference will match the corresponding note marker in the text.
#   ..  Nonprinting comments in note blocks begin with '..' or '??' or '%'.
#   ..  Blank lines _between_ note references are ignored and not needed.
#   ..  Blank lines _within_ note references are preserved on output.
#   ]]
#
# To-do: put block markers "[[" and "]]" for option switch reassignment.
BEGIN {
    if ( start && start !~ /^[0-9]+$/ ) {
        print "\aError!\nVariable 'start' was set as " start ", but it",
            "must be an integer.\nQuitting here ...\n" > "/dev/stderr"
        exit 1
    }

    if ( alt_nm == "" && alt_nm != 0 ) {
        print "\aError!\nOption switch 'alt_nm' was used, but it does not",
            "have a value assigned to it.\nThe syntax must be",
            "'-v alt_nm=\"string\"', where \"string\" is interpreted as",
            "a string literal.\nQuitting here ...\n" > "/dev/stderr"
        exit 1
    }
    # else, alt_nm was defined on the command line with a non-empty value

    # Use start to set an initial note number other than 1
    i_MarkCount = i_NoteCount = ( start ? start - 1 : 0 )

    # quote special chars in alternate note markers; fewer chars than in perl
    gsub(/[.?*+([$\\]/, "\\&", alt_nm)
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

# main body
{  b_BlankLine = $0 ~ /^[ \t]*$/ ? "Y" : "" }

# Within the Note Block:
/^[ \t]*\[\[/, /]][ \t]*$/ {  # Range op "," also matches 1 line

    if ( /^[ \t]*\[\[/ ) i_LLcount++      # count [[ marker
    if ( /^[ \t]*\[\[[ \t]*$/ ) next      # skip lone [[ markers
    if ( /^(\.\.|\?\?|%)/ ) next          # skip comment lines
    sub(/^[ \t]*\[\[ ?/, "", $0)          # strip leading [[

    # Increment Note Block: (optional spaces), 1-4 pound signs, period
    # gensub would be easier here, since it supports backreferences, but I want
    # this code to be compatible with mawk and BWK awk. Note that the regex has
    # "#+", since {interval,ranges} require special switches in some awks.
    if ( match($0, /^[ \t]*#+\./) ) {
        sub(/^[ \t]*/, "_=SPLIT=_&")
        sub(/#+\./, ++i_NoteCount ".", $0)
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


    # match alternate markers
    if ( alt_nm ) {
        while ( match($0, alt_nm) ) {
            sub(alt_nm, ++i_MarkCount, $0)
        }
    }
    else {
        # match default markers: [#] or [##] or [###], etc. not limited to 4.
        while ( match($0, /\[#+]/) ) {
            sub(/\[#+]/, "[" ++i_MarkCount "]", $0)    # increment [#]
        }
    }

    # NB: Must be positioned _after_ the if(NR==...) block above
    b_BlankBeforeBlock = $0 ~ /^[ \t]*$/ ? "Y" : ""
    print $0
}

END {
    if ( i_MarkCount == i_NoteCount || ignore_errors ) {
        # The number of note markers and note references match

        # Convert references to array to handle single- or double-spacing
        if (s_Refs) {
            split(s_Refs, notes, /_=SPLIT=_/)
        }

        # print ENDNOTES header only if notes exist
        if ( i_NoteCount ) {
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
    else {       # Number of Note Markers and Notes do not match
        i_body = i_MarkCount - start;
        i_refs = i_NoteCount - start;

        print "\a\a\n\n"
        print "================"
        print "  FATAL ERROR!  "
        print "================"
        print "The number of Note Markers and Notes is not the same! There"
        print "are", $i_body," Note Markers and", $i_refs, "Notes. The Endnote section"
        print "will not be printed. Quitting here ..."
    }
}
#---end of script---
