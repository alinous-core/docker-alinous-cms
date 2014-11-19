FROM centos:latest
MAINTAINER Tomohiro Iizuka

RUN yum update -y

# install ssh
RUN yum install -y openssh-server
RUN mkdir -p /var/run/sshd

RUN sed -ri 's/^#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i '/pam_loginuid\.so/s/required/optional/' /etc/pam.d/sshd

RUN ssh-keygen -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N ""
RUN ssh-keygen -t dsa -b 1024 -f /etc/ssh/ssh_host_dsa_key -N ""
RUN ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -t ecdsa -N ""

# install git
RUN yum install -y git

# install java
RUN yum install java-1.7.0-openjdk.x86_64 -y

# install and setup PostgreSQL
RUN yum install postgresql-server -y
RUN su postgres -c "initdb -D /var/lib/pgsql/data"
RUN su postgres -c "cd /var/lib/pgsql/data && pg_ctl -w -D /var/lib/pgsql/data -l logfile start && createdb -w apcms"


# Runtime script
ADD script/run.sh /bin/run.sh
RUN chmod +x /bin/run.sh

# git repositories
RUN mkdir /opt/repo.git && \
  cd /opt/repo.git && \
  git --bare init --share

ADD script/hook/post-receive /opt/repo.git/hooks/post-receive
RUN chmod +x /opt/repo.git/hooks/post-receive

RUN mkdir /opt/tomcat.git && \
  cd /opt/tomcat.git && \
  git --bare init --share

ADD script/hook-tomcat/post-receive /opt/tomcat.git/hooks/post-receive
RUN chmod +x /opt/tomcat.git/hooks/post-receive

# setup Tomcat
ADD apache-tomcat-8.0.15.tar.gz /root/apache-tomcat-8.0.15
RUN mv /root/apache-tomcat-8.0.15/apache-tomcat-8.0.15 /usr/local/tomcat
RUN cd /usr/local/tomcat/webapps && rm -rf ./ROOT && rm -rf ./docs && \
	rm -rf ./host-manager && rm -rf ./manager && \
	rm -rf ./examples
ADD ROOT.war /usr/local/tomcat/webapps/ROOT.war
ADD script/tomcatignore.txt /usr/local/tomcat/.gitignore

RUN cd /usr/local/tomcat/ && \
  git config --global user.email "you@example.com" && \
  git init && \
  git add -A && \
  git commit -m "init" && \
  git remote add origin /opt/tomcat.git && \
  git push origin master

# cms
RUN mkdir /opt/work && \
  cd /opt/work && \
  git init

ADD ALINOUS_HOME/ /opt/work/ALINOUS_HOME/
ADD script/alinousignore.txt /opt/work/.gitignore

RUN cd /opt/work && \
  git add -A && \
  git commit -m "init" && \
  git remote add origin /opt/repo.git && \
  git push origin master

EXPOSE 5432 8080 22

RUN echo 'root:pass' | chpasswd

CMD ["/bin/run.sh"]


