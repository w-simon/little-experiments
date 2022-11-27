
- download

$ git clone https://github.com/w-simon/little-experiments.git && cd little-experiments

- init submodules

$ git submodule update --init --recursive

- prepare crosstools (from https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_toolchain/)

$ mkdir -f tools/cross && pushd tools/cross &&  wget https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_toolchain/gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz && tar xfJ gcc-arm-11.2-2022.02-x86_64-aarch64-none-linux-gnu.tar.xz && popd
