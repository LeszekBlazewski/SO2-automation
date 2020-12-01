#!/bin/bash

directory=$1
requested_size=$2

find "$directory" \
     -size +"$requested_size"M \
     -readable \
     -writable \
     ! -executable \
     -print
