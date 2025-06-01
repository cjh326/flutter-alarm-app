@echo off
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.15.6-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"

REM 创建licenses目录（如果不存在）
if not exist "D:\Android\Sdk\licenses" mkdir "D:\Android\Sdk\licenses"

REM 创建license文件
echo 24333f8a63b6825ea9c5514f83c2829b004d1fee> "D:\Android\Sdk\licenses\android-sdk-license"

REM 安装Android SDK组件
call D:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=D:\Android\Sdk "platform-tools" "platforms;android-33" "build-tools;33.0.0"

pause
