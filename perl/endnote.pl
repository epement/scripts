#!/usr/bin/perl -w
#  Emacs file variables: -*- mode:perl; indent-tabs-mode:nil; tab-width:4; -*-
#
# Filename: endnote.pl
#   Author: Eric Pement
#  Version: 1.42
#     Date: 2012-12-28, 2023-11-01
# Copyleft: Free software under the terms of the GNU GPLv3
#  Purpose: To convert in-text notes and references to endnotes
#
#  Usage: perl [-s] endnote.pl [-options] source.txt >output.txt
#
# Options
#   -alt_np='str'   # use 'str' (literal) as an alternate note point
#   -ignore_errors  # ignore mismatched numbering in endnotes
#   -ssnotes        # omit blank line between notes (default: 1 line)
#   -start='n'      # start numbering at 'n' instead of 1
#
# DOS/Windows users should enter "str" (double quotes) in the top option, above
#
use strict;
use vars qw/$start $ssnotes $ignore_errors $alt_np/;
# use warnings;
# use diagnostics;    # requires a full version of perl

my ($i_TextCount, $i_RefCount, $s_Refs, $i_LLcount, $i_RRcount, $errmsg);
my (@notes, $b_BlankLine, $b_BlankBeforeBlock, $i_CurrLineNum, $i_BlockEndLineNum);
$i_TextCount = $i_RefCount = $i_LLcount = $i_RRcount = 0;
$i_CurrLineNum = $i_BlockEndLineNum = 0;
$ignore_errors = 0 unless defined $ignore_errors;

if (defined $start and $start !~ /^\d+$/ ) {
    print STDERR "\aError!\nVariable 'start' was set as $start,"
    . "but it must be an integer.\nQuitting here ...\n";
    exit 1;
}

if (defined $alt_np and $alt_np =~ /^$/ ) {
    print STDERR "\aError!\nOption switch 'alt_np' was used, but "
    . "it does not have a value assigned to it.\n"
    . "The syntax must be '-alt_np=\"string\"', where \"string\" is "
    . "interpreted as a string literal.\nQuitting here ...\n";
    exit 1;
}

=head1 NAME

ENDNOTE - A program for extracting and formatting endnotes from a lightly
marked input file.

=head1 SPECIAL TERMS

 note points - The places in the document body (paragraph) where superscript
               or bracketed numbers would normally be placed. Note points
               appear in the main text, not at the end of the document.

 note body   - The full text of an individual note, whether a single word
               like "Ibid." or a long comment extending a paragraph or more.
               Each note point must have a corresponding note body.

=head1 THEORY AND GOAL

The goal of ENDNOTE is to make it easy to create and edit documents with note
references using a plain text editor like vi, vim, Emacs, PSPad, UltraEdit,
Notepad++, gedit, etc. Note references in academic writing are sequential
numbers set in square brackets or set in superscript, referring the reader to
the same number at the bottom of the page ("footnotes") or at the end of the
document ("endnotes"), giving formal citation or further explanation for
something written at the note point.

The best way to do this is with a source document (for editing) that produces
a target document with the formatted output.

We believe the source document with its markup should be as easy to read as
the output document. It should be easy to move paragraphs around, and the
notes should follow. A block of text containing several notes should be easy
to move to another location without renumbering anything. This system allows
the writer or editor to focus on the organization of the paper, without being
distracted by manually numbering and renumbering note references.

When the writing is complete, the source document is run through a script
which numbers all the note points sequentially and collects all the "note
bodies", deleting them from the main body of the document and moving them to
the end of the file, where they are formatted and neatly printed. The total
number of note points in the main document will always match the total number
of notes at the end of the document.

If the output doesn't look like you expect, the source document is still a
separate file. Tweak the source file as necessary, and create a new output
file.

The markup style for ENDNOTE offers users different ways of entering note
text ("note bodies") into a document. Choose whichever works best for you.

The markup style allows the user to double-space note references in the
source document, but have single-spaced note references in the output
document. Or vice versa: users can single-space note references in the source
document but print double-spaced note references in the target document. Or
they can use the same formatting in both source and destination.

