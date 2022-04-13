#!/bin/bash

if [ -z $1 ] ; then
    echo "usage: $(basename $0) <mc_version>"
    echo "requirements"
    echo "    openjdk-8-jre-headless"
    echo "    git"
    exit 1
fi

# ***** Configuration *****
# Assign configuration values here or set environment variables before calling script.
rconpwd="$BAKERY_RCONPWD"
local_repo_path="$BAKERY_LOCAL_REPO_PATH"
remote_repo_path="$BAKERY_REMOTE_REPO_PATH"
repo_name="minecraft_spigot"

# Some options may be edited directly in the Dockerfile.master.
java_16="/usr/lib/jvm/java-16-openjdk-amd64/bin/java"
java_17="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"


# ***** Functions *****
errchk() {
    if [ "$1" != "0" ] ; then
	echo "$2"
	echo "Exiting."
	exit 1
    fi
}

ver_cmp() {
    local IFS=.
    local V1=($1) V2=($2) I
    for ((I=0 ; I<${#V1[*]} || I<${#V2[*]} ; I++)) ; do
	[[ ${V1[$I]:-0} -lt ${V2[$I]:-0} ]] && echo -1 && return
	[[ ${V1[$I]:-0} -gt ${V2[$I]:-0} ]] && echo 1 && return
    done
    echo 0
}

ver_ge() {
    [[ ! $(ver_cmp "$1" "$2") -eq -1 ]]
}


# ***** Initialize *****
if [ -z "$rconpwd" ] || [ -z "$local_repo_path" ] || [ -z "$remote_repo_path" ] ; then
    errchk 1 'Configuration variables in script not set. Assign values in script or set corresponding environment variables.'
fi

app_version=$1
image_tag=$app_version

# The project directory is the folder containing this script.
project_dir=$( dirname "$0" )
project_dir=$( ( cd "$project_dir" && pwd ) )
echo "Project directory is ${project_dir}."
if [ -z "$project_dir" ] ; then
    errck 1 "Error: Could not determine project_dir."
fi

if [ -n "$image_tag" ] ; then
    local_repo_tag="${local_repo_path}/${repo_name}:${image_tag}"
    remote_repo_tag="${remote_repo_path}/${repo_name}:${image_tag}"    
else
    local_repo_tag="${local_repo_path}:${repo_name}"
    remote_repo_tag="${remote_repo_path}:${repo_name}"
fi

build_tools_jar="${project_dir}/BuildTools.jar"
spigot_jar="${project_dir}/spigot-${app_version}.jar"
craftbukkit_jar="${project_dir}/craftbukkit-${app_version}.jar"

# ***** Prepare *****
# Prepare rootfs.
jar_file=minecraft_server.${app_version}.jar
rootfs="${project_dir}/rootfs"

echo "Cleaning up rootfs from previous build."
rm -frd "$rootfs"

mkdir -p ${rootfs}/opt/mc/server
mkdir -p ${rootfs}/opt/mc/server/world
mkdir -p ${rootfs}/opt/mc/server/world_the_end
mkdir -p ${rootfs}/opt/mc/server/world_nether
mkdir -p ${rootfs}/opt/mc/jar
mkdir -p ${rootfs}/opt/mc/bin
mkdir -p ${rootfs}/opt/mc/plugins_jar

cp prepare_java_app.sh ${rootfs}/opt/mc/bin
chmod ug+x "${rootfs}/opt/mc/bin/prepare_java_app.sh"
cp unprepare_java_app.sh ${rootfs}/opt/mc/bin
chmod ug+x "${rootfs}/opt/mc/bin/unprepare_java_app.sh"

# Set java version for running BuildTools.jar.
if ver_ge "${app_version}" "1.18" ; then
    java="${java_17}"
elif ver_ge "${app_version}" "1.12" ; then
    java="${java_16}"
else
    errchk 1 "$1 ist an unssupported Mincecraft version."
fi

# Download BuildTools.
if [ ! -e "${spigot_jar}" ] ; then
    curl -o "${build_tools_jar}" "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
    errchk $? "Download of spigot BuildTools.jar failed."
    # Prepare git.
    git config --global --unset core.autocrlf
    # Compile spigot.
    "${java}" -jar BuildTools.jar -rev "${app_version}"
    errchk $? "Build of spigot jar file ${spigot_jar} failed."
    chmod +x "${spigot_jar}"
else
    echo "Skipping build of ${spigot_jar} and using existing version. To force rebuild, delete ${spigot_jar}."
fi

cp "${spigot_jar}" "${rootfs}/opt/mc/jar/"

# Rewrite base image tag in Dockerfile. (ARG Variables support in FROM starting in docker v17.)
#echo '# This file is automatically created from Dockerfile.master. DO NOT EDIT! EDIT Dockerfile.master!' > "${project_dir}/Dockerfile"
#sed "s/SED_REPLACE_TAG_APP_VERSION/${app_version}/g" "${project_dir}/Dockerfile.master" >> "${project_dir}/Dockerfile"

# Build.
echo "Building $local_repo_tag"
docker build "${project_dir}" --no-cache --build-arg APP_VERSION="${app_version}" -t "${local_repo_tag}" -f Dockerfile

errchk $? 'Docker build failed.'

# Get image id.
image_id=$(docker images -q "${local_repo_tag}")

test -n $image_id
errchk $? 'Could not retrieve docker image id.'
echo "Image id is ${image_id}."


# ***** Test *****
echo "***** Testing image *****"
"${project_dir}/test/test_simple_run.sh" "${local_repo_path}/${repo_name}:${image_tag}"
errchk $? "Test failed."

# Tag for Upload to aws repo.
if [ ! -z "$BAKERY_REMOTE_REPO_PATH" ] ; then
    echo "Re-tagging image for upload to remote repository."
    docker tag "${image_id}" "${remote_repo_path}/${repo_name}:${image_tag}"
    errchk $? "Failed re-tagging image ${image_id}."
else
    echo "Environment variable BAKERY_REMOTE_REPO_PATH not set. Skipping retagging image." 
fi

# Upload image if necessary env vars are set.
if [ ! -z "$BAKERY_REMOTE_REPO_PATH" ] && [ ! -z "$AWS_ACCESS_KEY_ID" ] && [ ! -z "$AWS_SECRET_ACCESS_KEY" ] && \
       [ ! -z "$AWS_DEFAULT_REGION" ] ; then
    echo "Logging in to aws account."
    $(aws ecr get-login --no-include-email --region eu-central-1)
    echo "Pushing ${remote_repo_path}/${repo_name}:${image_tag} to remote repository."
    docker push "${remote_repo_path}/${repo_name}:${image_tag}"
else
    echo "Execute the following commands to upload the image to remote aws repository."
    echo '   $(aws ecr get-login --no-include-email --region eu-central-1)'
    echo "   docker push ${remote_repo_path}/${repo_name}:${image_tag}"
fi
