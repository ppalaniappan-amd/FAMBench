#!/bin/bash
set -e

# Initialize variables  
perf_flag=false  
config_flag=false  
trace_flag=false  

# Parse command-line arguments  
while [ "$#" -gt 0 ]; do  
    case "$1" in  
        -p) echo "Performance mode is ON"  
            perf_flag=true  
            shift  
            ;;  
        -c) echo "Config collection mode is ON"   
            config_flag=true  
            shift  
            ;;  
        -t) echo "Trace collection mode is ON"   
            trace_flag=true  
            shift  
            ;;  
        *)  echo "Unknown option: $1"  
            echo "Usage: $0 [-p](performance) [-c](config collection) [-t](trace collection)"  
            exit 1  
            ;;  
    esac  
done

# create output directory based on GPU vendor
output_dir="/workspace/RESULTS" 
if test -n "$(lspci | grep -i 'amd')"; then
    output_dir+="_AMD" 
else
    output_dir+="_NVIDIA" 
fi
if [ -d "$output_dir" ]; then  
    rm -r "$output_dir"  
fi
mkdir "$output_dir"    

# install RPD tracer if its not available
package_name="rpdTracerControl"
if python -c "import $package_name" 2>/dev/null; then  
    echo "Python package '$package_name' is installed."  
else  
    echo "Python package '$package_name' is not installed."
    rpd_dir="rocmProfileData"
    if [ -d "$rpd_dir" ]; then  
        rm -r "$rpd_dir"  
    fi
    git clone https://github.com/ROCm/rocmProfileData.git
    cd rocmProfileData
    apt-get install sqlite3 libsqlite3-dev
    apt-get install libfmt-dev
    make; make install
    cd ..  
fi  

git config --global --add safe.directory '*'
git submodule update --init
cd benchmarks/cvt/ootb

bash prep_env_data.sh

NODE_COUNT=1
RANK=0
MASTER_ADDR=$(hostname -I | awk '{print $1}')
DLM_MODEL_BATCH_SIZE=256 
DLM_RUNTIME_NGPUS=8 

# always set this flag for best performance
export HIP_FORCE_DEV_KERNARG=1

# performance mode
if $perf_flag; then
    rm -rf OUTPUT
    # run performance for 300 epochs
    DLM_MODEL_NUM_EPOCHS=300 
    MASTER_ADDR=$MASTER_ADDR NODE_COUNT=$NODE_COUNT RANK=$RANK bash run_cvt_train.sh $DLM_RUNTIME_NGPUS $DLM_MODEL_BATCH_SIZE $DLM_MODEL_NUM_EPOCHS 2>&1 | tee log.1machine.txt
    val_1machine=$(cat "log.1machine.txt" | grep -oP "'performance', \K.*(?=\),)")
    metric="samples/s"
    echo "model,performance,metric" > results_cvt.csv
    echo "1machine,$val_1machine,$metric" >> results_cvt.csv
    echo "performance: $val_1machine $metric"
    cp results_cvt.csv $output_dir/
fi

# config collection mode
# config to be collected only on MI300, it can be modified to run on H100
if $config_flag; then
    rm -rf OUTPUT
    export MIOPEN_ENABLE_LOGGING_CMD=1
    export ROCBLAS_LAYER=6
    # collect config for 1 epoch
    DLM_MODEL_NUM_EPOCHS=1 
    MASTER_ADDR=$MASTER_ADDR NODE_COUNT=$NODE_COUNT RANK=$RANK bash run_cvt_train.sh $DLM_RUNTIME_NGPUS $DLM_MODEL_BATCH_SIZE $DLM_MODEL_NUM_EPOCHS
    unset MIOPEN_ENABLE_LOGGING_CMD
    unset ROCBLAS_LAYER
    cp OUTPUT/miopen_configs_cvt.csv $output_dir/
    cp OUTPUT/rocblas_bench_configs_cvt.csv $output_dir/
    cp OUTPUT/rocblas_function_configs_cvt.csv $output_dir/
fi

# before running this step, make sure line 146 (rpd_tracing) in benchmark/cvt/ootb/CvT/tools/train.py is set to True
# trace collection mode
if $trace_flag; then
    # create empty rpd trace file
    python -m rocpd.schema --create $output_dir/trace.rpd
    rm -rf OUTPUT
    # trace will be captured for 5th epoch
    DLM_MODEL_NUM_EPOCHS=10 
    MASTER_ADDR=$MASTER_ADDR NODE_COUNT=$NODE_COUNT RANK=$RANK bash run_cvt_train.sh $DLM_RUNTIME_NGPUS $DLM_MODEL_BATCH_SIZE $DLM_MODEL_NUM_EPOCHS
    # save original trace
    cp /workspace/trace.rpd $output_dir/trace.rpd
    cp /workspace/trace.rpd $output_dir/trace_original.rpd
    rm /workspace/trace.rpd
    # rearrange trace
    python -m rocpd.autograd $output_dir/trace.rpd
    # get both kernels and aten operators
    sqlite3 -header -csv $output_dir/trace.rpd "select * from autogradKernel;" > $output_dir/aten_operator_performance.csv
    sqlite3 -header -csv $output_dir/trace.rpd "select * from top;" > $output_dir/kernel_performance.csv
    # get json file for visualizing using chrome tracing
    python /workspace/rocmProfileData/tools/rpd2tracing.py $output_dir/trace_original.rpd $output_dir/trace.json
fi
