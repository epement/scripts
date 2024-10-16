#n
# NOTE: "#n" on the top line causes this script to work like -n
#
# filename: KPM-to-LastPass-CSV.sed
#  updated: 2024-10-16 01:36:24 (UTC-0400)
#  version: 1
#
# GNU sed script to convert text exported from Kaspersky Password Manager
# into a CSV file for import into LastPass. Kaspersky PM does not have a
# native "export-to-csv" function; it exports to a record-jar text file.
#
v;  # cause the script to fail unless this is GNU sed
#
# Notes:
# (1) KPM exports 6 fields. Fields are exported one per line, except for
# the 6th, which often has multiple lines. See sample below.
# (2) The 3rd field ("Login name") from KPM always exports blank.
#
# Conversion to CSV actions:
# (1) If any field contains "double quotes", each quote mark is doubled.
# Then the whole field is wrapped in double quotes.
# (2) If any field contains a space or comma, the whole field is wrapped
# in double quotes.
# (3) If field #6 contains more than one line, the whole field is wrapped
# in double quotes.
# (4) Care is taken to avoid wrapping a field in quote marks twice.
# (5) Apostrophe or single quotes do not need special treatment.
# (6) Otherwise, output fields are not quoted.
#
# SYNTAX:
#   sed -rnf KPM-to-LastPass-CSV.sed kaspersky-exported.txt > file.csv
#
#### Sample password file entry exported from Kaspersky PM ####
#
# Website name: Facebook                F1
# Website URL: https://facebook.com     F2
# Login name:                           F3 = void
# Login: john-smith                     F4
# Password: MyPa55w0rd                  F5
# Comment: May have 2 or more lines.  ( F6
# May append additional lines ...       F6 )
#                                     (blank line)
# ---                                 (3 hyphens)
# 
#### Sample CSV format needed by LastPass ####
# https://facebook.com,john-smith,MyPa55w0rd,"May have 2 or more lines.
# May append additional lines ...",Facebook,,,
#
#### LastPass field headers described ####
# url:      Web address, not necessarily unique       F2
# username: String to enter at the LOGIN prompt       F4
# password: String to enter at the PASSWORD prompt    F5
# extra:    Comments and notes may include newlines   F6
# name:     Name for this entry; embedded spaces OK   F1
# grouping: Category (eg: Home, School, Work, etc.)   void
# fav:      1 = favorite, null = not a favorite       void
# totp:     Temporary One-Time Password               void
#######################

# Insert Field Headers as first line of output
1i\
url,username,password,extra,name,grouping,fav,totp

s/\r//;   # delete possible carriage return

/^Website name:/, /^---$/ {        # define an /address/,/range/
    /^---$/b labelA

    /^Website name:/ {
        s/^Website name: */F1=/;   # Field 1 often has spaces
        /"/ {
            s|"|""|g;              # double existing quotes
            s/^F1=(.*)/F1="\1"/;   # wrap the field, but not twice
            t label1
        }
        /[ ,]/s/^F1=(.*)/F1="\1"/; # wrap if spaces or commas
        : label1
        h;                         # overwrite hold space
        d;
    }

    /^Website URL:/ {
        s/^Website URL: */F2=/;    # Field 2 never has space,comma,quote
        H;                         # append to hold space
        d;
    }

    /^Login name:/ {               # Field 3 is not used on export
        s/^Login name: */F3=/;
        H;                         # append to hold space
        d;
    }

    /^Login:/ {                    # Field 4 may have space or comma
        s/^Login: */F4=/;
        /[ ,]/s/^F4=(.*)/F4="\1"/; # wrap if spaces or commas found
        H;                         # append to hold space
        d;
    }

    /^Password:/ {                 # Field 5 may have space,comma,quote
        s/^Password: */F5=/;
        /"/ {
            s|"|""|g;              # double existing quotes
            s/^F5=(.*)/F5="\1"/;   # wrap the field, but not twice
            t label2
        }
       /[ ,]/s/^F5=(.*)/F5="\1"/;  # wrap if spaces or commas
       : label2
       H;                          # append to hold space
       d;
    }

    /^Comment:/ {                  # Field 6 usually has space,comma,quote
        s/^Comment: */F6=/;
        /"/ s|"|""|g;              # double existing quotes
        H;                         # append to hold space
        d;
    }

    /^ *$/ D;                      # delete blank lines

    /./ {                          # All other lines are comment lines, so
        /"/ s|"|""|g;              # double existing quotes
        H;                         # append to hold space
    }
}

:labelA
/^---$/ {
  z;   # empty the pattern space
  x;   # swap hold space and pattern space

  # test for minimum 6 required fields in this order:
  /F1=/!       b error1
  /F1=.*F2=/!  b error2
  /F2=.*F3=/!  b error3
  /F3=.*F4=/!  b error4
  /F4=.*F5=/!  b error5
  /F5=.*F6=/!  b error6
  # We now have 6 (or more) lines in the buffer.

  # Rearrange numbered fields 1-6 into (2,4,5,6,1) plus 3 empty fields.
  # Wrap the Notes/Comments field in \v (vert tab) for analysis. It is
  # very, very unlikely that \v will be input file.
  #    (site)   (url)   (void)   (login)   (pass)   (notes)
  s|^F1=(.*)\nF2=(.*)\nF3=(.*)\nF4=(.*)\nF5=(.*)\nF6=(.*)$|\2,\4,\5,\v\6\v,\1,,,|;

  /\v\v/ {   # If nothing is between the 2 VT anchors,
     s|^(.*,)\v\v(,.*)$|\1\2|;   # .. delete them
  }

  /\v[[:print:]].*\v/ {   # Else, some text is between the VT anchors,
     s|\v|"|g;            # .. so change then to quotes
  }

  p;         # print the modified record
}
b

:error1
a\
  ERROR: Missing field: "Website name:"
  b

:error2
a\
  ERROR: Missing field: "Website URL:"
  b

:error3
a\
  ERROR: Missing field: "Login name"
  b

:error4
a\
  ERROR: Missing field: "Login:"
  b

:error5
a\
  ERROR: Missing field: "Password:"
  b

:error6
a\
  ERROR: Missing field: "Comment:"

# EOF
