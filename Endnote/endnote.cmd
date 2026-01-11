@echo off
:: filename: endnote.cmd (Windows CMD batch file to use Endnote easily)
::   author: Eric Pement
::  updated: 2026-01-11 01:01:23 (UTC-0500)
::
:: Requires all the following:
::   where.exe : included on Windows Server 2003, Vista, Windows 7, and later
:: findstr.exe : included on Windows Server 2003, Vista, Windows 7, and later
:: perl or awk : must be installed separately
:: endnote.pl or endnote.awk : must be installed from github, below
::
:: Latest version of Endnote is at https://github.com/epement/scripts

SETLOCAL ENABLEEXTENSIONS

::============================================================================
:: Configure these settings to match your setup! Keep the double quote marks.
:: EN_PATH_TO_AWK can be any modern awk, such as gawk, mawk, one-true-awk, etc.
:: Edit the variables below to match your version of awk and perl.

set EN_PATH_TO_PERL="c:\strawberry\perl\bin\perl.exe"
set  EN_PATH_TO_AWK="c:\utils\path\to\awk.exe"

set EN_PERL_SCRIPT="c:\tools\bat\lib\perl\endnote.pl"

:: Windows users must use FORWARD slash, not backslash, for the next line
set EN_AWK_SCRIPT=c:/tools/bat/lib/awk/endnote.awk
::============================================================================

if "%1"=="--help"     goto help
if "%1"=="-help"      goto help
if "%1"=="/?"         goto help
if "%1"=="-?"         goto help
if "%1"=="-h"         goto help
if "%1"==""           goto help
if "%1"=="--summary"  goto summary
set EN_COMMANDLINE=%*

:: Normal search order: path-to-perl, perl.exe, path-to-awk, awk.exe
if "%1" == "--awk" (
    call :defineAwkExe
    set EN_REQUIRE=awk
) else (
    call :definePerlExe
)

:: Choose a script to go with the exe
if "%EN_REQUIRE%" == "awk" (
    if NOT EXIST %EN_AWK_SCRIPT% (
        call :fatal_aScript %0
        exit /b
    ) else (
        set EN_SCRIPT=%EN_AWK_SCRIPT%
    )
) else (
    if NOT EXIST %EN_PERL_SCRIPT% (
        call :fatal_pScript %0
        exit /b
    ) else (
        set EN_SCRIPT=%EN_PERL_SCRIPT%
    )
)

:: Report on what program will be used, if both are available
if "%1" == "--report" (
    call :giveReport %ENDNT_EXE% %EN_SCRIPT%
    exit /b
)

:: Run the program
if "%EN_REQUIRE%" == "awk" (
   %ENDNT_EXE% -f %EN_SCRIPT% %EN_COMMANDLINE:--awk =%
) else (
   %ENDNT_EXE% %EN_SCRIPT% %EN_COMMANDLINE%
)

goto:eof


:definePerlExe
if exist %EN_PATH_TO_PERL% (
    set ENDNT_EXE=%EN_PATH_TO_PERL%
) else (
    where /q perl.exe || echo x >perl_search_failed
    if exist perl_search_failed (
        del /q perl_search_failed
    ) else (
        set ENDNT_EXE=perl.exe
    )
)
:: Normally, `where perl.exe` should return exit 0 on success and 1 on failure.
:: For some reason, both %ERRORLEVEL% nor ERRORLEVEL always return zero.
:: Only using the double-pipes immediately after produces reliable results.
:: Creating an intermediate disk file is the best way to fix this issue.
if NOT DEFINED ENDNT_EXE call :defineAwkExe
exit /b

:defineAwkExe
if exist %EN_PATH_TO_AWK% (
   set ENDNT_EXE=%EN_PATH_TO_AWK%
   set EN_REQUIRE=awk
) else (
   where /q awk.exe || echo x >awk_search_failed
   if exist awk_search_failed (
       del /q awk_search_failed
   ) else (
       set ENDNT_EXE=awk.exe
       set EN_REQUIRE=awk
   )
)

:: See comments on `where perl.exe` above, which also apply here.
if NOT DEFINED ENDNT_EXE (
    where /q gawk.exe || echo x >gawk_search_failed
    if exist gawk_search_failed (
        del /q gawk_search_failed
        call :no_exe awk
        exit /b
    ) else (
        set ENDNT_EXE=gawk.exe
        set EN_REQUIRE=awk
    )
)
:: use generic error msg for perl and awk
if NOT DEFINED ENDNT_EXE call :no_exe
exit /b

:giveReport
if "%1" == "awk.exe" (
    awk "BEGIN{ printf \"Endnote path to binary : \"; system(\"where awk\") }"
) else if "%1" == "gawk.exe" (
    gawk "BEGIN{ printf \"Endnote path to binary : \"; system(\"where gawk\") }"
) else if "%1" == "perl.exe" (
    perl -e "print \"Endnote path to binary : \", `where perl`;"
) else (
    echo Endnote path to binary : %1
)
echo Endnote path to script : %~f2
goto end

