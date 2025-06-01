@echo off
"C:\Program Files\Eclipse Adoptium\jdk-17.0.15.6-hotspot\bin\java.exe" -Dcom.android.sdklib.toolsdir="D:\Android\Sdk\cmdline-tools\latest" -classpath "D:\Android\Sdk\cmdline-tools\latest\lib\sdkmanager.jar" com.android.sdklib.tool.sdkmanager.SdkManagerCli --sdk_root=D:\Android\Sdk "platform-tools" "platforms;android-33" "build-tools;33.0.0"
pause
