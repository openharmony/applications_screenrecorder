#!/bin/bash
#
# Copyright (c) Huawei Device Co., Ltd. 2026. All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -ex

device_type=$2

if [ "$1"x = "clean"x ];
then
    echo "Not a build-command, skip now!"
    exit 0
fi

TEMP=$(getopt --longoptions PversionCode:,PversionName:,no-daemon:,Dhttp.socketTimeout:,Dhttp.connectionTimeout: --alternative -- "$@")

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"
declare -A myMap
while true ; do
    case "$1" in
        --PversionCode)
            case "$2" in
                *) version_code=$2;shift 2 ;;
            esac ;;
        --PversionName)
            case "$2" in
                *) version_name=$2;shift 2 ;;
            esac ;;
        --) shift ; break ;;
        *) echo "Other arguments \`$1' \`$2'" ; break ;;
    esac
done

if [ -z "$version_code" ]
then
    echo "version_code:$version_code, version_name:$version_name"
else
    sed -i "s/1000000/$version_code/g" AppScope/app.json5
    sed -i "s/1\.0\.0/$version_name/g" AppScope/app.json5
fi

echo 'app.json5:'
cat AppScope/app.json5

DIR_NAME=$(ls ${HOS_SDK_HOME}| tr -d "\r")
cp ${HM_SDK_HOME}/${DIR_NAME}/openharmony/toolchains/lib/hap-sign-tool.jar ./hw_sign/hap-sign-tool.jar
wget -nc --no-check-certificate
cp ./hapsign-online-plugin.jar ./hw_sign/hapsign-online-plugin.jar

export NODE_HOME="${NODE_HOME%/bin}"
echo "NODE_HOME is ${NODE_HOME}"
echo "nodejs.dir=${NODE_HOME}" >> ./local.properties
echo "sdk.dir=${HM_SDK_HOME}"  >> ./local.properties
echo "hwsdk.dir=${HM_SDK_HOME}" >> ./local.properties

hvigorw clean --no-daemon

ohpm install

hvigorw assembleHar --mode module -p product=default -p debuggable=false -p module=common

echo "install common dependency for screenRecorder"

cd feature/screenRecorder && ohpm install && cd ../../

hvigorw assembleHar --mode module -p product=default -p debuggable=false -p module=screenRecorder

echo "install hap dependency"

cd product/phone && ohpm install && cd ../../
cd product/pad && ohpm install && cd ../../
cd product/pc && ohpm install && cd ../../

echo "package Hap"

if [[ "${device_type}" == "tv" ]];
then
  # build hap (main: entry module)
  hvigorw --mode module -p module=tv -p debuggable=false -p ohos-test-coverage=true -p buildMode=test assembleHap --parallel --incremental --no-daemon --stacktrace
  # build test hap (ohosTest)
  hvigorw --mode module -p module=tv@ohosTest -p debuggable=false -p ohos-test-coverage=true assembleHap packageTesting --no-daemon --stacktrace
else
  # build hap (main: entry module)
  hvigorw --mode module -p module=phone -p debuggable=false -p ohos-test-coverage=true -p buildMode=test assembleHap --parallel --incremental --no-daemon --stacktrace
  # build test hap (ohosTest)
  hvigorw --mode module -p module=phone@ohosTest -p debuggable=false -p ohos-test-coverage=true assembleHap packageTesting --no-daemon --stacktrace
fi

hvigorw assembleHap --mode module -p product=default -p debuggable=false --no-daemon

# 将feature层源码及common层源码拷贝到output下
mkdir -p ./build/outputs/ScreenRecorder/source/common/src
cp -r ./common/src ./build/outputs/ScreenRecorder/source/common/
mkdir -p ./build/outputs/ScreenRecorder/source/feature/screenRecorder/src
cp -r ./feature/screenRecorder/src ./build/outputs/ScreenRecorder/source/feature/screenRecorder/

echo "-----------------handle DTPipeline.zip--------------------"
has_package_dt_pipeline=0
if [ -e "build/DTPipeline.zip" ]; then
  file_size=$(stat -c%s "build/DTPipeline.zip")
  if [ $file_size -gt 0 ]; then
    echo "DTPipeline.zip is normal"
  else
    echo "DTPipeline.zip size is 0"
  fi
  rm -rf build/DTPipeline.zip
  has_package_dt_pipeline=1
else
  echo "build/DTPipeline.zip is not exist"
  has_package_dt_pipeline=1
fi

if [ $has_package_dt_pipeline -eq 1 ]; then
  if ! [ -d "build/outputs" ]; then
    echo "build/outputs is not exist"
    exit 1
  fi
  pushd build/outputs
  zip -r ../DTPipeline.zip ./*
  popd
fi

# rename output hap
cp ./product/phone/build/default/outputs/default/phone-default-signed.hap ./product/phone/build/default/outputs/default/ScreenRecorder.hap
cp ./product/pad/build/default/outputs/default/pad-default-signed.hap ./product/pad/build/default/outputs/default/ScreenRecorder.hap
cp ./product/pc/build/default/outputs/default/pc-default-signed.hap ./product/pc/build/default/outputs/default/ScreenRecorder.hap