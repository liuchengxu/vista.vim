#!/usr/bin/env bash

try_download() {
  local testdata=$1
  local source=$2
  if [ -f "$testdata" ]; then
      echo "$testdata already exists"
<<<<<<< HEAD
  else 
=======
  else
>>>>>>> 39a8cc2c8bc87281f2638af3c415b3871ff4d2d6
      echo "$testdata does not exist, downloading..."
      curl "$source" -o "$testdata"
  fi
}

try_download data/184.cpp https://raw.githubusercontent.com/PointCloudLibrary/pcl/master/io/src/pcd_io.cpp

try_download data/190.cpp https://raw.githubusercontent.com/opencv/opencv/master/modules/core/include/opencv2/core/mat.hpp

