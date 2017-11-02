FROM docker
RUN mkdir /var/videos
WORKDIR /var/videos
ADD convert.sh
VOLUME /var/videos
