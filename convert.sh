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

# Add a (lightweight) tag for each TC release? (named "tc-<version>")
TAG=true

# Set to true to collapse the extracted tgz and zip of the same
# release into one commit.
# If set to false each processed archive will have a commit.
COLLAPSE_COMMITS=true

# keep a copy of the extracted archives in extracted/ ?
KEEP_EXTRACTED_ARCHIVES=true

#############################################################################
# No customisation needed beyond this part
#############################################################################


ALL_ARCHIVES=(
"" "truecrypt-1.0-source-code.zip"
"" "truecrypt-1.0a-source-code.zip"
"" "truecrypt-2.0-source-code.zip"
"" "truecrypt-2.1-source-code.zip"
"" "truecrypt-2.1a-source-code.zip"
"" "" # 3.0 is missing
"" "truecrypt-3.0a-source-code.zip"
"" "truecrypt-3.1-source-code.zip"
"" "truecrypt-3.1a-source-code.zip"
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

# Release dates of the releases. Most of these come
# from http://en.wikipedia.org/wiki/TrueCrypt_release_history
RELEASE_DATES=(
"2004-02-02" # 1.0
"2004-02-03" # 1.0a
"2004-06-07" # 2.0
"2004-06-21" # 2.1
"2004-10-01" # 2.1a
"2004-12-10" # 3.0 (missing), approximate date
"2004-12-11" # 3.0a
"2005-01-22" # 3.1
"2005-02-07" # 3.1a
"2005-11-01" # 4.0
"2005-11-25" # 4.1
"2006-04-17" # 4.2
"2006-07-04" # 4.2a, approximate date
"2007-03-19" # 4.3
"2007-05-08" # 4.3a, approximate date
"2008-02-05" # 5.0
"2008-02-13" # 5.0a, approximate date
"2008-03-10" # 5.1
"2008-03-17" # 5.1a, approximate date
"2008-07-04" # 6.0
"2008-07-08" # 6.0a
"2008-10-31" # 6.1
"2008-12-01" # 6.1a
"2009-05-11" # 6.2
"2009-06-19" # 6.2a
"2009-10-21" # 6.3
"2009-11-23" # 6.3a
"2010-07-19" # 7.0
"2010-09-06" # 7.0a
"2011-09-01" # 7.1
"2012-02-07" # 7.1a
)

if [ ${#ALL_ARCHIVES[@]} != $((${#RELEASE_DATES[@]} * 2)) ]; then
	echo "*** ERROR: Amount of archive versions and release dates out of sync"
	exit
fi

if [ $TEST == true ]; then
	ARCHIVES=("${TEST_ARCHIVES[@]}")
else
	ARCHIVES=("${ALL_ARCHIVES[@]}")
fi

NUM_ARCHIVES=${#ARCHIVES[@]}


# Check if all archives exist
for (( i=0; i<$NUM_ARCHIVES; i++ )); do
	ARCHIVE=$ARCHIVES_DIR/${ARCHIVES[i]}
	if [ -n "${ARCHIVES[i]}" ] && [ ! -f "$ARCHIVE" ]; then
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
	export GIT_COMMITTER_DATE="${RELEASE_DATES[0]} 00:00:00"
	git commit -m "Commit .gitattributes." --date="$GIT_COMMITTER_DATE"
	popd
fi

rm -rf extracted
mkdir extracted

ARCH_DIR=archive
rm -rf "$ARCH_DIR"

USE_UNZIP=true
command -v unzip >/dev/null 2>&1 || USE_UNZIP=false

mv_archive_file_to_repo () {
	FILEPATH=$1

	if [ $EOL_HANDLING == "auto" ]; then
		mv "$ARCH_DIR/$FILEPATH" "$REPO/$FILEPATH"
		return
	fi

	CONVERT_EOL=false

	EXT="${FILEPATH##*.}"

	if [ "$(dirname "$FILEPATH")" == "./Setup" ]; then
		# All the text files in Setup/ are Windows specific. Keep them
		# as CRLF (unless binary).

		if [ $EXT == "bmp" ] || [ $EXT == "ico" ]; then
			CONVERT_EOL=false
		else
			CONVERT_EOL=CRLF
		fi
	fi

	if [ $CONVERT_EOL == false ]; then
		# Some of the files from ZIP archives have to be converted from using CRLF to LF.
		# Otherwise every time when switching between the ZIP and tgz archives there will
		# be major changes that merely consist of EOL changes.
		BASENAME="$(basename "$FILEPATH")"

		if [ "$BASENAME" == "Makefile" ] \
			|| [ "$BASENAME" == "MAKEFILE" ] \
			|| [ $EXT == "1" ] \
			|| [ $EXT == "C" ] || [ $EXT == "c" ] \
			|| [ $EXT == "cpp" ] \
			|| [ $EXT == "H" ] ||  [ $EXT == "h" ] \
			|| [ $EXT == "html" ] || [ $EXT == "inc" ] \
			|| [ $EXT == "make" ] \
			|| [ $EXT == "sh" ] \
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
			|| [ $EXT == "rgs" ] \
			|| [ $EXT == "rtf" ] \
			|| [ $EXT == "sln" ] \
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
			awk '{ sub(/$/,"\r"); print }' < "$ARCH_DIR/$FILEPATH" > "$REPO/$FILEPATH"
			rm "$ARCH_DIR/$FILEPATH"
		fi
	fi

	if [ $CONVERT_EOL == false ]; then
		mv "$ARCH_DIR/$FILEPATH" "$REPO/$FILEPATH"
	fi
}

for (( i=0; i<$NUM_ARCHIVES; i++ )); do

	# Skip archives that aren't available
	if [ -z "${ARCHIVES[i]}" ]; then
		continue
	fi

	ARCHIVE=$ARCHIVES_DIR/${ARCHIVES[i]}

	echo
	echo "*** Processing $ARCHIVE [$((i+1))/$NUM_ARCHIVES]"

	mkdir "$ARCH_DIR"

	IS_ZIP=false
	if [ "${ARCHIVE##*.}" == "zip" ]; then
		IS_ZIP=true
	fi
	# Handling left (by default tgz) or right (by default zip) archive?
	if [ $((i%2)) -eq 1 ]; then
		IS_RIGHT_ARCHIVE=true
	else
		IS_RIGHT_ARCHIVE=false
	fi

	if [ $IS_ZIP = true ]; then
		if [ $USE_UNZIP == true ]; then
			unzip "$ARCHIVE" -d "$ARCH_DIR" >/dev/null
		else
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
		fi
	else
		tar -xf "$ARCHIVE" --strip-components 1 -C "$ARCH_DIR"
	fi

	# Set +x for .sh files regardless of the archive type. Even not all
	# tgz archives have the permissions for the .sh files set correct
	find "$ARCH_DIR" -iname "*.sh" -exec chmod +x {} \;


	# if the archive has all content in a single root dir, move the content to the root of extraction
	DIR_COUNT=$(find "$ARCH_DIR" -maxdepth 1 -type d | wc -l)
	if [ $DIR_COUNT -lt 3 ]; then
		mv "$ARCH_DIR"/TrueCrypt/* "$ARCH_DIR/"
		rm -r "$ARCH_DIR/TrueCrypt"
	fi

	cp -r "$ARCH_DIR" "extracted/${ARCHIVES[i]}"

	if [ $IS_RIGHT_ARCHIVE == true ]; then
		# Out of interest, mention any diffs that exist between the tgz and
		# zip archive of the same release
		#BACKUP_DIR_ZIP="extracted/${ARCHIVES[i]}"
		BACKUP_DIR_RIGHT_ARCHIVE="extracted/${ARCHIVES[i]}"

		pushd "$BACKUP_DIR_RIGHT_ARCHIVE"
		find . -type f|while read FILE; do
			if [ -f "../$BACKUP_DIR_LEFT_ARCHIVE/$FILE" ]; then
				diff -u -w "../$BACKUP_DIR_LEFT_ARCHIVE/$FILE" "$FILE" || true
			fi
		done
		popd

		if [ $KEEP_EXTRACTED_ARCHIVES == false ]; then
			rm -r "$BACKUP_DIR_LEFT_ARCHIVE"
			rm -r "$BACKUP_DIR_RIGHT_ARCHIVE"
		fi
	else
		BACKUP_DIR_LEFT_ARCHIVE="extracted/${ARCHIVES[i]}"
	fi


	# Are there any files that are present in the repository but missing
	# in the archive? Then rm the file from the repo (but not under all
	# circumstances, as the archives of the same version don't always have
	# the same files)
	pushd "$REPO"
	find . ! -path "*/.git/*" ! -iname ".*" -type f|while read REPO_FILE; do
		popd

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

		pushd "$REPO"
	done
	popd

	# Add any missing dirs to the repo

	pushd "$ARCH_DIR"
	find . -type d|while read DIR; do
		if [ ! -d "../$REPO/$DIR" ]; then
			pushd "../$REPO"
			mkdir "$DIR"
			git add "$DIR"
			popd
		fi
	done
	popd


	# Check for file changes
	pushd "$ARCH_DIR"
	find . -type f|while read FILE; do
		popd
		if [ -f "$REPO/$FILE" ]; then
			FILENAME_CASING_CHANGED=$(find "$REPO/`dirname "$FILE"`" -maxdepth 1 -name "`basename "$FILE"`" | wc -l)
			if [ $FILENAME_CASING_CHANGED -eq 0 ]; then
				# File's casing changed
				pushd "$REPO"
				OLD_NAME=$(find "`dirname "$FILE"`" -maxdepth 1 -iname "`basename "$FILE"`")
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
		pushd "$ARCH_DIR"
	done
	popd

	#if [ $i -eq "1" ]; then
	#	exit
	#fi

	FILES=($(find "$ARCH_DIR" -type f))
	if [ ${#FILES} -gt 0 ]; then
		echo "*** ERROR: UNPROCESSED FILES IN ARCHIVE:"
		echo $FILES
		exit
	fi


	if [ $COLLAPSE_COMMITS == false ] || [ $IS_RIGHT_ARCHIVE == true ]; then
		pushd "$REPO"
		git commit --short -a 2>/dev/null || true
		TC_VERSION=$(echo $ARCHIVE | sed 's/[^0-9.]*\([0-9a.]*\).*/\1/')
		if [ $TC_VERSION == "3.0a" ]; then
			COMMIT_MESSAGE="3.0+3.0a changes"
		else
			COMMIT_MESSAGE="$TC_VERSION changes"
		fi

		if [ $IS_ZIP == true ] && [ $COLLAPSE_COMMITS == false ]; then
			COMMIT_MESSAGE+=" (Windows)"
		fi
		COMMIT_MESSAGE+="."

		export GIT_COMMITTER_DATE="${RELEASE_DATES[i / 2]} 00:00:00"
		git commit -am "$COMMIT_MESSAGE" --date="$GIT_COMMITTER_DATE" 2>/dev/null || true
		if [ $TAG == true ]; then
			TAG_NAME=tc-$TC_VERSION
			if [ $IS_ZIP == true ] && [ $COLLAPSE_COMMITS == false ]; then
				TAG_NAME+="-w"
			fi
			git tag "$TAG_NAME"
		fi
		popd
	fi

	rm -r "$ARCH_DIR"

done

if [ $KEEP_EXTRACTED_ARCHIVES == false ]; then
	rm -r extracted
fi

echo "All done!"
