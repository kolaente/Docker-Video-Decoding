# Video Decoding with Docker containers

This image provides an easy way to convert a video file in multiple different output formats. Just specify a folder which holds the video files, it will automatically watch it and convert everything you specify.

# Running, the easy way

```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock -v /path/to/video/files:/var/videos --name videodecoding --env VIDEO_FOLDER=/path/to/video/files --env VIDEO_FORMATS='.mp4':'.webm' kolaente/video-decode
```

# Options

-c: Video Formats Location. Pass a path with a JSON config file for conversion. Defaults to 'video_formats.json' in current folder.
-p: Video Location. Pass a location to a different folder which holds the videos. Defaults to currents folder.
-v: Video Formats. Pass all video formats which should trigger the conversion, seperated by ':'. Example: .mp4:.wmv

ENVIRONMENT VARIABLES:
All settings can be done via environment variables passed to the container.

VIDEO_FORMATS_LOCATION: Pass a location to a different json file holding video convert configurations
VIDEO_LOCATION: Pass a location to a different folder which holds the videos
VIDEO_FORMATS: Pass all video formats which should trigger the conversion, seperated by ':. Example: .mp4:.wmv

# Specify output video formats

This is done via a JSON file at `/var/videoconversion/config/video_formats.json`. You can mount `/var/videoconversion/config/` to your host and specify your own formats.

Standard configuration looks like this:

```json
[
    {
        "name": "720p",
        "height": "720",
        "video_bitrate": "5000k",
        "video_codec": "libvpx",
        "audio_bitrate": "256k",
        "audio_codec": "libvorbis",
        "file_ending": "webm"
    },
    {
        "name": "480p",
        "height": "480",
        "framerate": 24,
        "video_bitrate": "2500k",
        "video_codec": "libvpx",
        "audio_bitrate": "256k",
        "audio_codec": "libvorbis",
        "file_ending": "webm"
    },
    {
        "name": "360p",
        "height": "360",
        "framerate": 24,
        "video_bitrate": "1000k",
        "video_codec": "libvpx",
        "audio_bitrate": "256k",
        "audio_codec": "libvorbis",
        "file_ending": "webm"
    }
]
```

# License

Copyright 2017 K. Langenberg
Licensed under GNU GPLv3
