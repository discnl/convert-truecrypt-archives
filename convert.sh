#!/bin/bash
set -e

# Set to true to create a git reposity based on the archives that are
# mentioned below in the TEST_ARCHIVES array.
# If false, create a full repository from the files in ALL_ARCHIVES.
# The script will check for existence of the archive files (in the
# current directory)
TEST=false

TEST_ARCHIVES=(
"TrueCrypt 7.1a Source.tar.gz" "TrueCrypt 7.1a Source.zip"
)


# What to do with EOLs?
# auto :
# Let git handle it automatically.

# mixed :
# Use LF for all files except those that are unique to the ZIP archive.
# The unique files keep CRLF and include these files:
# ./Setup/*
# ./TrueCrypt.sln
# Using mixed mode makes it easier to verify files: all files from a tgz
# should be the same as what's in the repository. The remaining ZIP
# specific files have to be verified against a ZIP archive.
EOL_HANDLING=mixed
#EOL_HANDLING=auto

# In which directory are the source archives located?
ARCHIVES_DIR=archives

REPO_ALREADY_EXISTS=false

REPO=tc-repo

# keep a copy of the extracted archives in extracted/ ?
KEEP_EXTRACTED_ARCHIVES=true

#############################################################################
# No customisation needed beyond this part
#############################################################################


ALL_ARCHIVES=(
"truecrypt-1.0-source-code.zip"
"truecrypt-1.0a-source-code.zip"
"truecrypt-2.0-source-code.zip"
"truecrypt-2.1-source-code.zip"
"truecrypt-2.1a-source-code.zip"
"truecrypt-3.0a-source-code.zip"
"truecrypt-3.1-source-code.zip"
"truecrypt-3.1a-source-code.zip"
"truecrypt-4.0-source-code.tar.gz" "truecrypt-4.0-source-code.zip"
"truecrypt-4.1-source-code.tar.gz" "truecrypt-4.1-source-code.zip"
"truecrypt-4.2-source-code.tar.gz" "truecrypt-4.2-source-code.zip"
"truecrypt-4.2a-source-code.tar.gz" "truecrypt-4.2a-source-code.zip"
"truecrypt-4.3-source-code.tar.gz" "truecrypt-4.3-source-code.zip"
"truecrypt-4.3a-source-code.tar.gz" "truecrypt-4.3a-source-code.zip"
"TrueCrypt 5.0 Source.tar.gz" "TrueCrypt 5.0 Source.zip"
"TrueCrypt 5.0a Source.tar.gz" "TrueCrypt 5.0a Source.zip"
"TrueCrypt 5.1 Source.tar.gz" "TrueCrypt 5.1 source.zip"
"TrueCrypt 5.1a Source.tar.gz" "TrueCrypt 5.1a Source.zip"
"TrueCrypt 6.0 Source.tar.gz" "TrueCrypt 6.0 Source.zip"
"TrueCrypt 6.0a Source.tar.gz" "TrueCrypt 6.0a Source.zip"
"TrueCrypt 6.1 Source.tar.gz" "TrueCrypt 6.1 Source.zip"
"TrueCrypt 6.1a Source.tar.gz" "TrueCrypt 6.1a Source.zip"
"TrueCrypt 6.2 Source.tar.gz" "TrueCrypt 6.2 Source.zip"
"TrueCrypt 6.2a Source.tar.gz" "TrueCrypt 6.2a Source.zip"
"TrueCrypt 6.3 Source.tar.gz" "TrueCrypt 6.3 Source.zip"
"TrueCrypt 6.3a Source.tar.gz" "TrueCrypt 6.3a Source.zip"
"TrueCrypt 7.0 Source.tar.gz" "TrueCrypt 7.0 Source.zip"
"TrueCrypt 7.0a Source.tar.gz" "TrueCrypt 7.0a Source.zip"
"TrueCrypt 7.1 Source.tar.gz" "TrueCrypt 7.1 Source.zip"
"TrueCrypt 7.1a Source.tar.gz" "TrueCrypt 7.1a Source.zip"
)

