FROM ubuntu:bionic

RUN apt-get update

# Qt5 build dependencies
RUN apt-get -y install git python make g++ clang gperf bison flex libnss3-dev libxrandr-dev libdbus-1-dev libxi-dev libxtst-dev libxcomposite-dev libxcursor-dev libc++-dev libc++abi-dev libssl-dev libfontconfig1-dev libxcb1-dev libglu1-mesa-dev mesa-common-dev libxkbcommon-x11-dev libxkbcommon-dev libx11-xcb-dev libxcb-xkb-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-render-util0-dev libxcb-xinerama0-dev libxcb-xinput-dev libwebp-dev libopus-dev --fix-missing

# Developer Tools
RUN apt-get -y install vim

# LY build dependencies
RUN apt-get -y install build-essential
RUN apt-get -y install libgl-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev libsdl2-2.0-0 libsdl2-dev
RUN apt-get -y install clang-6.0 libc++-dev libc++abi-dev uuid-dev libz-dev libncurses5-dev libcurl4-openssl-dev libjpeg-dev libjbig-dev libpython3.7
 
RUN update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100
RUN update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100

RUN apt-get -y install wget
RUN wget -qO - https://package.perforce.com/perforce.pubkey | apt-key add -
RUN echo "deb http://package.perforce.com/apt/ubuntu bionic release" > /etc/apt/sources.list.d/perforce.list
RUN apt-get update
RUN apt-get -y install helix-p4d

VOLUME /data