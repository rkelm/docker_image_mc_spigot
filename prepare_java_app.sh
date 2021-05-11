#!/bin/bash
# Create links for all plugins in server directory.
mkdir -p "${SERVER_DIR}/plugins"
for filename in ${PLUGINS_JAR_DIR}/*.jar ; do
    test -e "${SERVER_DIR}/plugins/$(basename $filename)" || continue
    echo prepare_java_app: Linking plugin jar $filename to ${SERVER_DIR}/plugins/$(basename $filename)
    ln -s "${filename}" "${SERVER_DIR}/plugins/$(basename $filename)"
done
