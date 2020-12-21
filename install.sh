# Only for Ubuntu 20.04 LTS
# Before you use this shell script, 
# it"s extremely recommended that you change your apt source to proper mirror.
# For some sources from Github, you may config proxy globally.

# Check Ubuntu Version
if [ $(lsb_release -sc) != "focal" ]; then
    exit
fi

export http_proxy=http://127.0.0.1:58591
export https_proxy=http://127.0.0.1:58591

ogre_version=v1.12.10
opencv_version=4.5.0

# Update Sources
sudo -E apt update

# Install Base Tools
sudo -E apt install build-essential net-tools git cmake cmake-qt-gui

# Install Java Development Kits
sudo -E apt install openjdk-11-jdk

# Install Python Development Environments
sudo -E apt install python3.8-dev python3.8-doc python3.8-dbg python3-distutils-extra

# Intel MKL - Optional
if [[ $(cat /proc/cpuinfo | grep "model name")=~"Intel" ]]
then
    # Get Public Key for Intel oneAPI Sources
    sudo -E apt-key adv --fetch-keys https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
    
    # Configure the APT client to use Intel"s repository
    sudo cp oneAPI.list /etc/apt/sources.list.d/

    # Update Sources
    sudo -E apt-get update

    # Install Intel MKL(Math Kernel Library)
    sudo -E apt install -y intel-oneapi-mkl-devel 

    # Set Intel MKL Environment Variables
    if [ -d "/opt/intel/oneapi" ]; then
    	echo "source /opt/intel/oneapi/setvars.sh" | sudo tee /etc/profile.d/intel-oneapi.sh
    	source /opt/intel/oneapi/setvars.sh
    fi
fi

# NVIDIA CUDA - Optional
if [[ $(lspci | grep "VGA compatible controller")=~"NVIDIA" ]]
then
    # Get Public Key for NVIDIA CUDA Sources
    sudo -E apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub
    
    # Configure the APT client to use NVIDIA"s repository
    sudo -E add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
    
    # Install NVIDIA CUDA
    sudo -E apt-get -y install cuda libcusolver10 libcudnn8 libcudnn8-dev
fi

# Python PIP
sudo -E apt install -y python3-pip
# Update PIP
sudo -E -H pip3 install -U pip setuptools wheel

# Python Numpy
sudo -E apt install -y python3-numpy
# Update Numpy
sudo -E -H pip3 install -U numpy

# Tensorflow
sudo -E -H pip3 install -U tensorflow
# PyTorch
sudo -E -H pip3 install -U torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio===0.7.2 -f https://download.pytorch.org/whl/torch_stable.html

# Qt Creator
sudo -E apt install -y qtcreator

# OpenCV Dependencies - CCache
sudo -E apt install -y ccache

# OpenCV Dependencies - BLAS
sudo -E apt install -y libblas-dev libblas64-dev
# OpenCV Dependencies - LAPACK
sudo -E apt install -y liblapack-dev liblapack64-dev
# OpenCV Dependencies - LAPACKE
sudo -E apt install -y liblapacke-dev liblapacke64-dev
# OpenCV Dependencies - ATLAS
sudo -E apt install -y libatlas-base-dev libatlas-cpp-0.6-dev
# OpenCV Dependencies - OpenBLAS
sudo -E apt install -y libopenblas-dev libopenblas64-dev

# OpenCV Dependencies - GTK & VTK
sudo -E apt install -y libgtk-3-dev libvtk7-dev
# OpenCV Dependencies - Images
sudo -E apt install -y zlib1g-dev libjpeg-turbo8-dev libwebp-dev libpng-dev libtiff-dev libopenjp2-7-dev libopenexr-dev
# OpenCV Dependencies - Videos
sudo -E apt install -y libdc1394-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libavresample-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

# OpenCV Dependencies - Java Supports
sudo -E apt install -y ant
# Ant - Fix Link Bug
sudo -E rm -rf /usr/bin/ant && sudo -E ln -s /usr/share/ant/bin/ant /usr/bin/ant

# OpenCV Dependencies - Google Glog & Gflags
sudo -E apt install -y libgflags-dev libgoogle-glog-dev
# OpenCV Dependencies - Others
sudo -E apt install -y libboost-all-dev libtesseract-dev

# OpenCV Dependencies - OGRE
git clone https://github.com/ogrecave/ogre
# OGRE Dependencies
sudo -E apt install -y libgles2-mesa-dev libxt-dev libxaw7-dev libsdl2-dev libfreetype-dev libfreeimage-dev nvidia-cg-toolkit
# OGRE Build
cd ./ogre
git checkout $ogre_version
mkdir build
cd ./build
cmake ..
make clean
make -j$(grep 'processor' /proc/cpuinfo | sort -u | wc -l) -l$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
sudo -E make install
cd ../..

# OpenCV Clone
git clone https://github.com/opencv/opencv
# OpenCV Contribution Clone
git clone https://github.com/opencv/opencv_contrib
# OpenCV Build
cd ./opencv_contrib
git checkout $opencv_version
cd ../opencv
git checkout $opencv_version
mkdir build
cd ./build
cmake .. -G "Unix Makefiles"
cmake ..\
    -DCMAKE_BUILD_TYPE:STRING="Release" \
    -DOPENCV_EXTRA_MODULES_PATH:PATH="../../opencv_contrib/modules" \
    -DWITH_JASPER:BOOL="0" \
    -DBUILD_JASPER:BOOL="1" \
    -DWITH_CUDA:BOOL="1" \
    -DOPENCV_DNN_CUDA:BOOL="1" \
    -DCUDA_ARCH_BIN:STRING="5.2;6.0;6.1;7.0;7.5;8.0;8.6" \
    -DOPENCV_GENERATE_PKGCONFIG:BOOL="1" \
    -DOPENCV_PYTHON3_VERSION:BOOL="1"
make clean
make -j$(grep 'processor' /proc/cpuinfo | sort -u | wc -l) -l$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
sudo -E make install/fast
