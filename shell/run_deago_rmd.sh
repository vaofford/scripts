#!/bin/bash

#########################################
#               CONFIGURATION           #
#########################################

export PATH=/software/R-3.4.0/bin:/software/pathogen/external/apps/usr/local/pandoc-1.19.2.1:$PATH
export R_LIBS=~/deago_rlibs 
export R_LIBS_USER=~/deago_rlibs

#########################################
#               USAGE                   #
#########################################

usage="
Run R Markdown file for deago analysis

  Usage : $0 -h (for help)

  Required :-
    i <input file>    : path to R Markdown file (.Rmd)
    o <output file>   : output HTML file (.html)
    d <output folder> : path to output directory
"

#########################################
#               OPTIONS                 #
#########################################

OPTIND=0
while getopts "hi:o:d:" option;
do
        case "$option" in
                h)  echo "$usage" >&2
                        exit 1
                        ;;
                i)  rmd_file="$OPTARG"
                        ;;
                o)  out_file="$OPTARG"
                        ;;
                d)  out_dir="$OPTARG"
                        ;;
                *)  echo "$usage" >&2
                        exit 1
                        ;;
        esac
done
shift $[ $OPTIND - 1 ]

if [ -z "$rmd_file" ] || [ -z "$out_file" ] || [ -z "$out_dir" ];
then
        echo "$usage" >&2
        exit 1
fi

if [ ! -d $out_dir ] 
then
    echo "Output directory does not exist: "$out_dir && exit 1
fi

if [ ! -f $rmd_file ]
then
    echo "R markdown file does not exist: "$rmd_file && exit 1
fi

Rscript -e 'library(knitr)' -e 'library(markdown)' -e 'library(rmarkdown)' -e "rmarkdown::render('$rmd_file', output_file='$out_file', output_dir='$out_dir')"




