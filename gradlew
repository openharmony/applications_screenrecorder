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
if [ "$1"x = "clean"x ];
then
    echo "Not a build-command, skip now!"
    exit 0
fi

TEMP=`getopt --longoptions PversionCode:,PversionName:,no-daemon:,Dhttp.socketTimeout:,Dhttp.connectionTimeout: --alternative -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"
declare -A myMap
while true ; do
    case "$1" in
        --PversionCode)
            case "$2" in
                *) versionCode=$2;shift 2 ;;
            esac ;;
        --PversionName)
            case "$2" in
                *) versionName=$2;shift 2 ;;
            esac ;;
        --) shift ; break ;;
        *) echo "Other arguments \`$1' \`$2'" ; break ;;
    esac
done

if [ -z "$versionCode" ]
then
    echo "versionCode:$versionCode, versionName:$versionName"
else
    sed -i "s/1000000/$versionCode/g" AppScope/app.json5
    sed -i "s/1\.0\.0/$versionName/g" AppScope/app.json5
fi

echo 'app.json5:'
cat AppScope/app.json5

# 安装ohpm, 若镜像中已存在ohpm，则无需重新安装
function init_ohpm
{
    TOOLS_INSTALL_DIR=`pwd`
    echo "start to download ohpm"
    # 下载
    commandlineVersion=2.0.1.0
    wget --no-check-certificate -q "" -O ohcommandline-tools-linux.zip
    unzip -oq ohcommandline-tools-linux.zip

    # 初始化
    echo "start to init ohpm"
    OHPM_HOME=${TOOLS_INSTALL_DIR}/oh-command-line-tools/ohpm
    ${OHPM_HOME}/bin/init
    export PATH=${OHPM_HOME}/bin:${PATH}
    ohpm_version=$(ohpm -v)
    echo "ohpm version: ${ohpm_version}"

    # 配置仓库地址
    echo "start to config ohpm"
    ohpm config set registry
    ohpm config set strict_ssl false
}

cp ${HM_SDK_HOME}/openharmony/12/toolchains/lib/hap-sign-tool.jar ./hw_sign/hap-sign-tool.jar
wget -nc --no-check-certificate
cp ./hapsign-online-plugin.jar ./hw_sign/hapsign-online-plugin.jar

export NODE_HOME="${NODE_HOME%/bin}"
echo "NODE_HOME is ${NODE_HOME}"
echo "nodejs.dir=${NODE_HOME}" >> ./local.properties
echo "sdk.dir=${HM_SDK_HOME}"  >> ./local.properties
echo "hwsdk.dir=${HM_SDK_HOME}" >> ./local.properties

ohpm config set registry
ohpm config set registry
ohpm config set @cloud:registry
ohpm config set @ohos:registry
ohpm config set strict-ssl false

npm config set registry
npm config set @ohos:registry
npm config set @ohoswidget:registry
npm config set strict-ssl false
echo 'lockfile=false' >> ${HOME}/.npmrc

init_ohpm

ohpm install

./hvigorw clean --no-daemon

./hvigorw assembleHar --mode module -p product=default -p debuggable=false -p module=common

echo "install common dependency for screenRecorder"

cd feature/screenRecorder && ohpm install && cd ../../

./hvigorw assembleHar --mode module -p product=default -p debuggable=false -p module=screenRecorder

echo "install hap dependency"

cd product/phone && ohpm install && cd ../../

echo "package Hap"

# build hap (main: entry module)
./hvigorw --mode module -p module=phone -p debuggable=false -p ohos-test-coverage=true -p buildMode=test assembleHap --parallel --incremental --no-daemon --stacktrace
# build test hap (ohosTest)
./hvigorw --mode module -p module=phone@ohosTest -p debuggable=false -p ohos-test-coverage=true assembleHap packageTesting --no-daemon --stacktrace

./hvigorw assembleHap --mode module -p product=default -p debuggable=false --no-daemon

echo "-----------------handle DTPipeline.zip--------------------"
hasPackageDTPipeline=0
if [ -e "build/DTPipeline.zip" ];then
  file_size=$(stat -c%s "build/DTPipeline.zip")
  if [ $file_size -gt 0 ]; then
    echo "DTPipeline.zip is normal"
  else
    hasPackageDTPipeline=1
    rm -rf build/DTPipeline.zip
    echo "DTPipeline.zip size is 0"
  fi
else
  hasPackageDTPipeline=1
  echo "build/DTPipeline.zip is not exist"
fi
if [ $hasPackageDTPipeline -eq 1 ];then
  pushd build/outputs
  if [ $? -ne 0 ];then
         echo "build/outputs is not exist"
         exit 1
  fi
  zip -r ../DTPipeline.zip ./*
  popd
fi