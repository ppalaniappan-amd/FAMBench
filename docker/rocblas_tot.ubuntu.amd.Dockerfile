FROM rocm/pytorch-private:rocm13360_445_ubuntu22.04_py3.9_pytorch_tunablegemm-temp_aed2c82_with_apex_v2

WORKDIR /root

RUN apt update && apt install -y openmpi-bin libopenmpi-dev

#build rocblas
#ex1: docker build -t rocm/rocblas:streamk -f Dockerfile.rocblas . --no-cache 
#ex2: docker build -t rocm/rocblas:develop -f Dockerfile.rocblas . --no-cache  --build-arg ROCBLAS_REPO="https://github.com/ROCm/rocBLAS" \
#      --build-arg ROCBLAS_BRANCH="develop"   --build-arg ROCBLAS_INSTALL_CMD_ARGS="-dci -a gfx942 --cmake_install" 
ARG ROCBLAS_REPO=https://github.com/ROCm/rocBLAS
ARG ROCBLAS_BRANCH=develop
ARG ROCBLAS_INSTALL_CMD_ARGS="-dci -a gfx942 --cmake_install"
RUN pip install joblib
RUN git clone "$ROCBLAS_REPO" rocBLAS-repo; \
   cd rocBLAS-repo ; \
   git checkout "$ROCBLAS_BRANCH"; \
   git show --oneline -s ; \
   ./install.sh $ROCBLAS_INSTALL_CMD_ARGS 

ADD . /root/ 
