#!/bin/bash
#This file contains code for comparing midi files to test whether their musical content is similar
#It can accept single file names with the correct path in reference to the MIDI_FILES_DIRECTORY,
# or it can accept full directories inside of the MIDI_FILES_DIRECTORY
#NOTE:Calculation is DISS-imilarity, meaning larger numbers indicate that files are LESS similar
readonly TOKEN_FILE_1=../Tokens/file1tokens.txt
readonly TOKEN_FILE_2=../Tokens/file2tokens.txt
readonly PROFILE_FILE_1=../Profiles/file1profile.txt
readonly PROFILE_FILE_2=../Profiles/file2profile.txt
readonly MIDI_FILES_DIRECTORY=midi_files

#The string entered by the user
filename=''
#Arrays of filenames that have been validated
filegroup1=()
filegroup2=()
#Size of the filegroup array that is currently being populated
fileCount=0
#n value entered by user
n=0
#profile length value entered by user
plength=''

#All code is written to run from this directory
cd Perl_Scripts

while :
do
	#Display instructions
	echo "Please enter a single midi file name or a directory within $MIDI_FILES_DIRECTORY directory"
	echo '- To clear collection, type "clear"'
	echo '- To quit, type "quit"'
	echo '- To finish selecting, type "done"'
	read -p '>' filename 

	#Trim any white spaces from the input
	#https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
	filename="$(echo -e "${filename}" | tr -d '[:space:]')"
	
	#Keep the display neat
	clear
	#Cases for quiting, finishing selection, and clearing selection
	if [ $filename == 'quit' ]
	then
		exit
	elif [ $filename == 'done' ]
	then
		break
	elif [ $filename == 'clear' ]
	then
		filegroup1=()
		fileCount=0
	#case for full directory
	elif [ -d "${MIDI_FILES_DIRECTORY}/$filename" ]
	then
		#go into the directory
		cd "${MIDI_FILES_DIRECTORY}/$filename"
		#make array of all files with the .mid extension
		filearray=($(ls *.mid))
		for (( i=0; i<${#filearray[@]}; i++ ));
		do
			#if the file exists on disk
			if [ -f "${filearray[$i]}" ]
			then
				#add file to array and increment fileCount
				filegroup1[${fileCount}]="$filename/${filearray[$i]}"
				let fileCount="$fileCount + 1"
			fi
		done
		#get back to Perl_Scripts
		cd ../..
	#case for file with extension
	elif [[ "${MIDI_FILES_DIRECTORY}/$filename" == *.mid ]]
	then
		if [ -f "${MIDI_FILES_DIRECTORY}/$filename" ]
		then
			filegroup1[${fileCount}]=${filename}
			let fileCount="$fileCount + 1"
		fi
	#case for file without extension
	elif [ -f "${MIDI_FILES_DIRECTORY}/$filename.mid" ]
	then
		filegroup1[${fileCount}]=${filename}.mid
		let fileCount="$fileCount + 1"
	else
		echo "Invalid file or directory. Please enter files with the .mid extension or directories without spaces"
	fi

	echo "$fileCount midi files selected."
	#Display selected files
	for (( i=0; i<${#filegroup1[@]}; i++ ));
	do
		echo ${filegroup1[$i]}
	done
	filename=''
	
done

#Can't continue if nothing was selected
if [ $fileCount == 0 ]
then
	echo "File collection 1 was empty"; exit 
fi

#reset the count of files
fileCount=0
#clean terminal
clear
#Same process for second selection
while :
do
	echo "Please enter a single midi file name or a directory within ${MIDI_FILES_DIRECTORY} directory"
	echo '- To clear collection, type "clear"'
	echo '- To quit, type "quit"'
	echo '- To finish selecting, type "done"'
	read -p '>' filename 
	
	#Trim any white spaces from the input
	#https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
	filename="$(echo -e "${filename}" | tr -d '[:space:]')"
	
	clear
	if [ $filename == 'quit' ]
	then
		exit
	elif [ $filename == 'done' ]
	then
		break
	elif [ $filename == 'clear' ]
	then
		filegroup2=()
		fileCount=0
	elif [ -d "${MIDI_FILES_DIRECTORY}/$filename" ]
	then
		cd "${MIDI_FILES_DIRECTORY}/$filename"
		filearray=($(ls *.mid))
		for (( i=0; i<${#filearray[@]}; i++ ));
		do
			filegroup2[${fileCount}]="$filename/${filearray[$i]}"
			let fileCount="$fileCount + 1"
		done
		cd ../..
	elif [[ "${MIDI_FILES_DIRECTORY}/$filename" == *.mid ]]
	then
		if [ -f "${MIDI_FILES_DIRECTORY}/$filename" ]
		then
			filegroup2[${fileCount}]=${filename}
			let fileCount="$fileCount + 1"
		fi
	elif [ -f "${MIDI_FILES_DIRECTORY}/$filename.mid" ]
	then
		filegroup2[${fileCount}]=${filename}.mid
		let fileCount="$fileCount + 1"
	else
		echo "Invalid file or directory. Please enter files with the .mid extension or directories without spaces"
	fi
	

	echo "$fileCount midi files selected."
	for (( i=0; i<${#filegroup2[@]}; i++ ));
	do
		echo ${filegroup2[$i]}
	done
	filename=''
	
done

if [ $fileCount == 0 ]
then
	echo "File collection 2 was empty"; exit 
fi

#Display both file groupings
#Create comma-seperated string for each collection to be passed to perl
echo "First Collection:"

collection1String=''
for (( i=0; i<${#filegroup1[@]}; i++ ));
do
	if [ $i -gt 0 ]
	then
		collection1String+=","
	fi
  	collection1String+=${filegroup1[$i]}
	echo ${filegroup1[$i]}
done

echo "Second Collection:"

collection2String=''
for (( i=0; i<${#filegroup2[@]}; i++ ));
do
	if [ $i -gt 0 ]
	then
		collection2String+=","
	fi
  	collection2String+=${filegroup2[$i]}
	echo ${filegroup2[$i]}
done

#Entry and validation for n and profile length
while :
do
	read -p 'Please enter a value for n: ' n
	if [[ $n =~ ^[1-9]$ ]]
	then
		break
	elif [ $n == 'quit' ]
	then
		exit
	fi
done

while :
do
	read -p 'Please enter desired profile length: ' plength
	if [[ $plength =~ ^[0-9]+$ ]] && [ $plength -gt 0 ]
	then
		break
	elif [ $n == 'quit' ]
	then
		exit
	fi
done

#Creates tokens from the midi file(s) selected and prints them to file
echo Printing collection 1 tokens to ${TOKEN_FILE_1}...
touch ${TOKEN_FILE_1}
perl midi_to_tokens.pl ${collection1String} > ${TOKEN_FILE_1}

echo Printing collection 2 tokens to ${TOKEN_FILE_2}...
touch ${TOKEN_FILE_2}
perl midi_to_tokens.pl ${collection2String} > ${TOKEN_FILE_2}

#Creates profile (hash of occurences) from those tokens and prints that to file
echo Printing $file1 profile to ${PROFILE_FILE_1}...
touch ${PROFILE_FILE_1}
perl tokens_to_profile.pl ${TOKEN_FILE_1} ${n} > ${PROFILE_FILE_1}

echo Printing $file2 profile to ${PROFILE_FILE_2}...
touch ${PROFILE_FILE_2}
perl tokens_to_profile.pl ${TOKEN_FILE_2} ${n} > ${PROFILE_FILE_2}

#Runs dissimilarity method 
echo Calculating resulting dissimilarity...
dissimilarity=`perl dissimilarity.pl ${PROFILE_FILE_1} ${PROFILE_FILE_2} ${plength}`
echo "Dissimilarity: ${dissimilarity}"












