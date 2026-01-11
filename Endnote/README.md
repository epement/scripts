# Endnote

Endnote is a lightweight, simple system I created several years ago
for editing and printing textfiles with documentation (footnotes, endnotes,
academic references). The goal was for me to have a source document where
if I moved sections, paragraphs, or added or deleted text and notes, I
would not have to renumber everything. I wanted sequential notes.

I also wanted to have a way to embed personal remaks to myself---usually
a reminder to check the facts or spelling on something, or to include
text blocks that I wanted to keep but weren't good enough to publish.
I _prefer_ page-bottom footnotes, but my need for simplicity forced me
to write it as document-bottom endnotes. That was the origin of Endnote.

This method uses a *very* lightweight markup system for putting note
references and comments in a text file. I call it ENDNT markup language.

Two fundamental elements are used:

(1) Note markers are indicated by "[#]" or "[##]", up to "[####]", right
after anything that needs to be documented or footnoted. Endnote will replace
the markers with incrementing digits "[1]", "[2]", "[3]", etc.

(2) Note blocks begin with "[[" in column 1 and end with a matching "]]",
which must be the two last characters on the line. Note blocks should be
put under the corresponding Note Markers, ideally in the same or next
paragraph.

Between the two double-brackets, there are a few rules or expectations
for formatting Notes or Comments. 

A simple awk or perl script is used to pass through the source document,
where it converts the ambiguous Note Markers into incrementing numbers,
extracts all the [[ double-bracket note blocks ]], stuffs them into a
temporary memory variable, and then prints them out nicely below an
"ENDNOTES" subtitle at the very end of the document.

As mentioned earlier, the Note Blocks can also contain Comments. Anything
marked as a comment is omitted from the output.

At the present time (January 2026), the Endnote conversion script exists
for two common languages, awk and perl.

To assist in wider distribution, I have included a Windows batch file,
"endnote.cmd", needing manual configuration. Not much, though: tell
it where perl or awk are, and edit the location of the perl or awk
scripts. Type "endnote --help" or "endnote --summary" for a brief
reminder of the syntax.

I recently updated the batch file to allow the user to choose between awk and
perl if both are installed and on the Windows path.

[end]



