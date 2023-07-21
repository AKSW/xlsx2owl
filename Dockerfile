# YARRRML + RMLMapper

FROM openjdk:17-bullseye
# we want a debian for nodejs install later on, bullseye = debian v11

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN cat /etc/os-release && java -version
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -
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

COPY xlsx2owl.sh yarrrml.yml /home/user/
COPY tools /home/user/tools
COPY resources /home/user/resources

VOLUME ["/data"]
#COPY resources /home/user/data/resources
WORKDIR /data
ENTRYPOINT ["/bin/bash", "/home/user/xlsx2owl.sh"]
