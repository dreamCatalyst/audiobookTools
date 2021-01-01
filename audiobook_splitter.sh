#!/bin/bash

# -----------------------------------------------------------------------------
# Copyright (c) 2020 Jonathan Maasland jDOTmaaslandATprotonmailDOTcom
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

SCRIPTNAME=$(basename "$0")
SCRIPTVERSION="0.1.0"

# -------------------------------------------------------- Variables for colorizing output

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_GREY='\033[0;37m'
COLOR_YELLOW='\033[1;33m'
NO_COLOR='\033[0m'


# -------------------------------------------------------- Generic functions

print_verbose() {
    if [ $ENABLE_DEBUG = true ] || [ $VERBOSE_OPT = true ]; then
        echo -e "${COLOR_YELLOW}$1${NO_COLOR}"
    fi
}

ENABLE_DEBUG=true  # temp. set to true for debugging
print_debug() {
    if [ $ENABLE_DEBUG = true ]; then
        echo -e "${COLOR_CYAN}$1${NO_COLOR}"
    fi
}

print_error() {
    echo -e "${COLOR_RED}$1${NO_COLOR}"
}

print_error_and_exit() {
    print_error "$1"
    exit 1
}

usage() {
    cat <<EOS
audiobook_splitter.sh - version $SCRIPTVERSION - Copyright (c) 2020 Jonathan Maasland

Usage: $SCRIPTNAME [options] FILENAME
  -h|--help                    Print this help message
  -v|--verbose                 Enable verbose messages
  -d|--directory directory     Place output segments in specified directory
  -l|--length seconds          Length each segment should be in seconds (default 1800 = 30 minutes)
  -g|--grace seconds           If the potential last segment is shorter than the grace period then
                               do not create the last segment but instead lengthen the last one.
                               (default 600 = 10 minutes, set to 0 to disable)
  -b|--bitrate num             Bitrate to use for encoding (default 128k)
  -c|--codec c                 Audio codec to use (default libmp3lame)
  -e|--ext e                   File extension to use for the output segments (default mp3)
  --prefix string              Use the provided string as a default prefix for segment filenames and
                               title metadata. Default value is to use the name of the source file
  --segment-prefix string      Use the specified string as a prefix for segment filenames. Overrides --prefix
  --title-prefix string        Use a specific title metadata string prefix. Overrides --prefix
  --suffix string              Use the provided string as a default suffix for segment filenames and
                               title metadata. Default value is " - part %02d". The "%02d" is the
                               placeholder for the number of the segment. It's possible to use two
                               placeholders. The second one will then be used for the total number of
                               segments. For example using " - part %2d / %2d" would result in a
                               suffix that would look like " - part 22 / 54".
                               See printf(1) for more information on formatting.
  --segment-suffix string      Use a specific segment filename suffix. Overrides --suffix
  --title-suffix string        Use a specific title metadata string suffix. Overrides --suffix
  --cover filename             Use provided file as the cover art instead of copying the cover art
                               (if any) of the source file
  --no-coverart                Do not copy cover art from the source file to the segments
  --no-copy-metadata           Do not copy over metadata from the source file to the segments
  
  The following options can be used to provide or override values for specific metadata fields:
  --meta-title string
  --meta-artist string
  --meta-album string
  --meta-genre string
  --meta-publisher string
  --meta-comment string
  These settings override the values provided (if any) in the source file.

EOS

    if [ "$1" ]; then
        print_error_and_exit "Error: $1";
    fi
    exit 0
}  # end of usage() function


# -------------------------------------------------------- Command line option parsing

VERBOSE_OPT=false
OUTPUT_DIRECTORY=""
SEGMENT_LENGTH=1800
GRACE_LENGTH=600
BITRATE="128k"
CODEC="libmp3lame"
SEGMENT_EXTENSION="mp3"

PREFIX_STRING=""
SEGMENT_PREFIX=""
TITLE_PREFIX=""

SUFFIX_STRING=" - part %02d"
SEGMENT_SUFFIX=""
TITLE_SUFFIX=""

COPY_METADATA=true
COPY_COVERART=true
COVERART_FILE=""
META_TITLE=""
META_ARTIST=""
META_ALBUM=""
META_GENRE=""
META_PUBLISHER=""
META_COMMENT=""

INPUTFILENAME=""

