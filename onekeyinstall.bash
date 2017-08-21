#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function SetPassword(){
	stty erase '^H' && read -p '[Notice] Please input password:' DefaultPassword;
	if [ "$DefaultPassword" == '' ]; then
		echo '[Error] password is empty.';
		SetPassword;
	else
		echo '[OK] Your password is:';
		echo $DefaultPassword;
		echo '==========================================================================';
	fi;
}
SetPassword
apt-get update -y
apt-get install python git unzip -y  >/dev/null 2>&1
apt-get install nginx php-fpm -y >/dev/null 2>&1
service nginx start
service php7.0-fpm start
cd /etc/php/7.0/fpm/pool.d
sed -i '/listen = \/var\/run\/php\/php7.0-fpm.sock/s/^/#/' www.conf
sed -i '/php7.0-fpm.sock/a\listen = 127.0.0.1:9000' www.conf
cd /etc/nginx/conf.d
ip=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
cat >> www.conf << EOF
server {
    listen 80;
    server_name ${ip};
    root /www/ytb/;

    location / {
        index index.html index.php;
    }
       location ~* \.php$ {
        fastcgi_pass   127.0.0.1:9000;
	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_index index.php;
    }
}	  
EOF

cat >> down.conf << EOF
server {
    listen 8888;
    server_name ${ip};
    root /www/downloads/;

    location / {
        index index.html index.php;
    }
       location ~* \.php$ {
        fastcgi_pass   127.0.0.1:9000;
	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_index index.php;
    }
}	  
EOF



cd
sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
sudo chmod a+rx /usr/local/bin/youtube-dl
mkdir -p /www/ytb/
mkdir -p /www/downloads/
chmod -R 777 downloads
add-apt-repository ppa:djcj/hybrid <<EOF

EOF
apt-get update -y
apt-get install ffmpeg -y

cd /www/ytb/
git clone https://github.com/avignat/Youtube-dl-WebUI.git
mv Youtube-dl-WebUI/* ./
rm -rf Youtube-dl-WebUI
MD5=`echo -n ${DefaultPassword}|md5sum| sed 's/ .*//'`
sed -i "s/63a9f0ea7bb98050796b649e85481845/${MD5}/g" ./config/config.php
sed -i 's/avconv/ffmpeg/g' ./config/config.php
sed -i 's/downloads/\/www\/downloads/g' ./config/config.php
sed -i 's/80/81/g' /etc/nginx/sites-available/default
chmod -R 777 /www/downloads
cd /www/downloads/
wget -O "DL.zip" https://raw.githubusercontent.com/godzlalala/Youtube-dl-WebUI/master/DirectoryLister-master.zip
unzip DL.zip
\mv ./DirectoryLister-master/* ./
rm -rf D*
service nginx restart
service php7.0-fpm restart
