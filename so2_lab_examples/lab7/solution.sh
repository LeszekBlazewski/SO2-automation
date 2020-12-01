#!/bin/bash

wget -q https://datko.pl/SO2/kant.txt

awk '
    BEGIN { 
        email_regex="[[:alnum:]_.]+@[[:alnum:]_]+[.][[:alnum:]]+"
        OFS="\n"
    }
    //{
        while (match($0, email_regex)) 
        {
            print substr($0, RSTART, RLENGTH)
            $0=substr($0, RSTART+RLENGTH)
        }
    }
' kant.txt
