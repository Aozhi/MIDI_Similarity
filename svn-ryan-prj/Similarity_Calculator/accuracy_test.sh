#!/bin/bash
#This file contains a specialized and optimized version of run.sh that
# tests the accuracy of the dissimilarity method
#Test is conducted on an equal proportion of beatles songs,
# 14 songs by McCartney and 14 songs by Lennon
#The total file size of each group of 14 needs to be
# roughly the same so that each group provides a roughly equal amount of tokens

readonly ACCURACY_TOKEN_FILE=../Tokens/accuracytokens.txt
readonly ACCURACY_PROFILE_FILE=../Profiles/accuracyprofile.txt
readonly MCCARTNEY_PROFILE_FILE=../Profiles/McCartneyprofile.txt
readonly LENNON_PROFILE_FILE=../Profiles/Lennonprofile.txt
readonly OUTPUT_FILE=../../doc/accuracyoutput.txt

#Profile lengths to test at
pLengthArray=(100 200 300 400 500 600 700 800 900 1000 1500 2000 2500 3000)

cd Perl_Scripts
#Clear or create the output file
> ${OUTPUT_FILE}
#Create an array of filenames from the two folders of midi files
cd midi_files/McCartney
mSongs=($(ls *.mid))
cd ../Lennon
lSongs=($(ls *.mid))
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

for (( n=1; n<=10; n++ ));
do
	echo "n: ${n}"
	echo "n: ${n}" >> ${OUTPUT_FILE}

	#Creates tokens, then profiles, for the entire folder of midi files for each artist
	#This takes a while! Must only do once per value of n!
	#echo "Creating Big Profile files..."
	#echo "McCartney..."
	perl midi_to_tokens.pl ${mcCartneySongsString} > ${ACCURACY_TOKEN_FILE}

	perl tokens_to_profile.pl ${ACCURACY_TOKEN_FILE} ${n} > ${MCCARTNEY_PROFILE_FILE}

	#echo "Lennon..."
	perl midi_to_tokens.pl ${lennonSongsString} > ${ACCURACY_TOKEN_FILE}

	perl tokens_to_profile.pl ${ACCURACY_TOKEN_FILE} ${n} > ${LENNON_PROFILE_FILE}

	#echo "Done"

	for plength in "${pLengthArray[@]}"
	do
		echo "Profile Length: ${plength}"
		echo "Profile Length: ${plength}" >> ${OUTPUT_FILE}
		#maximum number of correct responses
		maxAcc=$((${#mSongs[@]}+${#lSongs[@]}))
		#actual number of correct responses
		calcAcc=0

		#for each McCartney song...
		for (( i=0; i<${#mSongs[@]}; i++ ));
		do
			#create it's tokens, then it's profile...
			perl midi_to_tokens.pl ${mSongs[$i]} > ${ACCURACY_TOKEN_FILE}

			perl tokens_to_profile.pl ${ACCURACY_TOKEN_FILE} ${n} > ${ACCURACY_PROFILE_FILE}
			
			#calculate it's similarity to the entire group of McCartney songs
			mSim=`perl dissimilarity.pl ${ACCURACY_PROFILE_FILE} ${MCCARTNEY_PROFILE_FILE} ${plength}`
			#calculate it's similarity to the entire group of Lennon songs
			lSim=`perl dissimilarity.pl ${ACCURACY_PROFILE_FILE} ${LENNON_PROFILE_FILE} ${plength}`
		
			#echo "Is $mSim less than $lSim?"
			#if a McCartney song is more similar to the McCartney songs than the Lennon songs, it works!
			#increment accuracy!
			if (( $(echo "$mSim < $lSim" |bc -l) )); #bc -l is needed to work with decimal numbers in bash
			then
				((calcAcc+=1))
			fi
		done
		
		#same process for each Lennon song
		for (( i=0; i<${#lSongs[@]}; i++ ));
		do
			perl midi_to_tokens.pl ${lSongs[$i]} > ${ACCURACY_TOKEN_FILE}

			perl tokens_to_profile.pl ${ACCURACY_TOKEN_FILE} ${n} > ${ACCURACY_PROFILE_FILE}

			mSim=`perl dissimilarity.pl ${ACCURACY_PROFILE_FILE} ${MCCARTNEY_PROFILE_FILE} ${plength}`

			lSim=`perl dissimilarity.pl ${ACCURACY_PROFILE_FILE} ${LENNON_PROFILE_FILE} ${plength}`
		
			#echo "Is $lSim less than $mSim?"

			if (( $(echo "$lSim < $mSim" |bc -l) ));
			then
				((calcAcc+=1))
			fi
		done
		
		#Display accuracy in fraction form
		echo "${calcAcc} / ${maxAcc}"
		echo "${calcAcc} / ${maxAcc}" >> ${OUTPUT_FILE}
		#Display accuracy in percent form
		accuracy=$(echo "${calcAcc} / ${maxAcc} * 100" |bc -l) #more decimal numbers
		printf %.4f ${accuracy}
		echo "%"
		printf "\n"
		printf %.4f ${accuracy} >> ${OUTPUT_FILE}
		echo "%" >> ${OUTPUT_FILE}
		printf "\n" >> ${OUTPUT_FILE}


	done
done
