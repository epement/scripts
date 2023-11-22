#!/usr/bin/perl -s
#  Emacs file variables: -*- mode:perl; indent-tabs-mode:nil; tab-width:4; -*-
#
# Filename: endnote.pl
#   Author: Eric Pement
#  Version: 1.44
#     Date: 2023-11-22 15:30:47 (UTC-0500)
# Copyleft: Free software under the terms of the GNU GPLv3
#  Purpose: To convert in-text references and notes to endnotes
#
#  Usage:
#     endnote.pl [-options] source.txt >output.txt
#     perl [-s] endnote.pl [-options] source.txt >output.txt
#
# Options
#   -alt_nm='str'   # use 'str' (literal) as an alternate note marker
#   -ignore_errors  # ignore mismatched numbering in endnotes
#   -ssnotes        # omit blank line between notes (default: 1 line)
#   -start='n'      # start numbering at 'n' instead of 1
#
# DOS/Windows users should enter "str" (double quotes) in the top option, above
#
use strict;
use vars qw/$start $ssnotes $ignore_errors $alt_nm/;
# use warnings;       # disnabled to avoid warnings about locale not being set
# use diagnostics;    # requires a full version of perl

my ($i_TextCount, $i_RefCount, $s_Refs, $i_LLcount, $i_RRcount, $errmsg);
my (@notes, $b_BlankLine, $b_BlankBeforeBlock, $i_CurrLineNum, $i_BlockEndLineNum);
$i_TextCount = $i_RefCount = $i_LLcount = $i_RRcount = 0;
$i_CurrLineNum = $i_BlockEndLineNum = 0;
$ignore_errors = 0 unless defined $ignore_errors;

if (defined $start and $start !~ /^\d+$/ ) {
    print STDERR "\aError!\nVariable 'start' was set as $start, "
    . "but it must be an integer.\nQuitting here ...\n";
    exit 1;
}

if (defined $alt_nm and $alt_nm =~ /^$/ ) {
    print STDERR "\aError!\nOption switch 'alt_nm' was used, but "
    . "it does not have a value assigned to it.\n"
    . "The syntax must be '-alt_nm=\"string\"', where \"string\" is "
    . "interpreted as a string literal.\nQuitting here ...\n";
      exit 1;
}

=head1 NAME

ENDNOTE - A program for extracting and formatting endnotes from a lightly
marked input file.

=head1 SPECIAL TERMS

 Note references - The digits in a printed document which usually appear in
     superscript or in [square brackets]. In plain ASCII, superscript is not
     available, so note references occur inside square brackets.

 Note Markers - Identical strings which will be changed to incrementing
     numbers (note references) after the file is processed.

 Note - A citation or documentation item referred to by a note reference. It
     may be as short as "Ibid." or as long as several paragraphs.

 Note Body - A note (above), prefixed by "#." or "##." at the beginning of
     the line.

 Note Block - A group of one or more note bodies, enclosed before and after
     by 2 consecutive square brackets, as "[[" and "]]".

=head1 THEORY AND GOAL

The goal of ENDNOTE is to make it easy to edit text files with endnotes using
a plain text editor like vim, Emacs, Notepad++, etc.

In academia, note references are sequential numbers in square brackets that
direct the reader to a corresponding number at the page bottom ("footnotes")
or the end of the document ("endnotes"), usually citing a source.

While writing, moving paragraphs containing note references is difficult.
Microsoft Word handles auto-renumbering, but this is not possible in plain
text. Some writers resort to the Author-Date citation system (Pement 2023).

To get numbered citations, ENDNOTE requires a markup document with anonymous
note markers. ENDNOTES numbers each marker and moves the notes to the end of
the file. Output goes to screen unless redirected. ENDNOTE offers various ways
to enter notes into a document. Choose one that works best for you.

At this time, ENDNOTE produces only endnotes, not footnotes.

=head2 INSERT THE NOTE MARKERS

