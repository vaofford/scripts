#!/bin/bash

outfile="data_summary.txt"
filetype="spreadsheet"
declare -A ALLOWED_TYPES=( [file]=1 [study]=1 )
declare -A ALLOWED_FILETYPES=( [bam]=1 [coverage]=1 [featurecounts]=1 [intergenic]=1 [spreadsheet]=1 )

usage="
Combine pf info, data and rnaseq featurecounts file information when given a study id or file containing a list of lanes

 Usage : $0 -h (for help)
    or : $0 -t <pf type> -i <pf id>

Required :-

  t <pf type>     	   : possible values [study, file]
  i <pf id>       	   : study id (if -t study) or file location (if -t file)

Optional :-

  o <output file>          : output filename
  f <pf rnaseq filetype>   : possible values [bam, coverage, featurecounts, intergenic, spreadsheet]
			     default [spreadsheet]
" 

OPTIND=0

while getopts ":ht:i:o:f:" option; do
  case "$option" in
    h)  echo "$usage" >&2
        exit 1
        ;;

    t)  pf_type="$OPTARG"
        ;;

    i)  pf_id="$OPTARG"
        ;;

    o)  case "$OPTARG" in
        *) outfile="${OPTARG%/*}"
           ;;
        esac
        ;;
    f)  case "$OPTARG" in
        *) filetype="${OPTARG%/*}"
           ;;
        esac
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    *)
        usage
        ;;
  esac
done

shift $[ $OPTIND - 1 ]

# Check that there are no extra arguments
if [ $# -ne 0 ]
  then
    echo "$usage"
    exit 1
fi

# Check that arguments are given
if [ -z "$pf_type" ]
then
   echo "$usage"
   exit
fi

if [ -z "$filetype" ] || [ -z ${ALLOWED_FILETYPES[$filetype]} ]
then
   filetype='spreadsheet'
fi

# Check that type is file or study
if [ -z ${ALLOWED_TYPES[$pf_type]} ]
then
	echo "-t must be either study or file"
	exit 1
fi

# If type is a file, check the file given for id exists
if [ $pf_type == "file" ]
then
	if [ ! -e $pf_id ]
	then
		echo "File does not exist: "$pf_id
		exit 1
	fi
fi

# Get output from pf info 
pf_info=`pf info -t $pf_type -i $pf_id | awk -F '[[:space:]][[:space:]]+' 'BEGIN{OFS="\t"}; {print $1,$2,$3,$4,$5}'`
if [[ `echo "$pf_info" | wc -l` -eq 1 ]]
then
	echo "ERROR: No information found with pf info."
	exit 1
fi 

# Get output from pf rnaseq
pf_rnaseq=`pf rnaseq -t $pf_type -i $pf_id -f $filetype| awk -F "/" 'BEGIN{print "Lane\tFullPath\tFilename"}; {fn=$16"."$17; print $16"\t"$0"\t"fn}'`

# Join and write output to file
join -a1 -a2 -t $'\t' -o 0 1.2 1.3 1.4 1.5 2.3 2.2 -e 'NA' <(echo "$pf_info") <(echo "$pf_rnaseq") > $outfile
