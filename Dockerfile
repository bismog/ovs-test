FROM centos:7
RUN yum install -y openssh-clients openssh-server iproute 
RUN echo root:pass | chpasswd
EXPOSE 22