In a paragraph, indicate Note Markers by one of these strings: [#] or [##] or
[###] or [####]. They represent the point where incrementing numbers should
appear in the text. For example,

   [####] [#] [##]

will be translated to "[1] [2] [3]" at the beginning of a file. The number of
pound signs does not control how the numbers appear on output, and numbers
higher than 9999 are available with [#] alone.

Line-length of the output is usually important, so remember that as Note
Markers expand to multiple digits, overall line length will also expand.
Therefore:

   ape[#] bee[#] cow[#] dog[#] eagle[#] frog[#]

with sufficient previous notes might expand into:

   ape[1512] bee[1513] cow[1514] dog[1515] eagle[1516] frog[1517]

You may switch from [#] to [##] at any time. I normally use [##] for most of
my writing, since I rarely have more than 99 footnotes in one file.

The option "-alt_nm=I<string>" allows setting the note marker to a string other
than "[#]" and its relatives. This string will be interpreted as a literal
string, not as a regular expression (e.g., you can use '*' if you like).

=head2 INSERT THE NOTE BLOCKS

ENDNOTE lets you enter note text as close to the Note Marker as you wish,
either within the same paragraph, at the end of the paragraph, or in the
following paragraph. Whichever you choose, you must put the Note Body inside a
Note Block, defined as:

  Note Block  -
      A group of consecutive lines enclosed between "[[" and "]]",
      containing Note Bodies, or comments, or both. Note Blocks are
      best placed near the paragraphs with their matching Note
      Markers, but they can be placed anywhere in the document.

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

=head3 (a) Block inside the paragraph

=over 2

   Fortunately, the GNU implementation of the //coreutils// package[#]
   [[ #. Available at ftp://ftp.gnu.org/gnu/coreutils/. ]]
   remedies that deficiency via the //-stable// option: its output for
   this example correctly matches the input.

=back

The above works best if "[[" and "]]" will fit on a single line.

=head3 (b) Block touches end of paragraph

=over 2

   Fortunately, the GNU implementation of the //coreutils// package[#]
   remedies that deficiency via the //-stable// option: its output for
   this example correctly matches the input.
   [[
   #. Available at ftp://ftp.gnu.org/gnu/coreutils/.
   ]]

=back

In the above, the Note Block markers are put on separate lines. Paragraph
reformatting usually "wraps" a Note Block to the end of the previous sentence,
destroying the formatting. Use with care.

=head3 (c) Block forms its own paragraph

=over 2

   Fortunately, the GNU implementation of the //coreutils// package[#]
   remedies that deficiency via the //-stable// option: its output for
   this example correctly matches the input.

   [[
   #. Available at ftp://ftp.gnu.org/gnu/coreutils/.
   ]]

=back

The above works best for me.

Put a blank line between the paragraph and the Note Block. This will not
result in an extra line in the output, because ENDNOTE deletes one blank line
when moving the Note Block to the end of the file.

=head1 COMMENTS SUPPORTED

Inside Note Blocks, ENDNOTE supports nonprinting comment lines. Lines that
begin with ".." or "??" or "%" are not printed. This lets writers add comments
to themselves which will not appear in the output. A Note Block can consist
entirely of comment lines.

=head1 BLANK LINES IN NOTE BODIES

A Note Body begins with optional whitespace, 1-4 pound signs, and a period. It
continues until the next Note Body begins. When the Note Bodies are processed,
the pound signs are converted to the next expected integer.

Blank lines inside or around Note Bodies are handled like this:

=over 3

=item - All blank lines before the first Note Body are discarded.

=item - All blank lines in the middle of a Note Body are kept intact.

=item - All blank lines at the end of a Note Body are discarded.

=back

When ENDNOTE runs, it immediately prints the body text and auto-numbers the
Note Markers, while putting the Note Bodies into a FIFO array without printing
them. When it comes time to print the endnotes, it counts the number of
already-printed Note Markers and the number of Note Bodies waiting to be
printed (the size of the array). If there is a mismatch, ENDNOTE aborts with
an explanatory error message.

Otherwise, ENDNOTE prints the following:

   ---------
   ENDNOTES:

followed by the collected array of Note Bodies. The "[[" and "]]" markers
around the Note Block are discarded.

=head1 OPTIONS

By default, Note Markers in the text are indicated by [#], [##], etc. You may
use something simpler, such as '*' (asterisk), by the switch I<alt_nm>.
The characters will be interpreted as literal strings, not as regular
expressions or metacharacters.

By default, one blank line is automatically inserted after each Note Body
(double-spacing between notes, which is not the same as double-spacing each
note). If a switch is passed for I<ssnotes> (single-spaced notes), the
blank line between notes is omitted.

By default, note numbering always begins with 1. The switch I<start> allows
notes to begin at any specified integer, including zero.

By default, ENDNOTE halts if the number of Note Bodies does not equal the
number of Note Markers. The switch I<ignore_errors> causes ENDNOTE to ignore
mismatched notes in the body and the endnote section, printing the notes "as
is" without halting. This switch can be helpful if you need to print a working
draft and you don't care about mismatched notes.

This switch is also useful if you simply need to number items in a list.
Set I<alt_nm> to a simple string like '#', use I<ignore_errors>, and
ENDNOTE will replace each '#' with an incrementing number. If you need to,
you can use I<start> at the same time.

=head1 PERL USAGE

Normal syntax:

   endnote.pl [-options] source.txt > output.txt
or
   perl [-s] endnote.pl [-options] source.txt > output.txt

Switch placement. Note that B<-s> comes I<before> the script name, but the
options prefixed with a hyphen come I<after> the script name.

Options:

 -alt_nm='str'   # use 'str' (literal) as an alternate Note Marker
 -ignore_errors  # ignore mismatched numbering in endnotes
 -ssnotes        # omit blank line between notes (default: 1 line)
 -start='n'      # start numbering at 'n' instead of 1

=head1 CREDITS

The idea for this system came from "wsNOTE" by Eric Meyer. wsNOTE was a CP/M
and MS-DOS utility for handling both footnotes and endnotes in WordStar files,
at a time when WordStar supported neither.

=head1 AUTHOR

Eric Pement

=head1 VERSION

This release of ENDNOTE is version 1.44

=cut

# $i_TextCount counts note markers in the body of the main text.
# $i_RefCount counts note items in the endnote body at the end.
# Use $start to set an initial note number other than 1.
$i_TextCount = $i_RefCount = (defined $start ? $start - 1 : 0);

# quote special characters in alternate note markers
$alt_nm =~ s/[.?*+([$@%&`\\]/\\$&/g if defined $alt_nm;

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
        s/$alt_nm/++$i_TextCount/ge if defined $alt_nm;

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

if ( $i_TextCount == $i_RefCount or $ignore_errors) {  # note markers/bodies match

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
    The number of Note Markers and Note Bodies is not the same!
    There are $i_body Note Markers and $i_refs Note Bodies. The
    Endnote section will not be printed. Quitting here ...


    FINIS
    print "$errmsg";
}
#---end of script---
