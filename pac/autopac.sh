#!/bin/bash

APNIC_STATS=http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
GFWLIST=https://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt

PROXY_LOCAL=127.0.0.1:7070
PROXY_AZURE=solocompany.chinacloudapp.cn:4956
PROXY_BVM25=ss.solocompany.net:25

cd `dirname "${BASH_SOURCE[0]}"`

genpacForGfwlist() {
    if ! [ -f /tmp/gfwlist.txt ]; then
        echo "Downloading gfwlist from $GFWLIST"
        curl --fail "$GFWLIST" --socks5-hostname "$PROXY_LOCAL" -o /tmp/gfwlist.txt || exit 1
    fi

    /usr/local/bin/gfwlist2pac \
        --input /tmp/gfwlist.txt \
        --file "$2" \
        --proxy "SOCKS5 $1; SOCKS $1; DIRECT" \
        --user-rule user_rule.txt
}

genpac() {
    # node /Users/lwr/MyWORK/FloraPacNJS \
    flora-pac --config pac-config.json \
        --file "$2" \
        --proxy "SOCKS5 $1; SOCKS $1; DIRECT"

}

if [ "$1" == "bvm" ]; then
    # for bvm config - schedule at 14:10 every monday
    # 10 14 * * 1 nohup /home/solocompany/pac/autopac.sh bvm
    echo "Downloading $APNIC_STATS..."
    curl --fail "$APNIC_STATS" -O || exit
    PATH=$PATH:/home/solocompany
    genpac "$PROXY_AZURE" /var/www/html/proxy_azure.pac
    genpac "$PROXY_BVM25" /var/www/html/proxy_bvm25.pac
else
    # for local mac config - schedule at 14:10 every monday
    # 10 14 * * 1 nohup $HOME/MyWORK/personal/pac/autopac.sh
    genpac "$PROXY_LOCAL" proxy.pac
fi

rm -f /tmp/gfwlist.txt