if [ $TEST == true ]; then
	ARCHIVES=("${TEST_ARCHIVES[@]}")
else
	ARCHIVES=("${ALL_ARCHIVES[@]}")
fi

NUM_ARCHIVES=${#ARCHIVES[@]}


# Check if all archives exist
for (( i=0; i<$NUM_ARCHIVES; i++ )); do
	ARCHIVE=$ARCHIVES_DIR/${ARCHIVES[i]}
	if [ ! -f "$ARCHIVE" ]; then
		echo "*** ERROR: file '$ARCHIVE' not found"
		exit
	fi
done

# stop the verbal abuse of pushd and popd
pushd() { builtin pushd "$@" >/dev/null; }
popd() { builtin popd >/dev/null; }

if [ $REPO_ALREADY_EXISTS == false ]; then
	rm -rf "$REPO"
	mkdir "$REPO"
	git init "$REPO" >/dev/null
fi

if [ $EOL_HANDLING == "auto" ]; then
	# deal with line-ending changes
	pushd "$REPO"
	echo "* text=auto" >> .gitattributes
	git add .gitattributes
	git commit -m "Commit .gitattributes."
	popd
fi

rm -rf extracted
if [ $KEEP_EXTRACTED_ARCHIVES == true ]; then
	mkdir extracted
fi

ARCH_DIR=archive
rm -rf "$ARCH_DIR"

mv_archive_file_to_repo () {
	FILEPATH=$1

	if [ $EOL_HANDLING == "auto" ]; then
		mv "$ARCH_DIR/$FILEPATH" "$REPO/$FILEPATH"
		return
	fi

	CONVERT_EOL=false

	BASENAME="$(basename "$FILEPATH")"

	if [ "$(dirname "$FILEPATH")" == "./Setup" ] \
		|| [ "$BASENAME" == "TrueCrypt.sln" ]; then
		CONVERT_EOL=false
	else
		# Some of the files from ZIP archives have to be converted from using CRLF to LF.
		# Otherwise every time when switching between the ZIP and tgz archives there will
		# be major changes that merely consist of EOL changes.
		EXT="${FILEPATH##*.}"

		if [ "$BASENAME" == "Makefile" ] \
			|| [ "$BASENAME" == "MAKEFILE" ] \
			|| [ $EXT == "1" ] \
			|| [ $EXT == "C" ] || [ $EXT == "c" ] \
			|| [ $EXT == "cpp" ] \
			|| [ $EXT == "H" ] ||  [ $EXT == "h" ] \
			|| [ $EXT == "html" ] || [ $EXT == "inc" ] \
			|| [ $EXT == "make" ] \
			|| [ $EXT == "sh" ] || [ $EXT == "sln" ] \
			|| [ $EXT == "txt" ] \
			|| [ $EXT == "xml" ]; then

			CONVERT_EOL=LF

		elif [ "$BASENAME" == "Sources" ] \
			|| [ $EXT == "asm" ] \
			|| [ $EXT == "bat" ] \
			|| [ $EXT == "cmd" ] \
			|| [ $EXT == "fbp" ] \
			|| [ $EXT == "idl" ] \
			|| [ $EXT == "manifest" ] \
			|| [ $EXT == "pdf" ] \
			|| [ $EXT == "rc" ] \
			|| [ $EXT == "rtf" ] \
			|| [ $EXT == "vcproj" ]; then

			# Almost always these files already are CRLF but some of
			# the tar.gz archives store them as LF.
			CONVERT_EOL=CRLF

		fi
	fi


	if [ $CONVERT_EOL == "LF" ]; then
		# File has CRLF?
		if [[ $(head -1 "$ARCH_DIR/$FILEPATH") == *$'\r' ]]; then
			# Replace CRLF with LF
			tr -d "\r" < "$ARCH_DIR/$FILEPATH" > "$REPO/$FILEPATH"
			rm "$ARCH_DIR/$FILEPATH"
		else
			CONVERT_EOL=false
		fi
	elif [ $CONVERT_EOL == "CRLF" ]; then
		# if the file already has CRLF don't convert it (would become CRCRLF)
		if [[ $(head -1 "$ARCH_DIR/$FILEPATH") == *$'\r' ]]; then
			CONVERT_EOL=false
		else
			tr "\r" "\r\n" < "$ARCH_DIR/$FILEPATH" > "$REPO/$FILEPATH"
			rm "$ARCH_DIR/$FILEPATH"
		fi
	fi

	if [ $CONVERT_EOL == false ]; then
		mv "$ARCH_DIR/$FILEPATH" "$REPO/$FILEPATH"
	fi
}

for (( i=0; i<$NUM_ARCHIVES; i++ )); do
	ARCHIVE=$ARCHIVES_DIR/${ARCHIVES[i]}
	echo
	echo "*** Processing $ARCHIVE [$((i+1))/$NUM_ARCHIVES]"

	mkdir "$ARCH_DIR"

	IS_ZIP=false
	if [ "${ARCHIVE##*.}" == "zip" ]; then
		IS_ZIP=true
	fi

	if [ $IS_ZIP = true ]; then
		# ZIP doesn't support maintaining file permissions and depending
		# on the umask used ZIP files could be extracted with +x. Override
		# the file permissions that tar uses and make them the same
		# (rw-r--r--) as when extracting the tgz archive.
		OLD_UMASK=`umask`
		umask -S u=rw,g=r,o=r >/dev/null # same as: umask 0133
		tar -xf "$ARCHIVE" --no-same-permissions -C "$ARCH_DIR"
		umask $OLD_UMASK

		# Fix directories and some files that don't have +x:
		find "$ARCH_DIR" -type d -exec chmod +x {} \;
	else
		tar -xf "$ARCHIVE" --strip-components 1 -C "$ARCH_DIR"
	fi

	# Set +x for .sh files regardless of the archive type. Even not all
	# tgz archives have the permissions for the .sh files set correct
	find "$ARCH_DIR" -iname "*.sh" -exec chmod +x {} \;


	# if the archive has all content in a single root dir, move the content to the root of extraction
	DIR_COUNT=$(find "$ARCH_DIR" -type d -maxdepth 1 | wc -l)
	if [ $DIR_COUNT -lt 3 ]; then
		mv "$ARCH_DIR"/TrueCrypt/* "$ARCH_DIR/"
		rm -r "$ARCH_DIR/TrueCrypt"
	fi

	# Optionally keep a copy of extracted archives
	if [ $KEEP_EXTRACTED_ARCHIVES == true ]; then
		cp -r "$ARCH_DIR" "extracted/${ARCHIVES[i]}"
	fi


	# Are there any files that are present in the repository but missing
	# in the archive? Then rm the file from the repo (but not under all
	# circumstances, as the archives of the same version don't always have
	# the same files)
	IFS_OLD=$IFS
	IFS=","
	pushd "$REPO"
	REPO_FILES=($(find . ! -path "*/.git/*" ! -iname ".*" -type f -exec echo -n {}, \;))
	popd
	IFS=$IFS_OLD
	for (( j=0; j<${#REPO_FILES[@]}; j++ )); do
		REPO_FILE=${REPO_FILES[j]}

		REMOVE=false
		if [ ! -f "$ARCH_DIR/$REPO_FILE" ]; then
			REMOVE=true

			DIR=$(dirname "$REPO_FILE")

			if [ $IS_ZIP == true ]; then
				if [ "$REPO_FILE" == "./Makefile" ] \
					|| [ "$DIR" == "./Build/Include" ] \
					|| [ "$DIR" == "./Build/Resources/MacOSX" ] \
					|| [ "$DIR" == "./Core" ] \
					|| [ "$DIR" == "./Core/Unix" ] \
					|| [ "$DIR" == "./Core/Unix/FreeBSD" ] \
					|| [ "$DIR" == "./Core/Unix/Linux" ] \
					|| [ "$DIR" == "./Core/Unix/MacOSX" ] \
					|| [ "$DIR" == "./Core/Unix/Solaris" ] \
					|| [ "$DIR" == "./Driver/Fuse" ] \
					|| [ "$DIR" == "./Main" ] \
					|| [ "$DIR" == "./Main/Forms" ] \
					|| [ "$DIR" == "./Main/Unix" ] \
					|| [ "$DIR" == "./Platform/Unix" ] \
					|| [ "$DIR" == "./Resources" ] \
					|| [ "$DIR" == "./Resources/Icons" ] \
					|| [ "$DIR" == "./Volume" ]; then
					REMOVE=false
				fi
			else
				if [ "$REPO_FILE" == "./TrueCrypt.sln" ] \
					|| [ "$DIR" == "./Boot" ] \
					|| [ "$DIR" == "./Boot/Windows" ] \
					|| [ "$DIR" == "./Setup" ]; then
					REMOVE=false
				fi
			fi

			if [ $REMOVE == true ]; then
				pushd "$REPO"
				git rm -f "$REPO_FILE" >/dev/null
				popd
			fi
		fi
	done


	# Add any missing dirs to the repo
	IFS_OLD=$IFS
	IFS=","
	pushd "$ARCH_DIR"
	DIRS=($(find . -type d -exec echo -n {}, \;))
	popd
	IFS=$IFS_OLD

	for (( j=0; j<${#DIRS[@]}; j++ )); do
		if [ ! -d "$REPO/${DIRS[j]}" ]; then
			pushd "$REPO"
			mkdir "${DIRS[j]}"
			git add "${DIRS[j]}"
			popd
		fi
	done


	# Check for file changes
	IFS_OLD=$IFS
	IFS=","
	pushd "$ARCH_DIR"
	FILES=($(find . -type f -exec echo -n {}, \;))
	popd
	IFS=$IFS_OLD

	for (( j=0; j<${#FILES[@]}; j++ )); do
		FILE="${FILES[j]}"
		if [ -f "$REPO/$FILE" ]; then
			FILENAME_CASING_CHANGED=$(find "$REPO/`dirname "$FILE"`" -name "`basename "$FILE"`" -maxdepth 1 | wc -l)
			if [ $FILENAME_CASING_CHANGED -eq 0 ]; then
				# File's casing changed
				pushd "$REPO"
				OLD_NAME=$(find "`dirname "$FILE"`" -iname "`basename "$FILE"`" -maxdepth 1)
				git mv -f "$OLD_NAME" "$FILE" >/dev/null 2>&1
				popd
				rm "$ARCH_DIR/$FILE"
			else
				# File with same name
				mv_archive_file_to_repo "$FILE"
			fi
		else
			mv_archive_file_to_repo "$FILE"

			pushd "$REPO"
			git add "$FILE" >/dev/null 2>&1
			popd
		fi
	done

	#if [ $i -eq "1" ]; then
	#	exit
	#fi

	FILES=($(find "$ARCH_DIR" -type f))
	if [ ${#FILES} -gt 0 ]; then
		echo "*** ERROR: UNPROCESSED FILES IN ARCHIVE:"
		echo $FILES
		exit
	fi


	pushd "$REPO"
	git commit --short -a 2>/dev/null || true
	TC_VERSION=$(echo $ARCHIVE | sed 's/[^0-9.]*\([0-9a.]*\).*/\1/')
	COMMIT_MESSAGE="$TC_VERSION changes"
	if [ $IS_ZIP == true ]; then
		COMMIT_MESSAGE+=" (Windows)"
	fi
	COMMIT_MESSAGE+="."
	git commit -am "$COMMIT_MESSAGE" 2>/dev/null || true
	popd

	rm -r "$ARCH_DIR"

done
