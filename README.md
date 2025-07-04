<div align="center">
<h1 align="center">
</h1>
<h1 align="center">
DAEA: code for "A Duplication Analysis-Based Evolutionary Algorithm for Biobjective Feature Selection"
</h1>

[![Platform](https://img.shields.io/badge/Platform-MATLAB-orange)](https://www.mathworks.com/products/matlab.html)
[![Dataset](https://img.shields.io/badge/Dataset-Included-green)](https://github.com/zongtingwei/Feature-Selection-FS-datasets)

[Source Code](https://github.com/zongtingwei/DAEA)
| [Documentation](https://ieeexplore.ieee.org/abstract/document/9165863)
| [Dataset](https://github.com/zongtingwei/Feature-Selection-FS-datasets)

</div>
<br>

## 📖 Introduction

DAEA is a MATLAB-based evolutionary algorithm designed for solving biobjective feature selection problems in classification tasks. It leverages duplication analysis to enhance the efficiency and effectiveness of the feature selection process.

This implementation is based on the code of [SM-MOEA](https://github.com/BIMK/SM-MOEA) and [PlatEMO](https://github.com/BIMK/PlatEMO). Please refer to the original paper [A Duplication Analysis-Based Evolutionary Algorithm for Biobjective Feature Selection](https://ieeexplore.ieee.org/abstract/document/9165863) for detailed information about the algorithm's overview, methodology, and benchmark results.

DAEA_FS was developed for feature selection tasks in classification. The framework can be adapted to other feature selection scenarios with minor modifications.

<img src="./assets/figs/overview.png" alt="DAEA_FS" style="zoom:50%;">

## 🔥 News

+ 2020.04 🎉🎉 **DAEA_FS Paper Published** [“A Duplication Analysis-Based Evolutionary Algorithm for Biobjective Feature Selection”](https://ieeexplore.ieee.org/abstract/document/9165863) in IEEE Transactions on Evolutionary Computation!

## 💡 Features of our package

| Feature | Support / To be supported |
|---------|---------------------------|
| **Efficient Feature Selection** | 🔥Support |
| **Duplication Analysis** | 🔥Support |
| **Multi-Objective Optimization** | 🔥Support |
| **Classification Task Support** | 🔥Support |
| **MATLAB Implementation** | 🔥Support |
| **Integration with PlatEMO** | 🔥Support |
| **High-Dimensional Data Support** | 🔥Support |
| **More Application Scenarios** | 🚀Coming soon |

## 🎁 Requirements & Installation

> [!Important]
> This implementation requires MATLAB. Ensure you have MATLAB installed on your system.

> [!Note]
> The code is based on SM-MOEA and PlatEMO. Please download the required libraries if necessary.

### How to Run

1. Download the code and dataset from the repository.
2. Open MATLAB and set the working directory to the project root.
3. Run the `main_DAEA.m` script.
4. Use the provided "colon.mat" file in the "dataset" folder for testing.

```matlab
% Example code snippet to run DAEA_FS
addpath('path/to/DAEA_FS/code');
data = load('dataset/colon.mat');
% Configure parameters as needed
% Run the algorithm
results = main_DAEA(data);
disp(results);
