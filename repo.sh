#!/bin/bash
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils openssl-devel zlib-devel pcre-devel gcc libtool perl-core openssl nano lynx
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.18.0-2.el7.ngx.src.rpm
wget https://www.openssl.org/source/latest.tar.gz
rpm -i nginx-1.18.0-2.el7.ngx.src.rpm
mv latest.tar.gz /root/rpmbuild/
cd /root/rpmbuild
tar -xf latest.tar.gz
rm /root/rpmbuild/latest.tar.gz
sed -i 's/--with-debug/--with-openssl=\/root\/rpmbuild\/openssl-1.1.1j/g' /root/rpmbuild/SPECS/nginx.spec
yum-builddep /root/rpmbuild/SPECS/nginx.spec
rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec
file=`ls -l /root/rpmbuild/RPMS/x86_64/ | grep nginx-1.18`
if ! [[ "$file" ]] 
then 
exit 
fi
namefile=`echo $file | awk '{print $9}'`
yum localinstall -y /root/rpmbuild/RPMS/x86_64/$namefile
systemctl start nginx
systemctl enable nginx

# Создание репо
rm /usr/share/nginx/html/*
mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/$namefile /usr/share/nginx/html/repo/
wget http://www.percona.com/downloads/percona-release/redhat/1.0-26/percona-release-1.0-26.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-26.noarch.rpm
createrepo /usr/share/nginx/html/repo/
createrepo --update /usr/share/nginx/html/repo/
sed -i '/index  index.html index.htm;/s/$/ \n\tautoindex on;/' /etc/nginx/conf.d/default.conf
nginx -s reload
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
yum clean all

echo FINISH