The markup style in ENDNOTE was designed for handling plain text with
monospaced, nonproportional fonts, but it works equally well in output
formats without fixed page widths, such as HTML. At this time, ENDNOTE
produces only endnotes, not footnotes.

So let's get to the system, which has just two items: how to insert note
points (strings pointing to note references), and how to insert the note
references themselves (the academic documentation or explanatory statement).

=head2 INSERT THE NOTE POINTS

In a paragraph, indicate the note references by one of these strings: [#] or
[##] or [###] or [####]. I call these strings "note points." They represent
the point in the line where incrementing numbers should appear in the text.
It makes no difference which you use. For example,

   [####] [#] [##]

will be interpreted as "[1] [2] [3]" at the beginning of a file. The number
of pound signs ("#") does not control how the numbers appear on output, and
numbers higher than 9999 are available with [#] alone.

If you are writing for monospaced output where line-lengths are important,
bear in mind that as note numbers expand to multiple digits, line lengths on
the output file may be longer than expected. For example,

   ape[#] bee[#] cow[#] dog[#] eagle[#] frog[#]

with sufficient previous notes might expand into:

   ape[1512] bee[1513] cow[1514] dog[1515] eagle[1516] frog[1517]

So if you are using a lot of footnotes, feel free to switch from [#] to [##]
or [####] any time you like. I normally use [##] for most of my writing,
since I rarely have more than 99 footnotes in a single document.

The option "-alt_np=I<string>" allows setting the note point to a string other
than "[#]" and its relatives. This string will be interpreted as a literal
string, not as a regular expression (e.g., you can use '*' if you like).

=head2 INSERT THE NOTE BLOCKS

The ENDNOTE system lets you enter note references as close to the original
note as you would like, either within the same paragraph, at the end of the
paragraph, or in the following paragraph. Whichever you choose, you must
enter the references in a note block, defined here:

  note block  -
      A group of consecutive lines enclosed between "[[" and "]]",
      containing note bodies, or comments, or both. Note blocks are
      best placed near the paragraphs with their matching note
      points, but they can be placed anywhere in the document.

Important: The opening tag "[[" must occur in column #1 or must be preceded
by nothing but spaces or tabs at the beginning of the line. This is because
the entire line will be moved when the endnotes are formatted. Likewise, the
closing tag "]]" cannot be followed by anything else on the line (other than
spaces or tabs, which will be deleted on output).

Let me illustrate with an example from the book "Classic Shell Scripting," by
Nelson Beebee and Arnold Robbins (O'Reilly, 2005; ISBN 0-596-00595-4). As
mentioned, there are several ways to construct the note block. Had Beebee and
Robbins had ENDNOTE available to them, they could have marked up some of
their paragraphs like this:

=head3 Notes within the paragraph

In the following example, Italic type is indicated by the txt2tags markup of
wrapping italicized words in two slashes "//".

   Fortunately, the GNU implementation of the //coreutils// package[#]
   [[ #. Available at ftp://ftp.gnu.org/gnu/coreutils/. ]]
   remedies that deficiency via the //-stable// option: its output for
   this example correctly matches the input.

This is both efficient and compact. Observe that "[[" and "]]" may occur on a
single line, as above. It is useful for short notes, but with longer notes of
several lines, this style breaks up the readability of the paragraph.

=head3 Notes at the end of the paragraph

Two or more note references can be included in a note block. For increased
legibility, the note block can be moved to the end of the paragraph. Also,
the "[[" marker does not need to have text on the same line, nor does "]]"
need to have any words before it on the same line.

   The locale name encodes a language, a territory, and optionally, a
   codeset and a modifier. It is normally represented by a lowercase
   two-letter ISO 639 language code,[#] an underscore, and an uppercase
   two-letter ISO 3166-1 country code,[#] optionally followed by a dot and
   the character-set encoding, and an at-sign and a modifier word.
   [[
   #. Available at http://www.ics.uci.edu/pub/ietf/http/related/iso639.txt.
   #. Available at http://userpage.chemie.fu-berlin.de/diverse/doc/ISO_3166.html.
   ]]

=head3 Notes in a subsequent paragraph

The "paragraph reformat" command of most editors, if applied to the paragraph
of the preceding example, will probably "wrap" the note block to the end of
the previous sentence, destroying its formatting. (Remember, "[[" must be the
first visible characters on a line.)

If you insert a blank line between a paragraph and the note block, the note
block will I<not> be merged with the paragraph above it.

   The locale name encodes a language, a territory, and optionally, a
   codeset and a modifier. It is normally represented by a lowercase
   two-letter ISO 639 language code,[#] an underscore, and an uppercase
   two-letter ISO 3166-1 country code,[#] optionally followed by a dot and
   the character-set encoding, and an at-sign and a modifier word.

   [[
   #. Available at http://www.ics.uci.edu/pub/ietf/http/related/iso639.txt.
   #. Available at http://userpage.chemie.fu-berlin.de/diverse/doc/ISO_3166.html.
   ]]

"Now wait a minute," you ask. "If there is a blank line before a note block
and a blank line after a note block, when the note block is removed, won't
that leave one extra line in the output file?"

For a careless programmer, yes. But ENDNOTE is crafty enough to recognize its
own context. If a note block is preceded by a blank line and also followed by
a blank line (thus making the note block a "paragraph" in its own right),
ENDNOTE will delete one of those extra blank lines when the note block is
moved to the end of the file.

=head1 COMMENTS, BLANK LINES, FORMATTING.

Within a note block, ENDNOTE supports nonprinting comment lines. If a line
begins with ".." or "??" or "%", that line is not printed. This allows
writers to add comments to themselves which will not appear in the output
file. In fact, a note block can consist entirely of comment lines.

A "note body" begins with optional space, 1-4 pound signs, and a period. It
continues until the next note body begins. When the notes are converted, the
string of pound signs is converted into the next expected integer.

Blank lines in the middle of note blocks are handled like this:

=over 3

=item - All blank lines before the first note body are discarded.

=item - All blank lines in the middle of a note body are kept intact.

=item - All blank lines at the end of a note body are stripped off.

=back

When ENDNOTE runs, it immediately prints the body text and "note points",
while collecting note bodies (without printing them). When it comes time to
print the endnotes, it counts the number of already-printed note points and
the number of note bodies waiting to be printed. If there is a mismatch,
ENDNOTE aborts with an explanatory error message.

Otherwise, ENDNOTE prints

   ---------
   ENDNOTES:

followed by the collected series of note bodies. The "[[" and "]]" markers
are discarded.

=head1 OPTIONS

By default, note points in the text must be indicated by [#], [##], [###],
or [####]. You may opt for something simpler, such as '*' (asterisk), by
the switch I<alt_np>. The characters will be interpreted as literal strings,
not as regular expressions or metacharacters.

By default, one blank line is automatically inserted after each note body
(double-spacing between notes, which is not the same as double-spacing each
note). If a switch is passed for I<ssnotes> (single-spaced notes), the
blank line is omitted.

By default, note numbering always begins with 1. A switch named
I<start> allows notes to begin numbering at any specified integer.

By default, ENDNOTE halts if the number of note bodies do not
correspond with the number of note points. A switch named
I<ignore_errors> causes ENDNOTE to ignore mismatched notes in the body
and the endnote section, printing the notes "as is" without halting.
This switch can be helpful if you need to print a working draft and
you don't care about mismatched notes.

This switch is also useful if you simply need to number items in a list.
Set I<alt_np> to a simple string like '#', use I<ignore_errors>, and
ENDNOTE will replace each '#' with an incrementing number. If you need to,
you can use I<start> at the same time.

=head1 PERL USAGE

Normal syntax:

   perl [-s] endnote.pl [-options] source.txt > output.txt

Switch placement. Note that B<-s> comes I<before> the script name, but the
options prefixed with a hyphen come I<after> the script name.

Options:

 -alt_np='str'   # use 'str' (literal) as an alternate note point
 -ignore_errors  # ignore mismatched numbering in endnotes
 -ssnotes        # omit blank line between notes (default: 1 line)
 -start='n'      # start numbering at 'n' instead of 1

=head1 CREDITS

Key ideas for this system are adapted from "wsNOTE" by Eric Meyer. wsNOTE was
a MS-DOS utility for handling both footnotes and endnotes in WordStar files,
at a time when WordStar supported neither. Documentation for wsNOTES is at
http://sites.google.com/site/vdeeditor/Home/vde-files/wsnote-manual

=head1 AUTHOR

Eric Pement - eric.pement [=at=] gmail.com

=head1 VERSION

This release of ENDNOTE is version 1.42.

=cut

# $i_TextCount counts note points in the body of the main text.
# $i_RefCount counts note items in the endnote body at the end.
# Use $start to set an initial note number other than 1.
$i_TextCount = $i_RefCount = (defined $start ? $start - 1 : 0);

# quote special characters in alternate note points
$alt_np =~ s/[.?*+([$@%&`\\]/\\$&/g if defined $alt_np;

LINE: while (<>) {
    chomp;        # delete trailing LF or CRLF, usually
    s/\r//;       # sometimes under Cygwin, chomp() misses a trailing CR

    $b_BlankLine = m/^\s*$/ ? "Y" : "";

    if ( /^\s*\[\[/ .. /]]\s*$/ ) {  # range operator ".." matches on the same line

        $i_LLcount++ if /^\s*\[\[/;  # count [[ marker
        next if /^\s*\[\[\s*$/;      # skip lone [[ marker
        next if /^(\.\.|\?\?|%)/;    # skip comment lines
        s/^\s*\[\[ ?//;              # strip leading [[

        # Increment note block: (optional spaces), 1-4 pound signs, period
        s/^(\s*)#{1,4}(?=\.)/"_=SPLIT=_$1" . ++$i_RefCount/ge;

        # Is the closing marker, ]], on this line?
        if ( s/\s*]]\s*$// ) {
            $i_RRcount++;              # count ]] marker
            $i_BlockEndLineNum = $.;
            $s_Refs .= "$_\n";         # store line in the accumulator
        }
        else {
            $s_Refs .= "$_\n";         # store line in the accumulator
        }

    }
    else {                           # Not in the note block ..

        next if $. == ($i_BlockEndLineNum + 1) and $b_BlankLine and $b_BlankBeforeBlock;

        s/\[#{1,4}]/"[" . ++$i_TextCount . "]"/ge;       # increment [#]
        s/$alt_np/++$i_TextCount/ge if defined $alt_np;

        # NB: Must be positioned _after_ the if() block above.
        $b_BlankBeforeBlock = m/^\s*$/ ? "Y" : "";
        print "$_\n";
    }
}

sub printEndnotes {

    if ( defined $ssnotes and $ssnotes == 1 ) {
        s/\n*$/\n/ foreach @notes;                  # single-spaced
    }
    else {
        s/\n*$/\n\n/ foreach @notes;                # double-spaced
    }
    shift @notes;                    # because the 1st note is always blank
    print $_ foreach @notes;

}

if ( $i_TextCount == $i_RefCount or $ignore_errors) {  # note points/bodies match

    # Convert to array to handle single- or double-spacing on output
    @notes = split '_=SPLIT=_', $s_Refs if $s_Refs;

    # print ENDNOTES header only if notes exist.
    if ( $i_RefCount ) {
        print "\n---------\nENDNOTES:\n\n";
        printEndnotes();
        print "[end of file]\n";
    }

    if ( ($i_LLcount != $i_RRcount) and ($ignore_errors != 1) ) {

        print "DIAG: $i_LLcount, $i_RRcount, $ignore_errors\n";

        ($errmsg = <<"        FINIS") =~ s/^[ \t]+//gm;

        ================
            WARNING
        ================
        There were $i_LLcount Left Note Block Markers and $i_RRcount Right note block markers.
        Examine your output carefully, because there may be a formatting error.
        =======================================================================

        FINIS
        print "$errmsg";
    }
}
else {

    my $i_body = defined $start ? $i_TextCount - $start : $i_TextCount ;
    my $i_refs = defined $start ? $i_RefCount - $start  : $i_RefCount ;

    ($errmsg = <<"    FINIS") =~ s/^[ \t]+//gm;
    \a\a

    ================
      FATAL ERROR!
    ================
    Note points in the body and References at the end do not match!
    There are $i_body Note points in the body text and $i_refs References
    for those $i_body notes. The Endnote section will not be printed.
    Quitting here ...


    FINIS
    print "$errmsg";
}
#---end of script---
