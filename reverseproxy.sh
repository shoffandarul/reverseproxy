#!/bin/bash

# cek root
if [ $(id -u) -eq 0 ]; then #jika id user = 0 (root)

    # MENGECEK INSTALASI NGINX
    echo "\n(*￣3￣)╭ MENGECEK NGINX ...\n"
    if ! (ls /usr/sbin/ | grep -q "nginx"); then
        apt-get install nginx
    fi
    echo "(*￣3￣)╭ NGINX TERINSTALL!"

    # MENGECEK STATUS NGINX
    if ! (systemctl status nginx | grep -q "active (running)"); then
        systemctl enable nginx
        systemctl start nginx
    fi
    echo "          NGINX AKTIF!"

    # MENGECEK STATUS REVERSE PROXY
    rprox="/etc/nginx/sites-available/reverse-proxy.conf"
    if ! [ -f $rprox ]; then
        echo "(*￣3￣)╭ MEMBUAT REVERSE PROXY ..."
        echo
        echo -n "\n(*￣3￣)╭ MASUKKAN IP PUBLIK SERVER: "
        read -r ippublik
        
        isi_rprox="server {
    listen 80;
    server_name $ippublik;

    location / {
        proxy_pass http://127.0.0.1:9000;
    }
}"
        unlink /etc/nginx/sites-enabled/default
        echo "$isi_rprox" | sudo tee "$rprox" > /dev/null
        ln -s $rprox /etc/nginx/sites-enabled/reverse-proxy.conf
        systemctl restart nginx
    fi
    echo "          REVERSE PROXY AKTIF!"

    # INPUT USERNAME
    echo "\n(*￣3￣)╭ MEMBUAT USER BARU ..."
    echo -n "\n(*￣3￣)╭ MASUKKAN USERNAME: "
    read -r username
    echo -n "(*￣3￣)╭ MASUKKAN PORT APLIKASI: "
    read -r port

    # MENGECEK APAKAH USER SUDAH ADA DI SISTEM
    if cat /etc/passwd | grep -q ^$username; then
        echo "(*￣3￣)╭ USERNAME SUDAH ADA!"
        exit 1
    else
        # MEMBUAT USER BARU
        adduser $username -q --gecos ",,," --disabled-password
        echo "$username:$username" | chpasswd 2> /dev/null
        echo "\n(*￣3￣)╭ USER/PASS ${username}/${username} BERHASIL DIBUAT!"
    fi

    # JIKA PORT TIDAK DIINPUTKAN SPESIFIK
    if [ -z $port ]; then
        # MENGECEK PORT TERBESAR YANG TERDAFTAR
        port=$(expr $(cat $rprox | grep -o '[0-9]\+' | awk '{print $1}' | sort | tail -1) + 1)
    fi
    
    # MEMBUAT REVERSE PROXY USER
    sed -i '8i\\n    location /'$username' {\n        proxy_pass http://127.0.0.1:'$port'/;\n    }\n' $rprox
    service nginx restart
    echo "          IP-LOKAL ${username} adalah 127.0.0.1:${port}"
    echo "          REVERSE PROXY USER BERHASIL DIBUAT DI IP-PUBLIK/${username}"

    # MEMBUAT SAMPEL FLASK
    echo "\n(*￣3￣)╭ MEMBUAT SAMPEL FLASK ..."
    isi_flask="from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello():
    return 'Hello, $username!'
if __name__ == '__main__':
    app.run(port=$port)"
    echo "$isi_flask" | sudo tee /home/$username/sample.py > /dev/null
    echo "\n(*￣3￣)╭ FILE SAMPEL FLASK BERHASIL DIBUAT DI /home/${username}/sample.py"
    echo "          JALANKAN DENGAN PERINTAH python3 /home/${username}/sample.py"

    echo "\n(*￣3￣)╭ SELESAI"
else
    echo "(*￣3￣)╭ Silakan gunakan akun root atau sudo untuk menjalankan script ini!"
fi
