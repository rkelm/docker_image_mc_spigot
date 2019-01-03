#!/bin/bash

errchk() {
    if [ "$1" != "0" ] ; then
	echo "$2"
	echo "Exiting."
	exit 1
    fi
}

echo Cleaning up build files.

project_dir=$( dirname "$0" )
project_dir=$( ( cd "$project_dir" && pwd ) )
echo "Project directory is ${project_dir}."
if [ -z "$project_dir" ] ; then
    errck 1 "Error: Could not determine project_dir."
fi

rm -frd ${project_dir}/apache-maven-*/
rm -frd ${project_dir}/BuildData/
rm -frd ${project_dir}/BuildTools.jar
rm -frd ${project_dir}/BuildTools.log.txt
rm -frd ${project_dir}/Bukkit/
rm -frd ${project_dir}/CraftBukkit/
rm -frd ${project_dir}/Dockerfile
rm -frd ${project_dir}/rootfs/
rm -frd ${project_dir}/Spigot/
rm -frd ${project_dir}/work/
