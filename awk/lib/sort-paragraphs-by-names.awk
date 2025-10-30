# GNU awk script
#  -*- Emacs: mode:shell-script; tab-width:4; fill-column:78; indent-tabs-mode:nil; -*-
#        vim: set tw=78 ai ts=4 sw=4 expandtab :
#
# filename: sort-paragraphs-by-names
#   author: Eric Pement
#     date: 2025-10-26 02:39:22 (UTC-0400)
# requires: GNU awk
#  version: 1.0
#
# USAGE:   awk -f sort-paragraphs-by-names filename
#          cat file | awk -f sort-paragraphs-by-names
#
# Input file and output file will be in "record-jar format" or paragraph format,
# where each record is a paragraph or block of text. Paragraphs are separated by
# one or more blank lines. We assume that the first line of the paragraph block
# contains a personal name like John Doe.
#
#   Given an input file with names always on the first line:
#---------------------------
#    Mickey Mouse
#    Disneyland Park, CA
#
#    Snow White
#    Baden, Germany
#
#    Prof. Harold Hill
#    River City
#
#    Mr. Donald Duck
#
#    Clark Kent
#    Smallville
#---------------------------
#
# This script sorts on (last name, first name) to generate this:
#---------------------------
#    Mr. Donald Duck
#
#    Prof. Harold Hill
#    River City
#
#    Clark Kent
#    Smallville
#
#    Mickey Mouse
#    Disneyland Park, CA
#
#    Snow White
#    Baden, Germany
#---------------------------
BEGIN {
    RS = ""             # records separated by 1 or more blank lines
    ORS = "\n\n"        # output record separator = 1 blank line
    error_count = 0
}

function create_key(str,   tmp,key) {
    # input:  a line with "(Title)? Firstname Lastname"
    # output: Lastname,Firstname
    # Given a paragraph block, save the first line, switch the order of
    # "Firstname Lastname" to "Lastname,Firstname" to use as an array key.
    tmp = str
    sub(/\n.*/, "", tmp)   # use only the first line, discard the rest
    sub(/\s+$/, "", tmp)   # del whitespace at the EOL
    sub(/^\s+/, "", tmp)   # del whitespace at beginning of line

    # Delete Mr., Dr., Prof., but keep Mrs. (this only affects the key!)
    sub(/^Mrs[.]/, "Mrs", tmp)         # delete period in Mrs.
    sub(/Jr[.]/, "Jr", tmp)            # delete period in Jr.
    sub(/^[[:alpha:]]+[.] /, "", tmp)  # delete all titles followed by dot

    # Handle different name types, so that:
    #   Mrs William Lane Craig  => Craig,Mrs,William   4,1,2
    #   Robert M. Bowman, Jr    => Bowman,Robert,M     3,1,2
    #   Mrs William Craig       => Craig,Mrs,William   3,1,2
    #   Robert Bowman, Jr       => Bowman,Robert       2,1
    #   William Lane Craig      => Craig,William       3,1
    #   Mrs Craig               => Craig,Mrs           2,1
    #   Bill Craig              => Craig,Bill          2,1
    switch (tmp) {
    case /^Mrs \S+ \S+ \S+$/:
        key = gensub( /^(Mrs) (\S+) (\S+) (\S+)$/, "\\4_\\1_\\2", 1, tmp)
        break
    case /^\S+ \S+ \S+ Jr$/:
        key = gensub( /^(\S+) (\S+) (\S+) Jr$/, "\\3_\\1_\\2", 1, tmp)
        break
    case /^Mrs \S+ \S+$/:
        key = gensub( /^(Mrs) (\S+) (\S+)$/, "\\3_\\1_\\2", 1, tmp)
        break
    case /^\S+ \S+ Jr$/:
        key = gensub( /^(\S+) (\S+) Jr$/, "\\2_\\1", 1, tmp)
        break
    case /^\S+ \S+ \S+$/:
        key = gensub( /^(\S+) (\S+) (\S+)$/, "\\3_\\1", 1, tmp)
        break
    case /^\S+ \S+$/:
        key = gensub( /^(\S+) (\S+)$/, "\\2_\\1", 1, tmp)
        break
    default:
        # assume tmp is only one "word"; delete punctuation
        key = gensub( /[[:punct:]]/, "", g, tmp)
    }
    return key;
}

# for every record in the file:
{
    x = create_key($0)

    if (x in paragraph) {   # the key already exists
        printf "Warning! There is already an index to this person named [" x "]!\n" > "/dev/stderr"
        printf "ENTRY is: [" $0 "]\n"    > "/dev/stderr"
        printf "Not adding the entry!\n" > "/dev/stderr"
        error_count++
    }
    else {
        paragraph[x] = $0          # add each block to the array
    }
}

END {
    total = asorti(paragraph, order)    # sort the array keys

    for (i = 1; i <= total; i++) {
        if ( i == total )
            printf paragraph[ order[i] ] "\n"
        else
            print paragraph[ order[i] ]
    }

    if ( error_count > 0 )
        printf "WARNING:", error_count " records omitted from the output!\n" > "/dev/stderr"
}
