#!/bin/bash
set -e
set -x

echo "Detected new GPU architecture: $DLM_SYSTEM_GPU_ARCHITECTURE"

git config --global --add safe.directory '*'
git submodule update --init
cd benchmarks/cvt/ootb

bash prep_env_data.sh

NODE_COUNT=1
RANK=0
MASTER_ADDR=$(hostname -I | awk '{print $1}')
DLM_MODEL_BATCH_SIZE=128 
DLM_MODEL_NUM_EPOCHS=300 

#DLM_RUNTIME_NGPUS=1
#MASTER_ADDR=$MASTER_ADDR NODE_COUNT=$NODE_COUNT RANK=$RANK bash run_cvt_train.sh $DLM_RUNTIME_NGPUS $DLM_MODEL_BATCH_SIZE $DLM_MODEL_NUM_EPOCHS 2>&1 | tee log.1gpu.txt

DLM_RUNTIME_NGPUS=8 
#clear checkpoints
rm -rf OUTPUT
# enable tunable ops
export PYTORCH_TUNABLEOP_ENABLED=1
# warmup run with 1 epoch to generate tunable op solutions
MASTER_ADDR=$MASTER_ADDR NODE_COUNT=$NODE_COUNT RANK=$RANK bash run_cvt_train.sh $DLM_RUNTIME_NGPUS $DLM_MODEL_BATCH_SIZE 1
# disable further tuning
export PYTORCH_TUNABLEOP_TUNING=0
#clear checkpoints
rm -rf OUTPUT
# final performance run
MASTER_ADDR=$MASTER_ADDR NODE_COUNT=$NODE_COUNT RANK=$RANK bash run_cvt_train.sh $DLM_RUNTIME_NGPUS $DLM_MODEL_BATCH_SIZE $DLM_MODEL_NUM_EPOCHS 2>&1 | tee log.1machine.txt

#val_1gpu=$(cat "log.1gpu.txt" | grep -oP "'performance', \K.*(?=\),)")
val_1machine=$(cat "log.1machine.txt" | grep -oP "'performance', \K.*(?=\),)")
metric="samples/s"

echo "model,performance,metric" > results_cvt.csv
#echo "1gpu,$val_1gpu,$metric" >> results_cvt.csv
echo "1machine,$val_1machine,$metric" >> results_cvt.csv
cp -v results_cvt.csv ../../../../
echo "performance: $val_1machine $metric"
