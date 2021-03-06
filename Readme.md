# OTUS ДЗ Управление пакетами. Дистрибьюция софта (Centos 7)
-----------------------------------------------------------------------
### Домашнее задание

    Размещаем свой RPM в своем репозитории
    1) создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями)
    2) создать свой репо и разместить там свой RPM
        
1. Создание своего RPM
- Первым делом устанавливаем пакеты: ```yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils openssl-devel zlib-devel pcre-devel gcc```
- Скачиваем src.rpm - ```wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.18.0-2.el7.ngx.src.rpm ```
- Скачиваем исходники openssl ```wget https://www.openssl.org/source/latest.tar.gz```
- Распаковываем rpm пакет (распаковываются src и spec файл): ```rpm -i nginx-1.18.0-2.el7.ngx.src.rpm```
- Копируем в место распаковки rpm пакета исходники openssl: ```mv latest.tar.gz /root/rpmbuild/```
- Переходим в каталог rpmbuild ``cd /root/rpmbuild```

В папке SPECS лежит spec-файл. Файл, который описывает что и как собирать.
- Открываем файл ```nano SPECS/nginx.spec``` и добавляем в секцию %build необходимый нам модуль OpenSSL:
```
    --with-openssl=/root/rpmbuild/openssl-1.1.1j

```
- Устанавливаем зависимости - ```yum-builddep SPECS/nginx.spec```
- Собираем - ```rpmbuild -bb SPECS/nginx.spec```
- Видим два собранных пакета:
```
[root@lvm repo]# ls -l  /root/rpmbuild/RPMS/x86_64/
total 2796
-rw-r--r--. 1 root root  522868 Aug 27 13:51 nginx-1.18.0-2.el7.ngx.x86_64.rpm
-rw-r--r--. 1 root root 2335208 Aug 27 13:51 nginx-debuginfo-1.18.0-2.el7.ngx.x86_64.rpm
```
- Устанавливаем rpm пакет: ```yum localinstall -y RPMS/x86_64/nginx-1.18.0-2.el7.ngx.x86_64.rpm```
- Запускаем nginx - ```systemctl start nginx``` и можем посмотреть с какими параметрами nginx был скомпилирован ```nginx -V```

2. Создаем свой репозиторий
- Создаем папку в / нашего nginx - ```mkdir /usr/share/nginx/html/repo```
- Копируем наш скомпилированный пакет nginx в папку с будущим репозиторием - ```cp rpmbuild/RPMS/x86_64/nginx-1.18.0-2.el7.ngx.src.rpm /usr/share/nginx/html/repo/```
- Скачиваем дополнительно пакет - ```wget http://www.percona.com/downloads/percona-release/redhat/1.0-26/percona-release-1.0-26.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-26.noarch.rpm```
- Создаем репозиторий - ```createrepo /usr/share/nginx/html/repo/``` и ```createrepo --update /usr/share/nginx/html/repo/```
- В location / в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on.
```
autoindex on;

```
- Проверяем синтаксис ```nginx -t``` и ```nginx -s reload```
- Теперь можем просмотреть наши пакеты через HTTP - ```lynx http://localhost/repo/```
- Теперь чтобы протестировать репозиторий - создаем файл ``` /etc/yum.repos.d/otus.repo``` и вписываем в него следующее:
```
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
```
- Когда мы удаляем или добавляем пакеты в наш репозиторий, нам необходимо выполнить ```createrepo /usr/share/nginx/html/repo/``` и ```createrepo --update /usr/share/nginx/html/repo/```, 
после чего на всякий случай можем выполнить ```yum clean all``` и теперь ```yum list --showduplicates | grep otus```
