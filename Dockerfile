FROM debian:bullseye

RUN mkdir /src
RUN apt update
RUN apt-get --yes install --no-install-recommends \
	bc bison build-essential ca-certificates cpio dosfstools fdisk flex gcc-arm-linux-gnueabihf \
	git gpg kmod kpartx libssl-dev python3 python3-dev python3-setuptools rsync squashfs-tools \
	swig u-boot-tools wget

RUN git config --global advice.detachedHead false && \
	git config --global user.email nobody@example.org && \
	git config --global user.name nobody

WORKDIR "/src"
ENTRYPOINT [ ]
CMD [ "/bin/bash" ]
