#!/bin/bash
# Create links for all plugins in server directory.
mkdir -p "${SERVER_DIR}/plugins"
for filename in ${PLUGINS_JAR_DIR}/*.jar ; do
    echo prepare_java_app: $filename
    test -e "$filename" || continue
    echo prepare_java_app: linking plugin jar $filename to ${SERVER_DIR}/plugins/$(basename $filename)
    ln -s "${filename}" "${SERVER_DIR}/plugins/$(basename $filename)"
done
