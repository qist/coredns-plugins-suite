# coredns-plugins-suite

[中文](./README.md)

## Overview

This repository follows the latest stable semver tag from [CoreDNS](https://github.com/coredns/coredns), injects the following plugins, then builds and publishes release assets to this repository's GitHub Releases:

- [qist/hostlist](https://github.com/qist/hostlist)
- [qist/speedcheck](https://github.com/qist/speedcheck)
- [qist/resolve](https://github.com/qist/resolve)

## Workflow Behavior

The GitHub Actions workflow is named `Build CoreDNS Release` and supports both scheduled and manual runs.

Scheduled behavior:

1. Resolve the latest CoreDNS stable semver tag, for example `v1.14.3`
2. Resolve the latest stable semver tag in this repository
3. If both tags are the same, skip rebuilding
4. Build only when this repository is behind the latest CoreDNS tag
5. Upload assets to the CoreDNS target tag release, not to an older local tag release
6. If this repository has no stable semver tag yet on the first run, build and publish the latest CoreDNS tag directly

Manual runs can specify `coredns_tag`; if left empty, the workflow still uses the latest CoreDNS tag.

## Build Method

Both CI and local builds use the same script:

- `scripts/build-release.sh`

The script performs the following steps:

1. Clone the specified CoreDNS tag
2. Clone `hostlist`, `speedcheck`, and `resolve`
3. Apply the `resolve` patch
4. Inject plugins into `plugin.cfg`
5. Run `make -f Makefile.release release`
6. Copy artifacts from `release/` into the target output directory

Local example:

```bash
./scripts/build-release.sh v1.14.3 ./dist
```

## Service Scripts

This repository includes two service templates:

- Linux launcher script: `deploy/linux/coredns.sh`
- Linux systemd unit: `deploy/linux/coredns.service`
- Linux environment example: `deploy/linux/coredns.env.example`
- Linux US Corefile template: `deploy/linux/Corefile.us`
- Linux CN Corefile template: `deploy/linux/Corefile.cn`
- OpenWrt init script: `deploy/openwrt/coredns.init`
- OpenWrt UCI config example: `deploy/openwrt/coredns.config`
- OpenWrt CN Corefile template: `deploy/openwrt/Corefile.cn`

### Linux systemd

Recommended paths:

- Binary: `/usr/local/bin/coredns`
- Corefile: `/etc/coredns/Corefile`
- Working directory: `/var/lib/coredns`
- Launcher script: `/usr/local/libexec/coredns.sh`
- Environment file: `/etc/default/coredns`

Installation example:

```bash
sudo useradd --system --home /var/lib/coredns --shell /usr/sbin/nologin coredns
sudo mkdir -p /etc/coredns /var/lib/coredns
sudo install -m 0755 coredns /usr/local/bin/coredns
sudo install -m 0644 deploy/linux/Corefile.us /etc/coredns/Corefile
# or
# sudo install -m 0644 deploy/linux/Corefile.cn /etc/coredns/Corefile
sudo install -m 0755 deploy/linux/coredns.sh /usr/local/libexec/coredns.sh
sudo install -m 0644 deploy/linux/coredns.service /etc/systemd/system/coredns.service
sudo install -m 0644 deploy/linux/coredns.env.example /etc/default/coredns
sudo systemctl daemon-reload
sudo systemctl enable --now coredns
```

### OpenWrt

Recommended paths:

- Binary: `/usr/bin/coredns`
- Corefile: `/etc/coredns/Corefile`
- Init script: `/etc/init.d/coredns`
- UCI config: `/etc/config/coredns`

Installation example:

```sh
mkdir -p /etc/coredns /var/lib/coredns
install -m 0755 coredns /usr/bin/coredns
install -m 0644 deploy/openwrt/Corefile.cn /etc/coredns/Corefile
install -m 0755 deploy/openwrt/coredns.init /etc/init.d/coredns
install -m 0644 deploy/openwrt/coredns.config /etc/config/coredns
/etc/init.d/coredns enable
/etc/init.d/coredns start
```

## US Corefile Example

```corefile
.:53 {
    forward . 127.0.0.1:5302 127.0.0.1:5303 127.0.0.1:5301 {
        max_fails 2
        policy sequential
        health_check 5s
        max_concurrent 1000
    }
    hostlist {
        # blacklist sources
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_29.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_21.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_38.txt
        url https://raw.githubusercontent.com/Loyalsoldier/surge-rules/release/reject.txt

        # user allowlist rules
        allowlist @@||www.youtube.com^
        allowlist @@||m.youtube.com^
        allowlist @@||cntv.lat^
        allowlist @@||top^
        allowlist @@||angtv.cc^
        allowlist @@||cf^
        allowlist @@||m.stripe.com^
        allowlist @@||cqitv.cloudns.ch^
        allowlist @@||z-lib.io^
        allowlist @@||dpdns.org^
        allowlist @@||savetwitter.net^
        allowlist @@||wyfc.qzz.io^
        allowlist @@||polymarket.com^
        allowlist @@||epg.cdn.loc.cc^
        allowlist @@||a.nel.cloudflare.com^
        allowlist @@||d.skk.moe^

        # settings
        mode blacklist
        block_type 0.0.0.0
        refresh 12h
        cache_dir /opt/coredns/hostlist
        # bypass_ip 192.168.0.155
        safesearch off
        parental off
    }
    speedcheck {
        speed-check-mode ping,tcp:443,tcp:80
        speed-timeout-mode 1s
        speed-check-parallel on
        speed-cache-ttl 60s
        speed-ip-mode ipv6,ipv4
        speed-ip-parallel on
        speed-host-override mtalk.google.com|tcp:5228|ipv6,ipv4
        speed-host-override www.gstatic.com|tcp:80,tcp:443|ipv4
        speed-host-override *.bing.com|tcp:80,tcp:443|ipv4
        speed-host-override bing.com|tcp:80,tcp:443|ipv4
        check_http_send "HEAD / HTTP/1.1\r\nHost: {host}\r\nConnection: close\r\n\r\n"
        check_http_expect_alive http_2xx http_3xx http_4xx
    }
    reload 6s
    loadbalance
}

.:5301 {
    forward . tls://1.0.0.1 tls://1.1.1.1 tls://[2606:4700:4700::1001] tls://[2606:4700:4700::1111] {
        tls_servername one.one.one.one
        max_fails 2
        policy round_robin
        health_check 5s
    }
}

.:5302 {
    forward . tls://8.8.8.8 tls://8.8.4.4 tls://[2001:4860:4860::8844] tls://[2001:4860:4860::8888] {
        tls_servername dns.google
        max_fails 2
        policy round_robin
        health_check 5s
    }
}

.:5303 {
    forward . tls://9.9.9.9 tls://149.112.112.112 tls://[2620:fe::9] tls://[2620:fe::fe] {
        tls_servername dns.quad9.net
        max_fails 2
        policy round_robin
        health_check 5s
    }
}

https://.:8443 {
    tls /apps/nginx/sslkey/tycng.com/ecc/fullchain.crt /apps/nginx/sslkey/tycng.com/ecc/private.key
    edns0 on
    resolve
    forward . 127.0.0.1:53 {
        max_concurrent 1000
    }
    reload 6s
    loadbalance
}
```

## CN Corefile Example

```corefile
.:53 {
    forward . 127.0.0.1:5301 127.0.0.1:5302 {
        max_fails 2
        health_check 5s
        max_concurrent 1000
    }
    rewrite name cloudflare cloudflare
    hosts {
        190.93.245.123 cloudflare
        reload 30s
        fallthrough
    }
    speedcheck {
        speed-check-mode ping,tcp:443,tcp:80
        speed-timeout-mode 1s
        speed-check-parallel on
        speed-cache-ttl 60s
        speed-ip-mode ipv6,ipv4
        speed-ip-parallel on
        speed-host-override www.qq.com,tcp:443,ipv4
        check_http_send "HEAD / HTTP/1.1\r\nHost: {host}\r\nConnection: close\r\n\r\n"
        check_http_expect_alive http_2xx http_3xx http_4xx
    }
    reload 6s
    cache 10
    loadbalance
}

.:5301 {
    forward . tls://120.53.53.53 tls://1.12.12.12 {
        tls_servername dot.pub
        max_fails 2
        policy sequential
        health_check 5s
    }
}

.:5302 {
    forward . tls://223.5.5.5 tls://223.6.6.6 {
        tls_servername dns.alidns.com
        max_fails 2
        policy sequential
        health_check 5s
    }
}
```
