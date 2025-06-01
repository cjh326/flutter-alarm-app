@echo off
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.15.6-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"
"%JAVA_HOME%\bin\java" -jar "D:\Android\Sdk\cmdline-tools\latest\lib\sdkmanager.jar" --sdk_root=D:\Android\Sdk "platform-tools" "platforms;android-33" "build-tools;33.0.0"
pause
