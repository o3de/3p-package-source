#
# Copyright (c) Contributors to the Open 3D Engine Project.
# For complete copyright and license terms please see the LICENSE at the root of this distribution.
#
# SPDX-License-Identifier: Apache-2.0 OR MIT
#

# This Dockerscript is based off of a built docker image for the ispc compiler so that the 
# ISPC Text Compression library can use the ispc compiler
FROM ispc_cpu_env:latest
 
WORKDIR /data/workspace

ENV LANG=en_US.UTF-8

ARG CACHEBUST=1

# Copy the externally synced source code to this image
RUN mkdir -p /data/workspace/src
COPY src  /data/workspace/src/

# Copy the ispc compiler from the base docker image into the expected path where the source expects it to be 
RUN mkdir -p /data/workspace/src/ISPC/linux && \
    cp /home/src/ispc/build/bin/ispc /data/workspace/src/ISPC/linux/

ENTRYPOINT ["/bin/bash", "-c"]
