#!/bin/bash
#This file is a modified version of accuracy_test.sh which is used
# to determine, from the songs sung by both, which was written in
# who's style 

readonly IDENTITY_TOKEN_FILE=../Tokens/identitytokens.txt
readonly IDENTITY_PROFILE_FILE=../Profiles/identityprofile.txt
readonly MCCARTNEY_PROFILE_FILE=../Profiles/McCartneyprofile.txt
readonly LENNON_PROFILE_FILE=../Profiles/Lennonprofile.txt
readonly OUTPUT_FILE=../../doc/identityoutput.txt

#Profile lengths to test at
pLengthArray=(1500)

cd Perl_Scripts
#Clear or create the output file
> ${OUTPUT_FILE}
#Create an array of filenames from the three folders of midi files
cd midi_files/McCartney
mSongs=($(ls *.mid))
cd ../Lennon
lSongs=($(ls *.mid))
cd ../Both
bSongs=($(ls *.mid))
cd ../..

#folder path must be appended for perl script to find the files
for (( i=0; i<${#mSongs[@]}; i++ ));
do
  	mSongs[$i]="McCartney/${mSongs[$i]}"
done

for (( i=0; i<${#lSongs[@]}; i++ ));
do
  	lSongs[$i]="Lennon/${lSongs[$i]}"
done

for (( i=0; i<${#bSongs[@]}; i++ ));
do
  	bSongs[$i]="Both/${bSongs[$i]}"
done

#Creates a comma seperated string from the filenames, same as run.sh
mcCartneySongsString=''
for (( i=0; i<${#mSongs[@]}; i++ ));
do
	if [ $i -gt 0 ]
	then
		mcCartneySongsString+=","
	fi
  	mcCartneySongsString+=${mSongs[$i]}
done

lennonSongsString=''
for (( i=0; i<${#lSongs[@]}; i++ ));
do
	if [ $i -gt 0 ]
	then
		lennonSongsString+=","
	fi
  	lennonSongsString+=${lSongs[$i]}
done
#only n=3
for (( n=3; n<4; n++ )); 
do
	echo "n: ${n}"
	echo "n: ${n}" >> ${OUTPUT_FILE}

	#Creates tokens, then profiles, for the entire folder of midi files for each artist
	#This takes a while! Must only do once per value of n!
	#echo "Creating Big Profile files..."
	#echo "McCartney..."
	perl midi_to_tokens.pl ${mcCartneySongsString} > ${IDENTITY_TOKEN_FILE}

	perl tokens_to_profile.pl ${IDENTITY_TOKEN_FILE} ${n} > ${MCCARTNEY_PROFILE_FILE}

	#echo "Lennon..."
	perl midi_to_tokens.pl ${lennonSongsString} > ${IDENTITY_TOKEN_FILE}

	perl tokens_to_profile.pl ${IDENTITY_TOKEN_FILE} ${n} > ${LENNON_PROFILE_FILE}

	#echo "Done"

	for plength in "${pLengthArray[@]}"
	do
		echo "Profile Length: ${plength}"
		echo "Profile Length: ${plength}" >> ${OUTPUT_FILE}

		#for each song to identify...
		for (( i=0; i<${#bSongs[@]}; i++ ));
		do
			#create it's tokens, then it's profile...
			perl midi_to_tokens.pl ${bSongs[$i]} > ${IDENTITY_TOKEN_FILE}

			perl tokens_to_profile.pl ${IDENTITY_TOKEN_FILE} ${n} > ${IDENTITY_PROFILE_FILE}
			
			#calculate it's similarity to the entire group of McCartney songs
			mSim=`perl dissimilarity.pl ${IDENTITY_PROFILE_FILE} ${MCCARTNEY_PROFILE_FILE} ${plength}`
			#calculate it's similarity to the entire group of Lennon songs
			lSim=`perl dissimilarity.pl ${IDENTITY_PROFILE_FILE} ${LENNON_PROFILE_FILE} ${plength}`
		
			#Which is more similar?
			if (( $(echo "$mSim < $lSim" |bc -l) )); #bc -l is needed to work with decimal numbers in bash
			then
				echo "${bSongs[$i]} looks like a McCartney song!"
				echo "${bSongs[$i]} looks like a McCartney song!" >> ${OUTPUT_FILE}
			else
				echo "${bSongs[$i]} looks like a Lennon song!"
				echo "${bSongs[$i]} looks like a Lennon song!" >> ${OUTPUT_FILE}
			fi
		done
	done
done
