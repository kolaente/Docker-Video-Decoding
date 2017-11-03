# Video Decoding with Docker containers

This image provides an easy way to convert a video file in multiple different output formats. Just specify a folder which holds the video files, it will automatically watch it and convert everything you specify.

It will create a new folder for each video which will hold all outputted formats. Once finished, it creates a file `[videoname].done` in said folder to indicate it is done. It will also move (and rename) the original file to this folder.

# Running, the easy way

The following command will convert all `mp4` and `webm` videos to `webm` files.

```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock -v /path/to/video/files:/var/videos --name videodecoding --env VIDEO_FOLDER=/path/to/video/files --env VIDEO_FORMATS='.mp4':'.webm' kolaente/video-decode
```

# Options

All settings can be done via environment variables passed to the container.

* __VIDEO_FORMATS_LOCATION__: Pass a location to a different JSON file holding video convert configurations (see below for more informations about that file).
* __VIDEO_FORMATS__: Pass all video formats which should trigger the conversion, seperated by ':. Example: .mp4:.wmv

## Video location

Videos are placed in `/var/videos` inside the container. Mount a folder from your host holding the videos.

# Specify output video formats

This is done via a JSON file at `/var/videoconversion/config/video_formats.json`. You can mount `/var/videoconversion/config/` to your host and specify your own formats.

`framerate` is the only one optional. You _need_ to specify everything else.

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
