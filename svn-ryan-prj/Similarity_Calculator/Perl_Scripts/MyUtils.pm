#!/usr/bin/perl
#Contains the vast majority of functions for this project
 use strict;
 use warnings;
 use Carp;
 use constant MIDI_FILES_DIRECTORY => "midi_files";
# use Data::Dumper;
 
#Tests whether the given string has the right extension and checks if it exists on disk
 sub IsMIDIFile
 {
	return 0 unless (ref(\$_[0]) eq "SCALAR" && 
	substr($_[0], -4) eq ".mid" &&
    -f MIDI_FILES_DIRECTORY."/".$_[0]);
	return 1;
 }
 
#Takes pointer to array of tokens and creates ngrams according to the value of n
sub TokensToNgrams
{
	unless (defined $_[0] && ref($_[0]) eq "ARRAY")
	{croak "Please provide array of tokens as first argument"}
	
	unless (defined $_[1] && $_[1] =~/^\s*[\+\-]?\d+\s*$/ && $_[1] > 0)
	{croak "Please provide value of n (positive integer) as second argument"}
	
	my $ref_token_array = $_[0];
	
	my $n = $_[1];
	
	my @ngramArray;
	
	my $ngramString = "";
	
	for (my $x = 0; $x < (scalar @$ref_token_array - ($n-1)); $x++)
	{
		for(my $y = 0; $y < $n; $y++)
		{
			if ($y == ($n-1))
			{
				$ngramString.= @$ref_token_array[$x + $y];
			}
			else
			{
				$ngramString.= @$ref_token_array[$x + $y].",";
			}
		}
		push(@ngramArray,"($ngramString)");
		$ngramString = "";
	}
	return @ngramArray;	
}
 
#Reads given token file line by line and creates an array of tokens from it
sub ReadTokensFromFile
{
	unless (defined $_[0])
	{croak "Please provide filename of token file as first argument"}
	
	unless (ref(\$_[0]) eq "SCALAR" &&-f $_[0])
	{croak "Token file not found"}
	
	my $filename = shift;
		
	open(my $fh, '<:encoding(UTF-8)', $filename);

	my @tokenArray;
	my @rowTokens;
	while (my $row = <$fh>)
	{
		unless (length($row) <= 1 or ((substr $row, 0,1) eq '*'))
		{
			@rowTokens = split ' ', $row;
			push(@tokenArray, @rowTokens);
		}
	}
	close $fh;
	return @tokenArray;
}


#Couldn't find any built-in round functions installed...casting to int acts like floor function
sub round 
{
	return int($_[0] + 0.5);
}

#Takes a pointer to an array, counts occurences of values within the array, and returns a hash of "value => occurence count"
sub CountOccurences
{
	unless (ref $_[0] eq "ARRAY")
	{croak "Please provide an array as a first argument.\n";}

	my $ref_Array = shift;

	my %counter;
	
	foreach my $value (@$ref_Array)
	{
		#If value has been seen before, add to it's occurences
		if (exists $counter{$value})
		{
			$counter{$value}++;
		}
		else #else start its count at 1
		{
			$counter{$value} = 1;
		}
	}

	return %counter;
}

#Takes a pointer to an array of strings, and formats it into a multi-line string with maximum line character length provided
sub ArrayToOutputString
{
	unless (ref $_[0] eq "ARRAY")
	{croak "Please provide an array as a first argument.\n"; return;}
	
	unless (defined $_[1] && $_[1] =~/^\s*[\+\-]?\d+\s*$/ && $_[1] > 0)
	{croak "Please provide maximum number of characters (positive integer) as a second argument.\n"; return;}
	
	my $ref_Array = $_[0];
	my $maxCharacters = $_[1];
	my $outputString = "";
	my $characterCounter = 0;
	
	foreach my $value(@$ref_Array)
	{
		#if adding the value to the string exceeds the maxcharacters, add a new line
		if($characterCounter + length($value) > $maxCharacters)
		{	
			$outputString .= "\n";
			$characterCounter = 0;
		}
		#if adding the value to the string is exactly the maxcharacters, add the value before adding new line
		elsif($characterCounter + length($value) == $maxCharacters)
		{
			$outputString .= $value;
			$outputString .= "\n";
			$characterCounter = 0;
			next;
		}
		$outputString .= "$value ";
		$characterCounter += length($value) +1;
	}
	return $outputString;
}

#Takes the filenames of two profile files and a profile length, and calculates the dissimilarity between the files
sub CalcDissimilarity
{	
	unless (ref(\$_[0]) eq "SCALAR" && -f $_[0])
	{return "Profile file not found"}
		
	unless (ref(\$_[1]) eq "SCALAR" && -f $_[1])
	{return "Profile file not found"}
	
	unless (ref(\$_[2]) eq "SCALAR" && $_[2] =~/^\s*[\+\-]?\d+\s*$/ && $_[2] > 0)
	{return "Please provide appropriate profile length (positive integer) as third argument"}
	 
	my $file1 = $_[0];
	my $file2 = $_[1];
	my $profileLength = $_[2];
	my $dissimilarity = 0;
	 
	#Read profiles from two provided files into hashes of ngram => normFrequency
	my %profile1 = &ReadProfileFromFile($file1, $profileLength);
	my %profile2 = &ReadProfileFromFile($file2, $profileLength);
	
	#if ngram in profile1 exists in profile2, compare their frequencies, 
	#then delete that ngram from profile2 hash
	my $f1 = 0;
	my $f2 = 0;
	
	foreach my $ngram (keys %profile1)
	{
		$f1 = $profile1{$ngram};
		if(exists $profile2{$ngram})
		{
			$f2 = $profile2{$ngram};
		}
		else
		{
			$f2 = 0;	
		}
		$dissimilarity+= (2*($f1-$f2)/($f1 + $f2))**2;
		delete $profile2{$ngram};
	}
	#Walk over profile2 the same way
	foreach my $ngram (keys %profile2)
	{
		$f1 = $profile2{$ngram};
		if(exists $profile1{$ngram})
		{
			$f2 = $profile1{$ngram};
		}
		else
		{
			$f2 = 0;	
		}
		$dissimilarity+= (2*($f1-$f2)/($f1 + $f2))**2;
	}

	return $dissimilarity;
}

#Reads given profile file line by line for length given and creates a hash of 
#"ngram => normalized frequency"
#Ignores occurrence count column
sub ReadProfileFromFile
{	
	unless (defined $_[0])
	{croak "Please provide filename of profile file as first argument"}
	
	unless (ref(\$_[0]) eq "SCALAR" &&-f $_[0])
	{croak "Profile file not found"}
	
	unless (ref(\$_[1]) eq "SCALAR" && $_[1] =~/^\s*[\+\-]?\d+\s*$/ && $_[1] > 0)
	{croak "Please provide profile length as second argument"}
	
	my $filename = shift;
	
	my $profileLength = shift;
	
	open(my $fh, '<:encoding(UTF-8)', $filename);
	
	my @rowvalues;
	my %frequencies;
	my $row;
	for (my $i = 0; $i< $profileLength;)
	{
		unless ($row = <$fh>)
		{
			last;
		}
		unless (length($row) <= 1 or ((substr $row, 0,1) eq '*'))
		{
			@rowvalues = split ' ', $row;
			$frequencies{$rowvalues[2]} = $rowvalues[1];
			$i++;
		}
	}
	close $fh;
	return %frequencies;
}



 
 return 1;
