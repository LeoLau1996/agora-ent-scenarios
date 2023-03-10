# --------------------------------------------------------------------------------------------------------------------------
# =====================================
# ========== Guidelines ===============
# =====================================
#
# -------------------------------------
# ---- Common Environment Variable ----
# -------------------------------------
# ${Package_Publish} (boolean): Indicates whether it is build package process, e.g. If you want to get one CI SDK package.
# ${Clean_Clone} (boolean): Indicates whether it is clean build. If true, CI will clean ${output} for each build process.
# ${is_tag_fetch} (boolean): If true, git checkout will work as tag fetch mode.
# ${is_official_build} (boolean): Indicates whether it is official build release.
# ${arch} (string): Indicates build arch set in build pipeline.
# ${short_version} (string): CI auto generated short version string.
# ${release_version} (string): CI auto generated version string.
# ${build_date} (string(yyyyMMdd)): Build date generated by CI.
# ${build_timestamp} (string (yyyyMMdd_hhmm)): Build timestamp generated by CI.
# ${platform} (string): Build platform generated by CI.
# ${BUILD_NUMBER} (string): Build number generated by CI.
# ${WORKSPACE} (string): Working dir generated by CI.
#
# -------------------------------------
# ------- Job Custom Parameters -------
# -------------------------------------
# If you added one custom parameter via rehoboam website, e.g. extra_args.
# You could use $extra_args to get its value.
#
# -------------------------------------
# ------------- Input -----------------
# -------------------------------------
# ${source_root}: Source root which checkout the source code.
# ${WORKSPACE}: project owned private workspace.
#
# -------------------------------------
# ------------- Output ----------------
# -------------------------------------
# Generally, we should put the output files into ${WORKSPACE}
# 1. for pull request: Output files should be zipped to test.zip, and then copy to ${WORKSPACE}.
# 2. for pull request (options): Output static xml should be static_${platform}.xml, and then copy to ${WORKSPACE}.
# 3. for others: Output files should be zipped to anything_you_want.zip, and then copy it to {WORKSPACE}.
#
# -------------------------------------
# --------- Avaliable Tools -----------
# -------------------------------------
# Compressing & Decompressing: 7za a, 7za x
#
# -------------------------------------
# ----------- Test Related ------------
# -------------------------------------
# PR build, zip test related to test.zip
# Package build, zip package related to package.zip
#
# -------------------------------------
# ------ Publish to artifactory -------
# -------------------------------------
# [Download] artifacts from artifactory:
# python3 ${WORKSPACE}/artifactory_utils.py --action=download_file --file=ARTIFACTORY_URL
#
# [Upload] artifacts to artifactory:
# python3 ${WORKSPACE}/artifactory_utils.py --action=upload_file --file=FILEPATTERN --project
# Sample Code:
# python3 ${WORKSPACE}/artifactory_utils.py --action=upload_file --file=*.zip --project
#
# [Upload] artifacts folder to artifactory
# python3 ${WORKSPACE}/artifactory_utils.py --action=upload_file --file=FILEPATTERN --project --with_folder
# Sample Code:
# python3 ${WORKSPACE}/artifactory_utils.py --action=upload_file --file=./folder --project --with_folder
#
# ========== Guidelines End=============
# --------------------------------------------------------------------------------------------------------------------------


echo Package_Publish: $Package_Publish
echo is_tag_fetch: $is_tag_fetch
echo arch: $arch
echo source_root: ${source_root}
echo output: /tmp/jenkins/${project}_out
echo build_date: $build_date
echo build_time: $build_time
echo release_version: $release_version
echo short_version: $short_version
echo pwd: `pwd`

# enter android project direction
cd Android

# config android environment
source ~/.bashrc
export ANDROID_HOME=/usr/lib/android_sdk
ls ~/.gradle || mkdir -p /tmp/.gradle && ln -s /tmp/.gradle ~/.gradle && touch ~/.gradle/ln_$(date "+%y%m%d%H") && ls ~/.gradle
echo ANDROID_HOME: $ANDROID_HOME
java --version


# config app global properties
sed -ie "s#$(sed -n '/SERVER_HOST/p' gradle.properties)#SERVER_HOST=${SERVER_HOST}#g" gradle.properties
sed -ie "s#$(sed -n '/AGORA_APP_ID/p' gradle.properties)#AGORA_APP_ID=${APP_ID}#g" gradle.properties
sed -ie "s#$(sed -n '/AGORA_APP_CERTIFICATE/p' gradle.properties)#AGORA_APP_CERTIFICATE=${APP_CERT}#g" gradle.properties
cat gradle.properties

# config applicationId
sed -ie "s#$(sed -n '/applicationId/p' gradle.properties)#applicationId ${packageName}#g" app/build.gradle
cat app/build.gradle

# config voice properties
voicePropFile=scenes/voice/voice/voice_gradle.properties
rm -f $voicePropFile
touch $voicePropFile
echo "isBuildTypesTest=false\n" >> $voicePropFile
echo "AGORA_APP_ID_RELEASE=\"${APP_ID}\"\n" >> $voicePropFile
echo "AGORA_APP_CERTIFICATE_RELEASE=\"${APP_CERT}\"\n" >> $voicePropFile
echo "IM_APP_KEY_RELEASE=\"${IM_APP_KEY}\"\n" >> $voicePropFile
echo "TOOLBOX_SERVER_HOST_RELEASE=\"${TOOLBOX_SERVER_HOST}\"\n" >> $voicePropFile
echo "IM_APP_CLIENT_ID_RELEASE=\"${IM_CLIENT_ID}\"\n" >> $voicePropFile
echo "IM_APP_CLIENT_SECRET_RELEASE=\"${IM_CLIENT_SECRET}\"\n" >> $voicePropFile
cat $voicePropFile

# Compile apk
./gradlew clean || exit 1
./gradlew :app:assembleRelease || exit 1

# Upload apk
rm -rf ${WORKSPACE}/*.apk && cp app/build/outputs/apk/release/*.apk ${WORKSPACE}

