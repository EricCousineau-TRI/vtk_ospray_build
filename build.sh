#!/bin/bash
shopt -s expand_aliases

mkcd() { mkdir -p ${1} && cd ${1}; }
fhs-extend ()
{
    python_version=2.7
    local prefix=${1%/};
    export-prepend PYTHONPATH $prefix/lib:$prefix/lib/python${python_version}/dist-packages:$prefix/lib/python${python_version}/site-packages;
    export-prepend PATH $prefix/bin;
    export-prepend LD_LIBRARY_PATH $prefix/lib;
    export-prepend PKG_CONFIG_PATH $prefix/lib/pkgconfig:$prefix/share/pkgconfig;
}
export-prepend () 
{
    eval "export $1=\"$2:\$$1\""
}

cur=$(cd $(dirname $0) && pwd)
# rm -rf build
mkcd build

mkdir -p install
mkdir -p install/{bin,lib}
fhs-extend ~+/install

set -eux

(
    if [[ ! -d ${cur}/download ]]; then
        mkcd ${cur}/download
        curl -L https://astuteinternet.dl.sourceforge.net/project/ispcmirror/v1.9.2/ispc-v1.9.2-linux.tar.gz -O
    fi
)

(
    tar xfz ${cur}/download/ispc-v1.9.2-linux.tar.gz -C install/bin ispc-v1.9.2-linux/ispc --strip-components=1
)

(
    mkcd embree
    # https://github.com/embree/embree/issues/190
    cmake ../../embree \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=../install \
        $(echo "
        -DBUILD_SHARED_LIBS=ON
        -DBUILD_TESTING=OFF
        -DEMBREE_MAX_ISA=SSE4.2
        -DEMBREE_STACK_PROTECTOR=ON
        -DEMBREE_TUTORIALS=OFF
        ")
    make -j install
)

(
    mkcd ospray
    cmake ../../ospray \
        -DCMAKE_INSTALL_PREFIX=../install \
        -DCMAKE_BUILD_TYPE=Release \
        $(echo "
        -DBUILD_SHARED_LIBS=ON
        -DOSPRAY_ENABLE_APPS=OFF
        -DOSPRAY_ENABLE_TESTING=OFF
        ")
    make -j install
)

(
    rm -rf vtk
    mkcd vtk
    cmake ../../vtk \
        -DCMAKE_INSTALL_PREFIX=../install \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=../install \
        -DOSPRAY_INSTALL_DIR=1 \
        $(echo "
        -DBUILD_SHARED_LIBS=ON
        -DBUILD_TESTING=OFF
        -DModule_vtkRenderingOSPRay=ON
        -DVTK_ENABLE_VTKPYTHON=OFF
        -DVTK_Group_Qt=ON
        -DVTK_LEGACY_REMOVE=ON
        -DVTK_QT_VERSION=5
        -DVTK_USE_SYSTEM_EXPAT=ON
        -DVTK_USE_SYSTEM_FREETYPE=ON
        -DVTK_USE_SYSTEM_HDF5=ON
        -DVTK_USE_SYSTEM_JPEG=ON
        -DVTK_USE_SYSTEM_JSONCPP=ON
        -DVTK_USE_SYSTEM_LIBXML2=ON
        -DVTK_USE_SYSTEM_LZ4=ON
        -DVTK_USE_SYSTEM_NETCDF=ON
        -DVTK_USE_SYSTEM_NETCDFCPP=ON
        -DVTK_USE_SYSTEM_OGGTHEORA=ON
        -DVTK_USE_SYSTEM_PNG=ON
        -DVTK_USE_SYSTEM_TIFF=ON
        -DVTK_USE_SYSTEM_ZLIB=ON
        -DVTK_WRAP_PYTHON=ON
        ")
    make -j install
)
