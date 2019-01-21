FROM debian:testing

RUN apt-get update && \
      apt-get -y install sudo

RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

COPY . /app
CMD /app/bootstrap.sh
