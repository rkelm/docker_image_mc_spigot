#!/bin/bash
echo Simple test run of docker image.
echo Test is successful if image runs and outputs 'Preparing spawn area:' with in 5 minutes.
echo Script retuns non-zero value if not successful.


if [ -z "$1" ] ; then
    echo "usage: test_simple_run.sh <name of image>"
    exit 1
fi

img_name="$1"
img_run_cmd='/opt/mc/bin/run_java_app.sh'
container_name="TEST-SIMPLE-RUN"
test_log_file="test_simple_run.log"
test_log_string_success="INFO]: Preparing spawn area: "

project_dir=$( dirname "$0" )
project_dir=$( ( cd "$project_dir" && pwd ) )
echo "Project directory is ${project_dir}."
if [ -z "$project_dir" ] ; then
    errck 1 "Error: Could not determine project_dir."
fi

echo "Running test: SIMPLE RUN"

# Test run, show container std output on screen.
( docker run --name "${container_name}" "${img_name}" "${img_run_cmd}" | tee "${project_dir}/${test_log_file}" & )

done=0
sleep_cnt=0
while [ "$done" == "0" ] ; do
    sleep 5;
    sleep_cnt=$(( $sleep_cnt + 5 ))
    # Wait max 5 minutes for log output.
    if [ "$sleep_cnt" -ge "300" ] ; then
	done=1
    fi
    
    if grep "${test_log_string_success}" "${project_dir}/${test_log_file}" ; then
	done=1
    fi
done

echo Removing test container.
docker rm -f "${container_name}"

# Check log
if grep "${test_log_string_success}" "${project_dir}/${test_log_file}" ; then
    echo "***** Test 'Simple Run' SUCCESSFUL *****"
    echo "String ""${test_log_string_success}"" found in log output."
else
    echo "***** Test 'Simple Run' FAILED *****"
    echo "String ""${test_log_string_success}"" not found in log output."
    exit 1
fi

