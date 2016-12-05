#!/usr/bin/perl
 use MidiUtils;
 use strict;
 use warnings;
 #use Data::Dumper;
 
unless (defined $ARGV[0])
{croak "Please provide filename of token file as first argument"}

unless (-f $ARGV[0])
{croak "Could not find provided token file"}

unless (defined $ARGV[1])
{croak "Please provide value for n as second argument"}

unless ($ARGV[1] =~/^\s*[\+\-]?\d+\s*$/ && $ARGV[1] > 0)
{croak "n must be a positive integer"}

my $filename = $ARGV[0];
my $n = $ARGV[1];

#read tokens from file into array
my @tokens = &ReadTokensFromFile($filename);

my @ngrams;

#turn token array into n-gram array, skip if n=1 (unigrams)
if ($n > 1)
{
	@ngrams = &TokensToNgrams(\@tokens,$n);
}
else
{
	@ngrams = @tokens;
}


#print occurences with normalized frequency

my $numTokens = scalar @ngrams;

my %occurences = &CountOccurences(\@ngrams);

my $normFrequency;

print "*Number-of-Occurences Normalized-Frequency Ngram\n";

foreach my $ngram (sort { $occurences{$b} <=> $occurences{$a} } keys %occurences) {
	$normFrequency = $occurences{$ngram}/$numTokens;
    printf "$occurences{$ngram} %.5f $ngram\n" , $normFrequency;
}