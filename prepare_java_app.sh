#!/bin/ash
# Create links for all plugins in server directory.
for filename in "${APP_DIR}/plugins/*.jar" ; do
    test -e "$filename" || continue 
    ln -f -s "${filename}" "${SERVER_DIR}/plugins/$(basename $filename)"
done
