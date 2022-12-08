#!/bin/sh

#根据Podfile检查平台，iOS or macOS
platform=iOS
platform_name=_$platform
platform_name_line=`grep $platform_name Podfile|awk 'NR==1{print}'`
if [[ ! $platform_name_line ]]; then
    platform=macOS
fi

#根据Podfile检查是否是纯语音sdk
audio_only=false
local_podspec_name=AgoraRtcEngine_$platform
pod_rtc_line=`grep $local_podspec_name Podfile|awk 'NR==1{print}'`
if [[ ! $pod_rtc_line ]]; then
    audio_only=true
    local_podspec_name=AgoraAudio_$platform
    pod_rtc_line=`grep $local_podspec_name Podfile|awk 'NR==1{print}'`
fi

if [[ $pod_rtc_line == *:path* ]]; then
    sdk_path=${pod_rtc_line#*:path}
    sdk_path=${sdk_path#*\'}
    local_sdk_path=${sdk_path%\'*}
fi

if [[ $local_sdk_path ]]; then
    local_podspec_file=$local_sdk_path/$local_podspec_name.podspec
    if [[ -f $local_podspec_file ]]; then
        echo "$local_podspec_file exist!"
    else
        echo "create $local_podspec_file"
        
        spec_platform=:ios,9.0
        if [[ $platform == macOS ]]; then
            spec_platform=:osx,10.10
        fi

        sdk_version=$RTC_SDK_VERSION
        if [ ! $sdk_version ]; then
            sdk_version=1.0
        fi
        
        spec_name=AgoraRtcEngine_$platform
        if [[ $audio_only == true  ]]; then
            spec_name=AgoraAudio_$platform
        fi
        
        touch $local_podspec_file
        echo "# AgoraRtcEngine" > $local_podspec_file
        
        sed -i '' '$a\
Pod::Spec.new do |spec| \
   spec.name          = "'${spec_name}'" \
   spec.version       = "'${sdk_version}'" \
   spec.summary       = "Agora '${platform}' SDK" \
   spec.description   = "'${platform}' library for agora A/V communication, broadcasting and data channel service." \
   spec.homepage      = "https://docs.agora.io/en/Agora%20Platform/downloads" \
   spec.license       = { "type" => "Copyright", "text" => "Copyright 2022 agora.io. All rights reserved.\n"} \
   spec.author        = { "Agora Lab" => "developer@agora.io" } \
   spec.platform      = '${spec_platform}' \
   spec.source        = { :git => "" } \
   spec.vendored_frameworks = "*.xcframework" \
end '   $local_podspec_file
        
    fi
fi
