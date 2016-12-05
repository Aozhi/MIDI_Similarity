#!/usr/bin/perl
#Contains all methods that use the MIDI module by Sean M. Burke
#http://search.cpan.org/~conklin/MIDI-Perl-0.83/lib/MIDI.pm

 use MIDI;
 use MyUtils;
 use Carp;
 use strict;
 use warnings;
 #use Data::Dumper;
 use constant MIDI_FILES_DIRECTORY => "midi_files";
 use constant MAX_CHARACTERS_IN_LINE => 80;

#Takes a midi filename and returns a string formatted for output to text file
sub GetTokensForFile
{
	unless (defined $_[0] and ref \$_[0] eq "SCALAR")
	{croak "Please provide a midi filename as a first argument.\n"; }
	
	unless (&IsMIDIFile($_[0]))
	{croak "File not found.\n"}
	
	my $filename = $_[0];
	my $output = "";
	
	$output.= "*Content of $filename\n";
	
	#Using MIDI module
	my $opus = MIDI::Opus->new({'from_file' => MIDI_FILES_DIRECTORY."/$filename"});
	my @tracks = $opus->tracks;
	my $numTracks = scalar @tracks;

	for(my $i=0;$i<$numTracks;$i++)
	{
		my @trackTokens;
		$output.= "*Track ".($i+1)."\n";
		my $track = $tracks[$i];
		my @events = $track->events;
		#current event index
		my $current = -1;
		
		#seek out the first event with delta time greater that 5 (an actual note)
		#event type is at index 0
		#note length/duration is at index 1(delta time)
		for my $eventNum (0..(scalar @events-1))
		{
			#seek out the first note_on event and set the index 
			if($events[$eventNum][0] eq "note_on" && $events[$eventNum][1] > 5)
			{
				$current = $eventNum;
				last;
			}
		}
		if($current == -1)
		{
			$output.= "*No note_on events found in Track ".($i + 1)."\n";
			next;
		}
		
		#next event index
		my $next = $current+1;
		
		#variable for holding current token
		my $token;
		
		#seek out the next one to compare it to
		for my $eventNum ($next..(scalar @events-1))
		{
			#when the event is a "note_on" event and the delta time is greater than 5..
			if($events[$eventNum][0] eq "note_on" && $events[$eventNum][1] > 5)
			{	
				#pitch is at index 3
				$next = $eventNum;
				$token = ($events[$next][3]-$events[$current][3]).",".
				(&round(log($events[$next][1]/$events[$current][1])/log(2)));
				push(@trackTokens,"(".$token.")") ;
				$current = $next;
			}
		}
		
		$output.= &ArrayToOutputString(\@trackTokens, MAX_CHARACTERS_IN_LINE)."\n";
	}
	return $output;
}


return 1;


