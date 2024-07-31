# skp-to-m3u

An automated solution to turn skp files to m3u files for skipping over sections of a video while using something like VLC Media Player.

## Goal

The "skp" file format, called "Skip", is a file format used in conjunction with the open-source project VideoSkip.
These files help denote sections of a video that wish to be skipped over.
Skip files can be obtained from <https://videoskip.herokuapp.com/exchange/>.

The "m3u" file format, aka the MP3 URL, is a file format that can easily be used to leverage the same capability as "skp" files. When using "m3u" files with VLC media player, these jumps in time to skip over timestamped sections can be achieved with _#EXTVLCOPT_ headers.

This automated tool provides the convenience of the community's provided Skip files with the ease of use of VLC Media Player to achieve a great video experience.

## How to Use

There are a variety of scripts here that all do the same thing.

The files in this repository achieve the same thing, but are available for different platforms, like for PowerShell or Bash or Python, etc.

Running the script requires parameters:

- Absolute path of source video file
- Absolute path of Skip file to convert

If you do not include these when running the script, you will be prompted for them.

Once the script is done, it will output a M3U file to the location of your video file.
The M3U file must be in the same directory of your video file.

Opening the M3U with VLC Media Player will produce the desired effect.

## Technical Details

Again, we're just taking the information of the Skip file and translating it to a useable M3U file, nothing mind blowing like solving P=NP or creating a real random number generator.

A Skip file has the timestamp in the following pattern:

```less
0:23:13.63 --> 0:23:44.84
bad stuff
```

For a M3U file, these timestamps are converted to seconds and the following is produced:

```less
#EXTVLCOPT:start-time=1
#EXTVLCOPT:stop-time=1393
movie.mkv
#EXTVLCOPT:start-time=1424
#EXTVLCOPT:stop-time=10822
movie.mkv
```

It's a little more verbose, but you get the idea. The first section plays to a point and the second section picks up a little further ahead, skipping the bad stuff.
