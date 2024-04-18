#!/bin/bash
set -e
set -x

DLM_GPU_ARCHITECTURE='none'
status="$(lspci | grep -i 'amd')"
if test -n "$status"
then
    DLM_GPU_ARCHITECTURE='amd'
else
    DLM_GPU_ARCHITECTURE='nvidia'
fi

echo "Detected GPU architecture: $DLM_GPU_ARCHITECTURE"

git config --global --add safe.directory '*'
git submodule update --init
cd benchmarks/cvt/ootb

bash prep_env_data.sh

NODE_COUNT=1
RANK=0
MASTER_ADDR=$(hostname -I | awk '{print $1}')
DLM_MODEL_BATCH_SIZE=256 
DLM_MODEL_NUM_EPOCHS=1

# collect configs for 1 epoch
rm -rf OUTPUT
export MIOPEN_ENABLE_LOGGING_CMD=1
export ROCBLAS_LAYER=6
MASTER_ADDR=$MASTER_ADDR NODE_COUNT=$NODE_COUNT RANK=$RANK bash run_cvt_train.sh $DLM_RUNTIME_NGPUS $DLM_MODEL_BATCH_SIZE 1 2>&1 | tee log.1machine.configs.txt
unset MIOPEN_ENABLE_LOGGING_CMD
unset ROCBLAS_LAYER

#rocblas_configs=$(cat "log.1machine.txt" | grep -E "rocblas-bench") 
#echo $rocblas_configs > 