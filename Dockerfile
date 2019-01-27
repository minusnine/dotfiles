FROM debian:testing

RUN apt-get update && \
      apt-get -y install sudo

RUN useradd -m eric && echo "eric:eric" | chpasswd && adduser eric sudo
RUN echo "eric ALL = NOPASSWD: ALL" > /etc/sudoers.d/eric

USER eric
ENV USER eric
COPY . /home/eric/go/src/github.com/minusnine/dotfiles
RUN sudo chown -R eric:eric /home/eric
RUN sudo -u eric /home/eric/go/src/github.com/minusnine/dotfiles/bootstrap.sh
WORKDIR /home/eric
CMD /usr/bin/zsh -i -l
