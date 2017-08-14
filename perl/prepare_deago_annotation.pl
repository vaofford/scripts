#!/usr/bin/env perl

=head1 NAME

prepare_deago_annotation

=head1 SYNOPSIS

prepare_deago_annotation.pl

=head1 DESCRIPTION

Take in a delimited file of gene names and/or go terms and 
convert for use with the RNA-Seq expression analysis 
pipeline (DEAGO)

=head1 CONTACT

path-help@sanger.ac.uk

=head1 METHODS

=cut

use strict;
use warnings;
no warnings 'uninitialized';
use Getopt::Long;
use File::Basename;
use Cwd;

my($annotation_file, $delimiter, $output_directory, $help);

GetOptions(
    'a|annotation=s'    => \$annotation_file,
    'd|delimiter=s'			=> \$delimiter,  
    'o|outdir=s'				=> \$output_directory,
    'h|help'            => \$help,
);

!$help or die <<USAGE;


Usage: $0
  -a|annotation					annotation file <Required>
  -d|delimiter 					column delimiter <default: tab ("\t")>
  -o|outdir           	output directory <default: current working directory>
  -h|help           		print usage
  
Converts a tab-delimited file (e.g. from BioMart) for use with 
the RNA-Seq expression analysis pipeline (DEAGO).  Output is 
a tab delimited file where each row represents a unique value 
from the first column (assumed to be the gene id for DEAGO). 
Remaining column values from rows sharing the same unique 
identifier are collapsed and semi-colon separated (;).

Example input file contents:

Gene stable ID	Gene	GO term accession
Smp_000080	gene1	GO:0016020
Smp_000080	gene2	GO:0016021
Smp_000080	gene2	GO:0005515
Smp_000090	gene1	
Smp_000100	gene1	GO:0051015
Smp_000100	gene1	GO:0005515
Smp_000110              GO:0005515

Example output file contents:

Gene stable ID	Gene	GO term accession
Smp_000080	gene1;gene2	GO:0016020;GO:0005515;GO:0016021
Smp_000090	gene1
Smp_000100	gene1	GO:0051015;GO:0005515
Smp_000110		GO:0005515

Example command:

prepare_deago_annotation.pl -a my_annotation_file

USAGE

unless ( -e $annotation_file )
{
    die "Cannot find annotation file: $annotation_file \n";
}

if (!defined $delimiter || $delimiter eq '') 
{
	$delimiter = "\t";
}

my $output_file = fileparse($annotation_file, qr/\.[^.]*/) . "_deago.tsv";
if (defined $output_directory && -d $output_directory) 
{
	$output_directory =~ s/\/$//;
	$output_file = $output_directory . "/" . $output_file;
} else {
	my $current_directory = getcwd();
	$output_file = $current_directory . "/" . $output_file;
}

my %annotations;
open(my $ANN_FILE, '<', $annotation_file) or die "Cannot open $annotation_file $!\n";
while(<$ANN_FILE>)
{
	chomp;
	my $line  = $_;
	my ($identifier, @data) = map { $_ eq '' ? 'undefined_value' : $_ } split /$delimiter/, $_, -1; 

	if (scalar(@data) < 1)
	{
		 die "Could not convert annotation, only found one column. Check delimiter.\n";
	}

	for (my $i=0; $i < scalar(@data); $i++)
	{
		if (!exists $annotations{$identifier}{$i}{$data[$i]})
		{
			$annotations{$identifier}{$i}{$data[$i]} = 1;
		}
	}
}
close($ANN_FILE);

print "Writing converted annotation to: " . $output_file . "\n";
open(my $OUT_FILE, '>', $output_file) or die "Cannot open $output_file $!\n";
foreach my $identifier (sort keys %annotations)
{
	my $line=$identifier;
	foreach my $column (sort keys %{$annotations{$identifier}})
	{
		 $line .= "\t" . join(";", keys %{$annotations{$identifier}{$column}});
	}

	$line =~ s/undefined_value//g;
	print $OUT_FILE $line . "\n";
}
close($OUT_FILE);

