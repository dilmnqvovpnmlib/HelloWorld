FROM i386/centos:6

RUN sed -i 's/$basearch/i386/g' /etc/yum.repos.d/CentOS-*.repo && \
    ln -sf /usr/share/zoneinfo/Japan /etc/localtime

RUN sed -i -e "s/^mirrorlist=http:\/\/mirrorlist.centos.org/#mirrorlist=http:\/\/mirrorlist.centos.org/g" /etc/yum.repos.d/CentOS-Base.repo && \
    sed -i -e "s/^#baseurl=http:\/\/mirror.centos.org/baseurl=http:\/\/vault.centos.org/g" /etc/yum.repos.d/CentOS-Base.repo

RUN yum update -y && \
    yum install -y gcc && \
    yum install -y glibc-static && \
    yum install -y vim

# Setting .bashrc
RUN { \
    echo "alias ll='ls -l'"; \
    echo "alias la='ls -A'"; \
    echo "alias l='ls -CF'"; \
    echo "alias o='objdump'"
    echo "PS1='\[\e[1;34m\][\u@\h \W]\\$ \[\e[m\]'"; \
  } > ~/.bashrc

WORKDIR /app

CMD ["/bin/bash"]