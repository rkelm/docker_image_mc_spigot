ARG APP_VERSION
FROM rkelm/minecraft_vanilla:$APP_VERSION

ENV APP_VERSION $APP_VERSION
ENV APP_NAME Spigot Minecraft
ENV JAR_FILE spigot-$APP_VERSION.jar
ENV JAR_FILE_VANILLA minecraft_server.$APP_VERSION.jar
ENV PLUGINS_JAR_DIR $INSTALL_DIR/plugins_jar

# Delete old jar file.
RUN rm ${APP_DIR}/${JAR_FILE_VANILLA}
# Create Directory for plugin jar files.
RUN mkdir -p ${PLUGINS_JAR_DIR}

ADD rootfs /

RUN echo -e ' ************************************************** \n' \
  "Docker Image to run app ${APP_NAME} ${APP_VERSION}. \n" \
  '\n' \
  'Usage: \n' \
  "   Start service: docker run -v <host-server-data-dir>:${INSTALL_DIR}/server \\ \n" \
  "                             -d <image_name> ${INSTALL_DIR}/bin/run_java_app.sh \n" \
  "   Stop service:  docker exec ${INSTALL_DIR}/bin/stop_java_app.sh \n" \
  "   Send command:  docker exec ${INSTALL_DIR}/bin/app_cmd.sh  \\ \n" \
  "                              '<cmd1> <param1-1> <param1-2> ..' \\ \n" \
  "                              '<cmd2> <param2-1> <param2-2> ..'   \n" \
  "                  Every app command and its parameters must be single or double quoted. \n" \
'**************************************************' > /image_info.txt

VOLUME ["${SERVER_DIR}", "${SERVER_DIR}/logs"]

EXPOSE 25565 25575

CMD ["/bin/cat", "/image_info.txt"]
