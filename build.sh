#!/bin/bash

if [ -z $1 ] ; then
    echo "usage: $(basename $0) <mc_version>"
    echo "requirements"
    echo "    openjdk-8-jre-headless"
    echo "    git"
    exit 1
fi

errchk() {
    if [ "$1" != "0" ] ; then
	echo "$2"
	echo "Exiting."
	exit 1
    fi
}

# ***** Configuration *****
# Assign configuration values here or set environment variables before calling script.
rconpwd="$BAKERY_RCONPWD"
local_repo_path="$BAKERY_LOCAL_REPO_PATH"
remote_repo_path="$BAKERY_REMOTE_REPO_PATH"
repo_name="spigot_minecraft_2"

# Some options may be edited directly in the Dockerfile.master.

if [ -z "$rconpwd" ] || [ -z "$local_repo_path" ] || [ -z "$remote_repo_path" ] ; then
    errchk 1 'Configuration variables in script not set. Assign values in script or set corresponding environment variables.'
fi

app_version=$1
image_tag=$app_version

# project_dir="$(echo ~ubuntu)/docker_work/spigot_mc"
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

# Prepare rootfs.
jar_file=minecraft_server.${app_version}.jar
rootfs="${project_dir}/rootfs"

echo "Cleaning up rootfs from previous build."
rm -frd "$rootfs"

mkdir -p ${rootfs}/opt/mc/server
mkdir -p ${rootfs}/opt/mc/server/world_the_end
mkdir -p ${rootfs}/opt/mc/server/world_nether
mkdir -p ${rootfs}/opt/mc/jar
mkdir -p ${rootfs}/opt/mc/bin

cp prepare_java_app.sh ${rootfs}/opt/mc/bin
chmod ug+x "${rootfs}/opt/mc/bin/prepare_java_app.sh"
cp unprepare_java_app.sh ${rootfs}/opt/mc/bin
chmod ug+x "${rootfs}/opt/mc/bin/unprepare_java_app.sh"

# Download BuildTools.
#if [ ! -e "${build_tools_jar}"  ] ; then
# Always download fresh BuildTools.jar.

#fi

if [ ! -e "${spigot_jar}" ] ; then
    curl -o "${build_tools_jar}" "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"    # Prepare git.
    git config --global --unset core.autocrlf
    # Compile spigot.
    java -jar BuildTools.jar -rev "${app_version}"
    chmod +x "${spigot_jar}"
fi

cp "${spigot_jar}" "${rootfs}/opt/mc/jar/"

# Rewrite base image tag in Dockerfile. (ARG Variables support in FROM starting in docker v17.)
echo '# This file is automatically created from Dockerfile.master. DO NOT EDIT! EDIT Dockerfile.master!' > "${project_dir}/Dockerfile"
sed "s/SED_REPLACE_TAG_APP_VERSION/${app_version}/g" "${project_dir}/Dockerfile.master" >> "${project_dir}/Dockerfile"

# Build.
echo "Building $local_repo_tag"
docker build "${project_dir}" --build-arg RCONPWD="${rconpwd}" --build-arg APP_VERSION="${app_version}" -t "${local_repo_tag}"

errchk $? 'Docker build failed.'

# Get image id.
image_id=$(docker images -q "${local_repo_tag}")

test -n $image_id
errchk $? 'Could not retrieve docker image id.'
echo "Image id is ${image_id}."

# Tag for Upload to aws repo.
echo "Re-tagging image for upload to remote repository."
docker tag "${image_id}" "${remote_repo_tag}"
errchk $? "Failed re-tagging image ${image_id}".

# Upload.
echo "Execute the following commands to upload the image to remote aws repository."
echo '   $(aws ecr get-login --no-include-email --region eu-central-1)'
echo "   docker push ${remote_repo_tag}"
