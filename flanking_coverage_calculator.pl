#!/usr/bin/env perl
# flanking_coverage_calculator.pl
# Mike Covington
# created: 2011-12-11
#
# Description: 
#
use strict;
use warnings;
use autodie;
use feature 'say';
use File::Basename;
use Getopt::Long;

#TODO: gap and nogap one at a time to cut down on memory requirements

my $usage = <<USAGE_END;

USAGE:
flanking_coverage_calculator.pl
  --snp_file   </PATH/TO/snp_file.csv>
  --cov_prefix </PATH/TO/cov_file_prefix_only -- w/o .cov_(no)gap>
  --flank_dist <flanking distance to use [8]>
  --help

USAGE_END

#get options
my ( $snp_in, $cov_prefix, $help );
my $flank_dist = 8;    # default
my $options = GetOptions(
    "snp_file=s"   => \$snp_in,
    "cov_prefix=s" => \$cov_prefix,
    "flank_dist=i" => \$flank_dist,
    "help"         => \$help,
);
die $usage if $help;
die $usage unless defined $snp_in && defined $cov_prefix;

#generate filenames
my ( $cov_nogaps_file, $cov_gaps_file ) = ( $cov_prefix ) x 2 ;
$cov_nogaps_file .= ".cov_nogaps";
$cov_gaps_file   .= ".cov_gaps";
my ( $filename, $directories, $suffix ) = fileparse( $snp_in, ".csv" );
my $snp_out = $directories . $filename . ".nogap.gap.csv";

#open files
open my $snp_in_fh,     "<", $snp_in;
open my $snp_out_fh,    ">", $snp_out;
open my $cov_nogaps_fh, "<", $cov_nogaps_file;
open my $cov_gaps_fh,   "<", $cov_gaps_file;

#build coverage hashes
my ( %nogaps, %gaps );
%nogaps = map { chomp; @{ [ split /\t/ ] }[ 1 .. 2 ] } <$cov_nogaps_fh>;
%gaps   = map { chomp; @{ [ split /\t/ ] }[ 1 .. 2 ] } <$cov_gaps_fh>;

#write header
my $header = <$snp_in_fh>;
chomp $header;
say $snp_out_fh join( ",",
    $header,
    "nogap_pos-$flank_dist", "nogap_pos", "nogap_pos+$flank_dist",
    "gap_pos-$flank_dist",   "gap_pos",   "gap_pos+$flank_dist" );

#write coverage
while ( my $snp_line = <$snp_in_fh> ) {
    chomp $snp_line;
    my ( $snp_chr, $snp_pos_unsplit, $snp_remainder ) = split( /,/, $snp_line, 3 );
    my ( $snp_pos, $snp_pos_index ) = split( /\./, $snp_pos_unsplit );

    my ( $del_cov ) = ${ [ split /,/, $snp_remainder ] }[5];    #nogaps doesn't see deletions, must compensate

    my $lt_pos = $snp_pos - $flank_dist;
    my $rt_pos = $snp_pos + $flank_dist;

    say $snp_out_fh join( ",",
        $snp_chr,                $snp_pos_unsplit,         $snp_remainder,
        $nogaps{ $lt_pos } || 0, $nogaps{ $snp_pos } + $del_cov || 0, $nogaps{ $rt_pos } || 0,
        $gaps{ $lt_pos }   || 0, $gaps{ $snp_pos }              || 0, $gaps{ $rt_pos }   || 0 );
}

#close shop
close $snp_in_fh;
close $cov_nogaps_fh;
close $cov_gaps_fh;
close $snp_out_fh;
exit;