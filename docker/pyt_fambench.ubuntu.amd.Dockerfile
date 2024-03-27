# CONTEXT {'gpu_vendor': 'AMD', 'guest_os': 'UBUNTU'}
# FBGEMM requires pytorch 1.11
ARG BASE_DOCKER=compute-artifactory.amd.com:5000/rocm-plus-docker/framework/compute-rocm-dkms-no-npi-hipclang:13710_ubuntu20.04_py3.9_pytorch_rocm6.2_internal_testing_de739ad
FROM $BASE_DOCKER
USER root
ENV WORKSPACE_DIR=/workspace
RUN mkdir -p $WORKSPACE_DIR
WORKDIR $WORKSPACE_DIR

# hipify-clang install may fail on older ROCm releases
RUN apt install -y hipify-clang || true
   
# ROCm gpg key
RUN wget -q -O - http://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
RUN apt update && apt install -y \
    unzip \
    jq \
    intel-mkl-full

# add sshpass, sshfs for downloading from mlse-nas
RUN apt-get install -y sshpass sshfs
RUN apt-get install -y netcat
RUN apt-get install numactl -y 

# add locale en_US.UTF-8
RUN apt-get install -y locales
RUN locale-gen en_US.UTF-8

# numpy is reinstalled because of pandas compatibility issues, remove the lines below once base image moves to numpy>1.20.3
RUN pip3 install -U numpy
RUN pip3 install -U scipy

# Workaround for the numpy/pip upgrade issue
# https://github.com/huggingface/transformers/issues/23076
RUN rm -rf /opt/conda/envs/py_3.9/lib/python3.9/site-packages/numpy*
RUN rm -rf /opt/conda/envs/py_3.10/lib/python3.10/site-packages/numpy*

# click for DLRM
RUN pip3 install click
RUN pip3 install setuptools==59.5.0 setuptools_git_versioning
RUN pip3 install jinja2
RUN pip3 install ninja
RUN pip3 install scikit-build
RUN pip3 install --upgrade hypothesis
RUN pip3 install --upgrade numpy

RUN pip3 install "git+https://github.com/mlperf/logging.git"
RUN pip3 install tornado
RUN pip3 install tabulate

RUN pip3 install transformers

# record configuration for posterity
RUN pip3 list
