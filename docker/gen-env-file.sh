#!/bin/bash
env_file="./.env"
VAR=$(getent group | grep -Po "video:\w:\K\d+") && echo "VIDEO_GROUP=${VAR}" >> ${env_file}
VAR=$(getent group | grep -Po "render:\w:\K\d+") && echo "RENDER_GROUP=${VAR}" >> ${env_file}
echo "USER=$(whoami)" >> ${env_file}

# DLM environment variables
echo "DLM_GPU_VENDOR=AMD" >> ${env_file}  
echo "DLM_SYSTEM_GPU_ARCHITECTURE=$(rocminfo | grep -o -m 1 'gfx.*' | xargs)" >> ${env_file}
#echo "DLM_SYSTEM_NGPUS=8" >> ${env_file}
#echo "DLM_RUNTIME_NGPUS=8" >> ${env_file}

# Tunable ops environment variables
echo "PYTORCH_TUNABLEOP_ENABLED=1" >> ${env_file}
echo "HIP_FORCE_DEV_KERNARG=1" >> ${env_file}
#echo "PYTORCH_TUNABLEOP_FILENAME= ??