while [[ $# -gt 0 ]]
do
    key="$1"
    print_debug "Parsing command line option: '$key'"
    case "$key" in
    -h|--help)
        usage
        ;;
    -v|--verbose)
        print_debug "Setting verbose to true"
        VERBOSE_OPT=true
        shift
        ;;
    -d|--directory)
        print_debug "Setting OUTPUT_DIRECTORY to '$2'"
        OUTPUT_DIRECTORY="$2"
        shift; shift
        ;;
    -l|--length)
        print_debug "Setting SEGMENT_LENGTH to '$2'"
        SEGMENT_LENGTH="$2"
        shift; shift
        ;;
    -g|--grace)
        print_debug "Setting GRACE_LENGTH to '$2'"
        GRACE_LENGTH="$2"
        shift; shift
        ;;
    -b|--bitrate)
        print_debug "Setting BITRATE to '$2'"
        BITRATE="$2"
        shift; shift
        ;;
    -c|--codec)
        print_debug "Setting CODEC to '$2'"
        CODEC="$2"
        shift; shift
        ;;
    -e|--ext)
        print_debug "Setting SEGMENT_EXTENSION to '$2'"
        SEGMENT_EXTENSION="$2"
        shift; shift
        ;;
    --prefix)
        print_debug "Setting PREFIX_STRING to '$2'"
        PREFIX_STRING="$2"
        shift; shift
        ;;
    --segment-prefix)
        print_debug "Setting SEGMENT_PREFIX to '$2'"
        SEGMENT_PREFIX="$2"
        shift; shift
        ;;
    --title-prefix)
        print_debug "Setting TITLE_PREFIX to '$2'"
        TITLE_PREFIX="$2"
        shift; shift
        ;;
    --suffix)
        print_debug "Setting SUFFIX_STRING to '$2'"
        SUFFIX_STRING="$2"
        shift; shift
        ;;
    --segment-suffix)
        print_debug "Setting SEGMENT_SUFFIX to '$2'"
        SEGMENT_SUFFIX="$2"
        shift; shift
        ;;
    --title-suffix)
        print_debug "Setting TITLE_SUFFIX to '$2'"
        TITLE_SUFFIX="$2"
        shift; shift
        ;;
    --cover)
        print_debug "Setting COVERART_FILE to '$2'"
        COVERART_FILE="$2"
        shift; shift
        ;;
    --no-coverart)
        print_debug "Setting COPY_COVERART to false"
        COPY_COVERART=false
        shift
        ;;
    --no-copy-metadata)
        print_debug "Setting COPY_METADATA to false"
        COPY_METADATA=false
        shift
        ;;
    --meta-title)
        print_debug "Setting META_TITLE to '$2'"
        META_TITLE="$2"
        shift; shift
        ;;
    --meta-artist)
        print_debug "Setting META_ARTIST to '$2'"
        META_ARTIST="$2"
        shift; shift
        ;;
    --meta-album)
        print_debug "Setting META_ALBUM to '$2'"
        META_ALBUM="$2"
        shift; shift
        ;;
    --meta-genre)
        print_debug "Setting META_GENRE to '$2'"
        META_GENRE="$2"
        shift; shift
        ;;
    --meta-publisher)
        print_debug "Setting META_PUBLISHER to '$2'"
        META_PUBLISHER="$2"
        shift; shift
        ;;
    --meta-comment)
        print_debug "Setting META_COMMENT to '$2'"
        META_COMMENT="$2"
        shift; shift
        ;;
    *)
        print_debug "setting INPUTFILENAME to '$1'"
        INPUTFILENAME="$1"
        shift
esac
done


# -------------------------------------------------------- Command line option validation

if [ -z "$INPUTFILENAME" ]; then
    usage "Please provide an input filename."
fi
if [ ! -e "$INPUTFILENAME" ]; then
    usage "File '$INPUTFILENAME' does not exist"
fi

if [ "$OUTPUT_DIRECTORY" ]; then
    if [ ! -d "$OUTPUT_DIRECTORY" ]; then
        if ! mkdir "$OUTPUT_DIRECTORY"; then
            print_error_and_exit "Error creating directory '$OUTPUT_DIRECTORY'. Exiting"
        fi
    fi
fi

if ! [[ "$SEGMENT_LENGTH" =~ ^[1-9][0-9]*$  ]]; then
    usage "Please provide an integer larger than 0 for segment length"
