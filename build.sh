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

rm -rf build
mkcd build

mkdir install
mkdir -p install/{bin,lib}
fhs-extend ~+/install

set -eux

(
    mkcd download

    curl -L https://astuteinternet.dl.sourceforge.net/project/ispcmirror/v1.9.2/ispc-v1.9.2-linux.tar.gz -O
    tar xfz ispc-v1.9.2-linux.tar.gz -C ../install/bin ispc-v1.9.2-linux/ispc --strip-components=1
)

(
    mkcd embree
    # https://github.com/embree/embree/issues/190
    cmake ../../embree \
        -DCMAKE_INSTALL_PREFIX=../install \
        -DEMBREE_TUTORIALS=OFF \
        -DEMBREE_ISA_AVX512KNL=OFF \
        -DEMBREE_ISA_AVX512SKX=OFF \
        -DEMBREE_TASKING_SYSTEM=TBB
    make -j install
)

(
    mkcd ospray
    cmake ../../ospray \
        -DCMAKE_INSTALL_PREFIX=../install \
        -DCMAKE_BUILD_TYPE=Debug \
        -DOSPRAY_TASKING_SYSTEM=TBB
    make -j install
)

(
    rm -rf vtk
    mkcd vtk
    cmake ../../vtk \
        -DCMAKE_INSTALL_PREFIX=../install \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Debug \
        -DModule_vtkRenderingOSPRay=ON \
        -DOSPRAY_INSTALL_DIR=../install \
        -DVTK_Group_Qt=ON \
        -DVTK_LEGACY_REMOVE=ON \
        -DVTK_QT_VERSION=5 \
        -DVTK_USE_SYSTEM_EXPAT=ON \
        -DVTK_USE_SYSTEM_FREETYPE=ON \
        -DVTK_USE_SYSTEM_HDF5=ON \
        -DVTK_USE_SYSTEM_JPEG=ON \
        -DVTK_USE_SYSTEM_JSONCPP=ON \
        -DVTK_USE_SYSTEM_LIBXML2=ON \
        -DVTK_USE_SYSTEM_LZ4=ON \
        -DVTK_USE_SYSTEM_NETCDF=ON \
        -DVTK_USE_SYSTEM_NETCDFCPP=ON \
        -DVTK_USE_SYSTEM_OGGTHEORA=ON \
        -DVTK_USE_SYSTEM_PNG=ON \
        -DVTK_USE_SYSTEM_TIFF=ON \
        -DVTK_USE_SYSTEM_ZLIB=ON \
        -DVTK_WRAP_PYTHON=ON
    make -j install
)
