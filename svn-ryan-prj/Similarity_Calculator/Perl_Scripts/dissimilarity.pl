#!/usr/bin/perl
#Simply prints the result of the CalcDissimilarity function
 use strict;
 use warnings;
 use MyUtils;
 
 unless (defined $ARGV[0])
 {die "Please provide filename of profile file as first argument";}
 
 unless (defined $ARGV[1])
 {die "Please provide filename of profile file as second argument";}
 
 unless (defined $ARGV[2])
 {die "Please provide profile length as third argument";}
 
 print CalcDissimilarity($ARGV[0],$ARGV[1],$ARGV[2]);