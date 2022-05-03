# YARRRML + RMLMapper

FROM openjdk:8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
# took hint for version 14 from an official yarrrml docker file
# a current node.js version (at least node.js 17.x) seems to cause problems
#RUN curl -sL https://deb.nodesource.com/setup_current.x | bash -

RUN apt-get update -qq && apt-get install -qq --no-install-recommends \
        nodejs \
    # check nodejs and npm(installed automatically) was installed successful
    && echo -n "node.js version: " && node -v \
    && echo -n "npm version: " && npm -v

# change group id to group that has permissions to read input and write result!
RUN groupadd --system -g 1000 user \
    # Change user id (-u) to user that has permissions to read input and write result!
    && useradd --system -s /bin/bash -g user -u 1000 user --create-home
RUN mkdir /data && chown user:user /data

USER user:user
WORKDIR /home/user

RUN npm install @rmlio/yarrrml-parser

COPY xlsx2owl-StahlDigital.sh yarrrml.yml /home/user/
COPY tools /home/user/tools
COPY resources /home/user/resources

VOLUME ["/data"]
#COPY resources /home/user/data/resources
WORKDIR /data
ENTRYPOINT ["/bin/bash", "/home/user/xlsx2owl-StahlDigital.sh"]
