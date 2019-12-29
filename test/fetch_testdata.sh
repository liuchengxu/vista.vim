#!/usr/bin/env bash

try_download() {
  local testdata=$1
  local source=$2
  if [ -f "$testdata" ]; then
      echo "$testdata already exists"
  else
      echo "$testdata does not exist, downloading..."
      curl "$source" -o "$testdata"
  fi
}

try_download data/184.cpp https://raw.githubusercontent.com/PointCloudLibrary/pcl/master/io/src/pcd_io.cpp

try_download data/190.cpp https://raw.githubusercontent.com/opencv/opencv/master/modules/core/include/opencv2/core/mat.hpp

