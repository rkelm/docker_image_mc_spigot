#!/bin/bash
# Delete any existing symbolic links to plugins.
for filename in "${SERVER_DIR}/plugins/*.jar" ; do
    if test -L "$filename" && rm "${filename}"
done