:help
:: Notice the caret "^" to quote and prevent ">" from redirecting to the disk.
echo Endnote v1.45 - Extract and generate endnotes from marked text file
echo.
echo   Endnote requires a textfile which has been marked up with ENDNT, a very
echo   lightweight markup language for inserting notes and comments in plain
echo   text files. Output goes to the screen unless redirected.
echo   Source at https://github.com/epement/scripts/tree/main/Endnote
echo.
echo Usage:
echo    endnote [-options] source.txt [ ^>formatted.txt]
echo    endnote --awk [other args]  # Use awk even though perl is on the PATH
echo.
echo    endnote -           # Use single "-" to pipe input into Endnote
echo    endnote --help      # Display this help
echo    endnote --report    # Show full path to executable and script
echo    endnote --summary   # Show summary of how to mark the input file
echo.
echo Options for Perl script:
echo   -alt_nm="str"   # Use "str" as a Note Marker (default: 1-4 "#" signs)
echo   -ignore_errors  # Ignore mismatched numbers in Note Markers and Notes
echo   -ssnotes        # Omit blank line between Notes (default: 1 blank line)
echo   -start=N        # Start numbering at N instead of 1
echo.
echo Options for awk script:
echo   -v alt_nm="str"      # Alt Note Marker cannot be *, +, or ?
echo   -v ignore_errors=1   # Set to 1 to ignore errors
echo   -v ssnotes=1         # Set to 1 to print single-spaced
echo   -v start=N           # Start numbering at N instead of 1
goto end


:summary
echo ----Special terms----
echo NOTE MARKERS go in the body of the document for later conversion.
echo NOTES are the corresponding citations (eg, "Ibid.") Endnote will number
echo    and move them from the body of the file to the end as endnotes.
echo COMMENTS are private statements to be deleted from the output.
echo NOTE BLOCKS are groups of 1 or more Notes or Comments. They start in the
echo    in the body near the Note Markers, but are moved on output.
echo.

echo ----Usage----
echo In a text paragraph, insert Note Markers as [#], [##], [###], or [####].
echo The number of "#" signs does not control any formatting in Endnote.
echo If you expect to use less than 100 references, use 2 "#" signs. Endnote
echo will increment the pound signs inside the single brackets.
echo.

echo Put both Notes and Comments inside double brackets. "[[" and "]]"
echo may be on the same line or span 3 or more lines. Note Blocks can be
echo [[ #. Like this, only for very short notes. ]]
echo inside a paragraph, but are best placed directly below the paragraph.
echo.

echo [[
echo ##. Notes MUST have "#." or "##." as the first visible characters on
echo the line. If any chars precede them, they will not be auto-numbered.
echo ##. A Note can consist of multiple paragraphs. Blank lines WITHIN a Note
echo are preserved. Blank lines BETWEEN Notes are optional.
echo .. Inside [[ Note Blocks ]], lines that begin with "..", "??", or "%%"
echo .. as the first character on the line are non-printing comments.
echo .. Comment lines are deleted only if they are inside Note Blocks.
echo    ##. If a Note is indented with spaces on the input, it will also be
echo indented in the output.
echo ]]
echo.

echo Use "-alt_nm" (Alternate Note Marker) to number list items like this:
echo   * milk
echo   * eggs    Do: endnote -alt_nm="*" -ignore_errors list.txt (in Perl)
echo   * bread
echo to turn a column of asterisks into a numbered list. Using an alternate
echo marker only affects numbering the body text, not the [[Note Blocks]].
echo Perl allows "-alt_nm" to be any symbol or multi-character string. Awk
echo allows most symbols or strings except regex quantifiers (*, +, or ?).
echo.
echo Run "endnote --summary | endnote -" to see how Endnote usually works.
goto end

:fatal_pScript
echo --------------------------------------------------------
echo FATAL! Perl is correctly located, but the Endnote script
echo is not found at: %EN_PERL_SCRIPT%
echo Please edit the batch file: %~f1
echo.
echo Change the value of EN_PERL_SCRIPT to point to the
echo correct location. Quitting here ...
goto end

:fatal_aScript
echo --------------------------------------------------------
echo FATAL! Awk is correctly located, but the Endnote script
echo is not found at: %EN_AWK_SCRIPT%
echo Please edit the batch file: %~f1
echo.
echo Change the value of EN_AWK_SCRIPT to point to the
echo correct location. Quitting here ...
goto end

:no_exe
echo FATAL ERROR!
if "%1" == "awk" (
    echo Awk was requested to run Endnote, but neither awk.exe nor
    echo gawk.exe are on the PATH. The path to awk/gawk is also
    echo not set in the batch file, %0
) else (
    echo Perl and awk are not installed on the PATH, and
    echo they are also not set in the batch file, %0
)
echo.
echo Current PATH is:
path
echo.
echo Path to perl (not found!): %EN_PATH_TO_PERL%
echo Path to awk (not found!) : %EN_PATH_TO_AWK%
echo.
echo To fix this problem, make sure perl or awk are installed and
echo edit %0 to give
echo the correct path to perl.exe or awk.exe (at least one).
echo Quitting here ...

:end
set ENDNT_EXE=
set EN_AWK_SCRIPT=
set EN_COMMANDLINE=
set EN_PATH_TO_AWK=
set EN_PATH_TO_PERL=
set EN_PERL_SCRIPT=
set EN_REQUIRE=
set EN_SCRIPT=
echo DIAG FINAL:
set EN
exit /b
