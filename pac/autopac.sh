#!/bin/bash

APNIC_STATS=http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
GFWLIST=https://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt

PROXY_LOCAL=127.0.0.1:7070

cd `dirname "${BASH_SOURCE[0]}"`

PATH=/opt/local/bin/:/usr/local/bin:/usr/bin:/bin

genpacForGfwlist() {
    if ! [ -f /tmp/gfwlist.txt ]; then
        echo "Downloading gfwlist from $GFWLIST"
        curl --fail "$GFWLIST" --socks5-hostname "$PROXY_LOCAL" -o /tmp/gfwlist.txt || exit 1
    fi

    gfwlist2pac \
        --input /tmp/gfwlist.txt \
        --file "$2" \
        --proxy "SOCKS5 $1; SOCKS $1; DIRECT" \
        --user-rule user_rule.txt
}

RUN_FLORA_PAC=
findFloraPac() {
    if [ -z "$RUN_FLORA_PAC" ]; then
        RUN_FLORA_PAC=`which flora-pac`
        local p
        for p in \
            "$HOME"/MyWORK/FloraPacNJS \
            "$HOME"/flora-pac \
            "$HOME"/node_modules/flora-pac \
            /home/william/flora-pac \
            /home/william/node_modules/flora-pac \
            ; do
            if [ -d "$p" ]; then
                RUN_FLORA_PAC="$p/index.js"
                break;
            fi
        done
        if [ -z "$RUN_FLORA_PAC" ]; then
            RUN_FLORA_PAC=flora-pac
            echo "Can not find any runtime of flora-pac"
        else
            echo "Using $RUN_FLORA_PAC"
        fi
    fi
}

genpac() {
    local type="$1"
    local host="$2"
    local file="$3"
    if [ "$type" == "SOCKS5" ] ; then
        local proxy="SOCKS5 $host; SOCKS $host"
    else
        local proxy="PROXY $host"
    fi

    findFloraPac
    "$RUN_FLORA_PAC" --config pac-config.ini --file "$file" --proxy "$proxy"
}

if [ "$1" == "bvm" ] || [ "$1" == "all" ] ; then
    # for bvm config - schedule at 14:10 every monday
    # 10 14 * * 1 nohup /home/solocompany/pac/autopac.sh bvm
    cd /home/solocompany/
    svn up pac; npm update flora-pac
    cd pac/
    echo "Downloading $APNIC_STATS..."
    curl --fail "$APNIC_STATS" -O || exit
    genpac SOCKS5 "lotus-hk.solocompany.net:25"     /var/www/html/proxy_lotus_hk.pac
    genpac SOCKS5       "ss.solocompany.net:25"     /var/www/html/proxy_bvm25.pac
    genpac SOCKS5 "$PROXY_LOCAL"                    /var/www/html/proxy_local.pac
    genpac ""     "127.0.0.1:8000"                  /var/www/html/proxy_local_http.pac
    rm -rf delegated-apnic-latest
elif [ "$1" == "mt" ]; then
    # for 92.rd.mt config - schedule at 14:10 every monday
    # 10 14 * * 1 nohup /home/william/pac/autopac.sh mt
    cd /home/william
    svn up pac; npm update flora-pac
    cd pac/
    echo "Downloading $APNIC_STATS..."
    curl --fail --socks5-hostname "rd.mailtech.cn:7070" "$APNIC_STATS" -O || exit
    genpac SOCKS5 "rd.mailtech.cn:7070"    /home/release/web/proxy.pac
    genpac ""     "rd.mailtech.cn:8000"    /home/release/web/proxy_http.pac
    rm -rf delegated-apnic-latest
else
    # for local mac config - schedule at 14:10 every monday
    # 10 14 * * 1 nohup $HOME/MyWORK/personal/pac/autopac.sh
    genpac SOCKS5 "$PROXY_LOCAL" proxy.pac
fi

rm -f /tmp/gfwlist.txt