fi
if ! [[ "$GRACE_LENGTH" =~ ^[0-9]+$  ]]; then
    usage "Please provide a segment length of greater than or equal to 0"
fi

if ! [[ "$BITRATE" =~ ^[1-9][0-9]*k$  ]]; then
    usage "Please provide a valid bitrate ending in k (e.g. 128k)"
fi

print_debug "-----------------------------------"
print_debug "Printing variables after validation"
print_debug "-----------------------------------"
print_debug "INPUTFILENAME:     '$INPUTFILENAME'"
print_debug "OUTPUT_DIRECTORY:  '$OUTPUT_DIRECTORY'"
print_debug "SEGMENT_LENGTH:    $SEGMENT_LENGTH"
print_debug "GRACE_LENGTH:      $GRACE_LENGTH"
print_debug "SEGMENT_EXTENSION: '$SEGMENT_EXTENSION'"
print_debug "CODEC:             '$CODEC'"
print_debug "BITRATE:           '$BITRATE'"
print_debug "-----------------------------------"


# ------------------------------------------------------ Check for required programs

REQUIRED_PROGRAMS=("ffprobe" "ffmpeg" "bc")
for p in "${REQUIRED_PROGRAMS[@]}"; do
    if ! which "$p" &>/dev/null; then
        usage "Required program '$p' not found. exiting"  # "  (added because of Kate bash highlighting bug )
    fi
done


# ------------------------------------------------------ Commence heavy lifting

# Retrieve the duration of the file in hours, minutes and seconds
PROBE_OUTPUT_FN="probe_output.txt"
if [ -e $PROBE_OUTPUT_FN ]; then
    print_debug "$PROBE_OUTPUT_FN already exists. Removing"
    rm $PROBE_OUTPUT_FN
fi

ffprobe "$INPUTFILENAME" 2> $PROBE_OUTPUT_FN
if [ ! -e "$PROBE_OUTPUT_FN" ]; then
    print_error_and_exit "Error creating or retrieving output from ffprobe. Exiting!"
fi

DURATION_STRING=$(cat $PROBE_OUTPUT_FN | grep Duration | grep -o "[0-9]\{1,2\}:[0-9]\{1,2\}:[0-9]\{1,2\}\.[0-9]\+")
print_verbose "Inputfile duration: $DURATION_STRING"

LEN_H=$(echo $DURATION_STRING| cut -f1 -d:)
LEN_M=$(echo $DURATION_STRING| cut -f2 -d:)
LEN_S=$(echo $DURATION_STRING| cut -f3 -d:)
# length in seconds here contains seconds plus the milliseconds (so 42.61 for example)
# we don't care about the milliseconds, we simply add 1 second to the value
LEN_S=$(( $(echo $LEN_S | cut -f1 -d.) + 1 ))
print_debug "Duration string separated: hours=$LEN_H minutes=$LEN_M seconds=$LEN_S"

TOTAL_LEN_S=$((LEN_H*3600 + LEN_M*60 + LEN_S))

# calculate the number of segments we need to create
NUM_SEGMENTS=$((TOTAL_LEN_S / SEGMENT_LENGTH))
REMAINDER=$((TOTAL_LEN_S % SEGMENT_LENGTH))
if [ $REMAINDER -gt $GRACE_LENGTH ]; then
    NUM_SEGMENTS=$((NUM_SEGMENTS+1))
fi
print_verbose "Number of segments to create: $NUM_SEGMENTS"

# build the ffmpeg command and execute it
for SEGMENT in $(seq 1 $NUM_SEGMENTS); do
  FFMPEG_CMD="ffmpeg "
  if [ $SEGMENT -gt 1 ]; then  # for the first segment -ss is not needed
      SEGMENT_START=$(( (SEGMENT-1) * SEGMENT_LENGTH ))
      FFMPEG_CMD+="-ss $SEGMENT_START "
  fi
  if [ $SEGMENT != $NUM_SEGMENTS ]; then  # for the last segment -to is not needed
      SEGMENT_END=$(( SEGMENT * SEGMENT_LENGTH ))
      FFMPEG_CMD+="-to $SEGMENT_END "
  fi
  # regular metadata
  # title metadata
  # cover art
  # segment filename
  
  print_debug "constructed command: '$FFMPEG_CMD'"
done


# ------------------------------------------------------ Cleanup

#rm $PROBE_OUTPUT_FN
