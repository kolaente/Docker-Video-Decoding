FROM docker

# Add bash, needed for our conversion script
RUN apk add --update bash util-linux && rm -rf /var/cache/apk/*

# Create folders
RUN mkdir /var/videos && \
mkdir -p /var/videoconversion/config

# Add the actual script
COPY convert.sh /var/videoconversion/
COPY jq /var/videoconversion/
COPY video_formats.json /var/videoconversion/config/

RUN chmod +x /var/videoconversion/convert.sh && \
chmod +x /var/videoconversion/jq

# Volumes
VOLUME /var/videos
VOLUME /var/videoconversion/config

#ENTRYPOINT while true; do sleep 1d; done
ENTRYPOINT ./var/videoconversion/convert.sh -c /var/videoconversion/config/video_formats.json -p /var/videos -f "docker run -v /var/videos:/var/videos jrottenberg/ffmpeg:alpine-3.3"
