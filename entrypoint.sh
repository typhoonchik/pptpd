#!/bin/sh
set -e

# enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# configure firewall
nft delete table ip pptp 2>/dev/null || true

nft -f - <<'NFT'
table ip pptp {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;

        ip saddr 10.99.99.0/24 ip daddr != 10.99.99.0/24 masquerade
    }

    chain forward {
        type filter hook forward priority filter; policy accept;

        ip saddr 10.99.99.0/24 tcp flags & (fin | syn | rst | ack) == syn \
            tcp option maxseg size set 1318

        iifname "ppp*" accept
        oifname "ppp*" accept
    }

    chain input {
        type filter hook input priority filter; policy accept;

        iifname "ppp*" accept
    }

    chain output {
        type filter hook output priority filter; policy accept;

        oifname "ppp*" accept
    }
}
NFT

exec "$@"
