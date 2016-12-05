#!/usr/bin/perl
#Takes a single midi filename or a comma-seperated list of filenames and prints out tokens for all files
 use MidiUtils;
 use strict;
 use warnings;
 use Data::Dumper;
 use constant MAX_CHARACTERS_IN_LINE => 80;
 
 #First argument can be a single file and won't be affected by split
 my @midiFiles = split ',', $ARGV[0];
 
 foreach my $filename (@midiFiles)
 {
	print &GetTokensForFile($filename);
 }
 