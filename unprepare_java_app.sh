#!/bin/bash
# Delete any existing symbolic links to plugins.
for filename in ${SERVER_DIR}/plugins/*.jar ; do
    if test -L "${filename}" ; then
	 echo "unprepare_java_app.sh: Removing link ${filename}."
	rm "${filename}"
    fi
done
