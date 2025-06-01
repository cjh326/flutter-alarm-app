@echo off
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.15.6-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo y | D:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --licenses
echo y | D:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat "platform-tools" "build-tools;33.0.0" "platforms;android-33"

pause
