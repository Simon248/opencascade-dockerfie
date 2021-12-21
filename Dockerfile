# We use Ubuntu image as OpenCascade (at least 7.4.0 won't compile on alpine).
FROM ubuntu:latest

# To avoid all sort of prompts from apt-get.
# You use this mode when you need zero interaction while installing or upgrading the system via apt.
# It accepts the default answer for all questions. It might mail an error message to the root user,
# but that's it all. Otherwise, it is totally silent and humble, a perfect frontend for automatic
# installs. One can use such mode in Dockerfile, shell scripts, cloud-init script, and more.
ENV DEBIAN_FRONTEND=noninteractive

# ======================
#  Prepare dependencies
# ======================

# Downloads the package lists from the repositories and "updates" them to get information on
# the newest versions of packages and their dependencies. It will do this for all repositories
# and PPAs.
RUN apt-get update

# The build-essentials packages are meta-packages that are necessary for compiling software.
# They include the GNU debugger, g++/GNU compiler collection, and some more tools and libraries
# that are required to compile a program. For example, if you need to work on a C/C++ compiler,
# you need to install essential meta-packages on your system before starting the C compiler installation.
# When installing the build-essential packages, some other packages such as G++, dpkg-dev, GCC and make, etc.
# also install on your system.
RUN apt-get -y install build-essential

# Git to clone OpenCascade from its github repo.
RUN apt-get -y install git

# OpenCascade is built with cmake.
RUN apt-get -y install cmake

# Deps for DRAW and dumping images to PNG (freeimage).
#
# TODO: Tk might not be necessary starting from OpenCascade 7.6 (to be checked).
#       (https://tracker.dev.opencascade.org/view.php?id=32232)
RUN apt-get -y install tcl tcl-dev tk tk-dev libfreeimage-dev

# libXmu provides a set of miscellaneous utility convenience functions for X libraries to use.
# libxi is X11 Input extension library (development headers).
#
# Without these, libTKService.so won't compile with linker errors saying
#
#    "/usr/bin/ld: cannot find -lXmu"
#    "/usr/bin/ld: cannot find -lXmi"
#
# TODO: Xlib might become optional (https://tracker.dev.opencascade.org/view.php?id=32308)
RUN apt-get -y install libxmu-dev libxi-dev

# /opencascade/src/InterfaceGraphic/InterfaceGraphic.hxx:41:10: fatal error: GL/glx.h: No such file or directory
#
# libglfw3-dev     : portable library for OpenGL, window and input (development files).
# libgl1-mesa-dev  : free implementation of the OpenGL API -- GLX development files.
# libglu1-mesa-dev : includes headers and static libraries for compiling programs with GLU.
RUN apt-get -y install libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev

# Xvfb provides an X server that can run on machines with no
# display hardware and no physical input devices. It emulates a
# dumb framebuffer using virtual memory.
RUN apt-get -y install xvfb

# ===========================================================
#  Clone OpenCascade from its public repo, build and install
# ===========================================================
 
# OpenCascade
RUN git clone https://github.com/Open-Cascade-SAS/OCCT.git opencascade
WORKDIR /opencascade
RUN git checkout V7_4_0 -b dev-branch
RUN mkdir -p build
WORKDIR /opencascade/build
RUN cmake .. \
       -DCMAKE_BUILD_TYPE=release \
       -DCMAKE_INSTALL_RPATH="" \
       -DCMAKE_INSTALL_PREFIX=/usr \
       -DUSE_FREEIMAGE=OFF \
       -DUSE_FFMPEG=OFF \
       -DUSE_VTK=OFF \
       -DUSE_TBB=OFF
RUN make
RUN make install

# To run interactively on Linux, use:
# ---
# > xhost +
# > docker run --rm -ti --net=host -e DISPLAY=:0 quaoarcad/opencascade:7_4_0
# ---
# On Unix-like operating systems, the xhost command is a server access control program for X.
# In our case, access is granted to everyone, even if they aren't on the list (i.e., access
# control is turned off).
#
# To run interactively on Windows, use the instruction provided
# by https://cuneyt.aliustaoglu.biz/en/running-gui-applications-in-docker-on-windows-linux-mac-hosts/
# To put it briefly, you'll need XLaunch, which is a Windows X-server. Then, notice that you'll have
# to supply it with the IP address, which you can find using `ipconfig` command. Just make sure to
# set 'Disable access control' flag in the XLaunch wizard.
# ---
# > docker run --rm -it -e DISPLAY=192.168.1.40:0.0 quaoarcad/opencascade:7_4_0
# ---
#
# Here:
#  --rm      automatically cleans up the container from the file system when the container exits.
#   -ti      is used for interactive processes (-t for tty allocation, -i to keep stdin open).
# --net=host gives the container full access to local system services.
#  -e        sets the environment variable.
#
# See also https://docs.docker.com/engine/reference/run/
