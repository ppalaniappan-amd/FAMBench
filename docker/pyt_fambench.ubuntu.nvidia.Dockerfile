# CONTEXT {'gpu_vendor': 'NVIDIA', 'guest_os': 'UBUNTU'}
ARG BASE_DOCKER=nvidia/cuda:12.1.1-cudnn8-devel-ubuntu20.04
FROM $BASE_DOCKER
USER root
ENV WORKSPACE_DIR=/workspace
RUN mkdir -p $WORKSPACE_DIR
WORKDIR $WORKSPACE_DIR

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y \
    unzip \
    jq \
    python3-pip \
    git \
    vim \
    wget \
    numactl \
    openmpi-bin libopenmpi-dev

ENV PATH="/root/miniconda3/bin:${PATH}"
ARG PATH="/root/miniconda3/bin:${PATH}"
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    mkdir /root/.conda && \
    bash Miniconda3-latest-Linux-x86_64.sh -b && \
    rm -rf Miniconda3-latest-Linux-x86_64.sh && \
    /root/miniconda3/bin/conda install -y python=3.9 && \
    /root/miniconda3/bin/conda clean -afy

RUN conda --version && \
    conda init
RUN pip3 install --upgrade pip
RUN pip3 install typing-extensions
RUN pip3 install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu121

RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - |  tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main' |  tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    apt-get update && \
    apt-get install -y cmake

RUN pip3 install scikit-build ninja jinja2 hypothesis
RUN pip3 install scikit-learn tensorboard click

RUN echo "export CPLUS_INCLUDE_PATH=$( python3-config --includes | sed 's/-I/:/g' | sed 's/ //g' )" >> ~/.bashrc

RUN pip3 install transformers

# install apex
RUN git clone https://github.com/NVIDIA/apex && \
    cd apex && \
    pip3 install -r requirements.txt && \
    pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation --config-settings "--build-option=--cpp_ext" --config-settings "--build-option=--cuda_ext" ./ && \
    cd ..

RUN pip3 install "git+https://github.com/mlperf/logging.git"
RUN pip3 install tornado
RUN pip3 install tabulate
RUN pip3 install setuptools_git_versioning

# record configuration for posterity
RUN pip3 list
