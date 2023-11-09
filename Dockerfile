# YARRRML + RMLMapper
FROM node:21-alpine
#FROM openjdk:19-bullseye
# we want a debian for nodejs install later on, bullseye = debian v11

# update packages and install more software
# * bash: for our bash script
# * shadow: offers 'groupadd' and 'useradd'
# * curl: needed by xlsx2owl
# * python3: needed by xlsx2csv
RUN apk update && apk upgrade && apk add bash shadow curl python3

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN cat /etc/os-release \
    && echo -n "node.js version: " && node -v \
    && echo -n "npm version: " && npm -v

# copy openjdk from eclipse-temurin as documented at https://github.com/docker-library/docs/blob/master/eclipse-temurin/README.md#using-a-different-base-image
ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:21-alpine $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"
RUN java -version

# change group id to group that has permissions to read input and write result!
RUN groupadd --system -g 1010 user \
    # Change user id (-u) to user that has permissions to read input and write result!
    && useradd --system -s /bin/bash -g user -u 1010 user --create-home
RUN mkdir /data && chown user:user /data
USER user:user
WORKDIR /home/user

# install yarrrml parser
RUN npm install @rmlio/yarrrml-parser@v1.6.1

# copy xlsx2owl files
COPY xlsx2owl.sh yarrrml.yml /home/user/
COPY tools /home/user/tools
COPY resources /home/user/resources

# define docker metadata
VOLUME ["/data"]
WORKDIR /data
ENTRYPOINT ["/bin/bash", "/home/user/xlsx2owl.sh"]
