# Audiobooktools

Tools to convert large audiobooks into smaller segments.

---
    Copyright (c) 2020 Jonathan Maasland jDOTmaaslandATprotonmailDOTcom
    
    Permission to use, copy, modify, and/or distribute this software for
    any purpose with or without fee is hereby granted, provided that the
    above copyright notice and this permission notice appear in all copies.
    
    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
    OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
---

## Introduction

Audiobooktools was created to simplify the process of splitting up long audio files into
smaller and shorter files. As someone who listens to audiobooks before sleep I found it
tedious to have to issue shell commands so that that 9 hour book I was listening to would
pause after 45 minutes. The solution is simple: just split the book up into smaller parts
of 30 minutes. The added benefit is that it's obviously much simpler to keep track of where
in the audiobook you left off. No more searching, seeking and listening to parts you already
heard. Just start at the part where you left off. Maybe in the specific part you'll do some
fastforwarding but it's much more precise.

After several times of manually splitting audiobooks with ffmpeg I decided to create this little
tool to make my life easier. It is dependent on ffmpeg and is nothing more than a simple
wrapper but should provide the user the freedom to forget about how to apply the proper options
to ffmpeg.


## Some examples

Suppose we have an audiobook called source.mp3 and it's a three hour long book. Executing:

    audiobook_splitter.sh source.mp3
    ...
    > ls
    source.mp3
    source - part 01.mp3
    source - part 02.mp3
    ...
    source - part 06.mp3

would result in six new files being created: source - part 01.mp3, source - part 02.mp3 all the way through
to source - part 06.mp3. All these files would be 30 minutes long and be encoded in a bitrate of 128k.

    audiobook_splitter.sh -l 3600 source.mp3
    ...
    > ls
    source.mp3
    source - part 01.mp3
    source - part 02.mp3
    source - part 03.mp3

As you can see this command would create three new files: source-part01.mp3, source-part02.mp3 and source-part03.mp3.
The *-l 3600* option indicates that each part should be 3600 seconds long (1 hour).

If you want to place the newly created segments in a directory of their own you can do that by using
the *-d directory* option:

    audiobook_splitter.sh -d parts source.mp3
    ...
    > ls
    parts/
    source.mp3
    > ls parts/
    source - part 01.mp3
    source - part 02.mp3
    ...
    source - part 06.mp3
    
    
This would create the same six, 30 minute segments and put them in the *parts* subdirectory.


## Prefix, suffix and segments. What's up with all that?

In order to provide the user with more flexibility it's possible to provide options overriding the default 
prefix and suffix values. By default audiobook_splitter uses the name of the source file as it's prefix.
For all the created segments it adds a **" - part xx"** suffix.

For example:

    source - part01.mp3
      |        |
      |        +---> suffix
      +----> prefix

Suppose you live in Germany and you don't want **" - part 01"** but **" - teil 01"** instead.
You can use the *--suffix* option to provide your own suffix. As noted below in the usage section
you can use the printf format for placeholders:

    audiobook_splitter.sh --suffix " - teil %2d" source.mp3
    ...
    > ls
    source.mp3
    source - teil 01.mp3"
    source - teil 02.mp3"
    ...

As you can see, the "%2d" part of the suffix string gets replaced with the appropriate number.

Now suppose you have source.mp3 but it actually contains the audiobook version of "Alice in Wonderland".
You can then use the *--prefix* option to change the prefix of the generated files:

    audiobook_splitter.sh --prefix "Alice in Wonderland" source.mp3
    ...
    > ls
    source.mp3
    Alice in Wonderland - part 01.mp3"
    Alice in Wonderland - part 02.mp3"
    ...


## Usage

    audiobook_splitter.sh - version 0.2.0 - Copyright (c) 2020 Jonathan Maasland

    Usage: audiobook_splitter.sh [options] FILENAME
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
    These settings override the metadata values provided (if any) by the source file.
