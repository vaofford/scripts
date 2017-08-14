#!/bin/bash

# This script can be used to check that reference FASTA headers are in the same order as sort -d -k1,1
# Takes a reference index (e.g. refs.index) as input and outputs references which are not sort -d -k1,1 ordered

# Check that a file is given
if [ $# -eq 0 ]
  then
    echo "No file supplied."
    exit 1
elif [ $# -gt 1 ]
  then
    echo "Too many arguments supplied"
    exit 1
fi

# Check that the index file exists
if [ ! -f $1 ]
  then
    echo "File does not exist: "$1
    exit 1
fi

ref_idx=$1

function check_ref_order () 
{
  ref_file=$1
  if ! diff <(less $ref_file | grep '>') <(less $ref_file | grep '>' | sort -d -k1,1) >/dev/null ; then
    printf $ref_file"\n"
  fi
}
export -f check_ref_order
awk '{print $2}' $ref_idx | xargs -L 1 -I{} bash -c "check_ref_order {}"

