import re
import argparse
import csv
from collections import OrderedDict


class CvtLogParser:
    def __init__(self, last_steps):
        super(CvtLogParser, self).__init__()
        self.last_steps = last_steps
    
    def process_trace(self, path, regex):
        config_cnt = {}
        with open(file=path, mode="r", encoding="UTF-8") as f:
            for line in f:
                match = regex.search(line)
                if match:
                    if match.group(0) in config_cnt:
                        config_cnt[match.group(1)] += 1
                    else:
                        config_cnt[match.group(1)] = 1
        return config_cnt

    def parse(self, path):
        print(f"Parsing {path}")
        performance_regex = re.compile(
            ".*Speed (?P<performance>[0-9]*\.[0-9]*) samples/s.*"
        )

        performances = []

        with open(file=path, mode="r", encoding="UTF-8") as f:
            for line in f:
                match = performance_regex.match(line)
                if match:
                    performance = float(match["performance"])
                    performances.append(performance)

        metrics = OrderedDict()

        if len(performances) > 0:
            metrics["performance_step"] = self.last_steps
            metrics["performance"] = sum(performances[-self.last_steps :]) / 10
            metrics["metrics"] = "samples/s"

        print(metrics)
        return metrics


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--logpath", type=str, default="cvt.log", help="log path"
    )
    parser.add_argument("--steps", type=int, default=80, help="gpus * 10")
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = get_args()
    parser = CvtLogParser(last_steps=args.steps)
    logfile = args.logpath

    metric = parser.parse(logfile)

    labels = list(metric.keys())
    try:
        with open(f"metrics.csv", "w") as f:
            writer = csv.DictWriter(f, fieldnames=labels)
            writer.writeheader()
            writer.writerow(metric)
    except IOError:
        print("I/O error")

    miopen_regex = re.compile(r"MIOpen\(HIP\): Command \[.*\] (./bin/MIOpenDriver .*)$")
    miopen_config_cnt = parser.process_trace(logfile, miopen_regex)
    rocblas_bench_regex = re.compile(r"(./rocblas-bench .*)$")
    rocblas_bench_cnt = parser.process_trace(logfile, rocblas_bench_regex)
    rocblas_function_regex = re.compile(r"(^.*rocblas_function: .*)$")
    rocblas_function_cnt = parser.process_trace(logfile, rocblas_function_regex)
    fields = ['config', 'calls']
    try:
        with open(f"configs_cvt.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerow(fields)
            for config in miopen_config_cnt:
                writer.writerow([config, miopen_config_cnt[config]])
            for config in rocblas_bench_cnt:
                writer.writerow([config, rocblas_bench_cnt[config]])
            for config in rocblas_function_cnt:
                writer.writerow([config, rocblas_function_cnt[config]])
    except IOError:
        print("I/O error")
