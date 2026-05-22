# coredns-plugins-suite

[English](file:///opt/coredns-plugins-suite/README.en.md)

## 简介

本仓库会跟随 [CoreDNS](https://github.com/coredns/coredns) 的最新标准语义化 tag，注入以下插件后自动构建并发布到当前仓库的 GitHub Releases：

- [qist/hostlist](https://github.com/qist/hostlist)
- [qist/speedcheck](https://github.com/qist/speedcheck)
- [qist/resolve](https://github.com/qist/resolve)

## 工作流行为

GitHub Actions 工作流为 `Build CoreDNS Release`，支持定时触发和手动触发。

定时运行时的行为：

1. 获取 CoreDNS 最新标准语义化 tag，例如 `v1.14.3`
2. 获取当前仓库最新标准语义化 tag
3. 如果两边 tag 一致，则不重新打包
4. 只有当当前仓库最新 tag 低于 CoreDNS 最新 tag 时，才构建最新 CoreDNS 版本
5. 产物上传到 CoreDNS 对应的最新 tag release 中，而不是上传到当前仓库原有较低 tag 的 release 中
6. 如果当前仓库第一次运行、还没有任何标准语义化 tag，则直接使用 CoreDNS 最新 tag 构建并发布

手动运行时可以指定 `coredns_tag`，如果留空则仍然按最新 CoreDNS tag 处理。

## 构建方式

工作流和本地都共用脚本：

- `scripts/build-release.sh`

脚本执行内容：

1. 拉取指定的 CoreDNS tag
2. 拉取 `hostlist`、`speedcheck`、`resolve`
3. 对 `resolve` 应用补丁
4. 向 `plugin.cfg` 注入插件
5. 执行 `make -f Makefile.release release`
6. 复制 `release/` 目录产物到目标输出目录

本地示例：

```bash
./scripts/build-release.sh v1.14.3 ./dist
```

## 启动脚本

仓库内置两套启动模板：

- Linux 启动脚本: `deploy/linux/coredns.sh`
- Linux systemd: `deploy/linux/coredns.service`
- Linux 环境变量示例: `deploy/linux/coredns.env.example`
- Linux US Corefile 模板: `deploy/linux/Corefile.us`
- Linux CN Corefile 模板: `deploy/linux/Corefile.cn`
- OpenWrt init 脚本: `deploy/openwrt/coredns.init`
- OpenWrt UCI 配置示例: `deploy/openwrt/coredns.config`
- OpenWrt CN Corefile 模板: `deploy/openwrt/Corefile.cn`

### Linux systemd

建议路径：

- 二进制: `/usr/local/bin/coredns`
- Corefile: `/etc/coredns/Corefile`
- 工作目录: `/var/lib/coredns`
- 启动脚本: `/usr/local/libexec/coredns.sh`
- 环境文件: `/etc/default/coredns`

安装示例：

```bash
sudo useradd --system --home /var/lib/coredns --shell /usr/sbin/nologin coredns
sudo mkdir -p /etc/coredns /var/lib/coredns
sudo install -m 0755 coredns /usr/local/bin/coredns
sudo install -m 0644 deploy/linux/Corefile.us /etc/coredns/Corefile
# 或
# sudo install -m 0644 deploy/linux/Corefile.cn /etc/coredns/Corefile
sudo install -m 0755 deploy/linux/coredns.sh /usr/local/libexec/coredns.sh
sudo install -m 0644 deploy/linux/coredns.service /etc/systemd/system/coredns.service
sudo install -m 0644 deploy/linux/coredns.env.example /etc/default/coredns
sudo systemctl daemon-reload
sudo systemctl enable --now coredns
```

### OpenWrt

建议路径：

- 二进制: `/usr/bin/coredns`
- Corefile: `/etc/coredns/Corefile`
- init 脚本: `/etc/init.d/coredns`
- UCI 配置: `/etc/config/coredns`

安装示例：

```sh
mkdir -p /etc/coredns /var/lib/coredns
install -m 0755 coredns /usr/bin/coredns
install -m 0644 deploy/openwrt/Corefile.cn /etc/coredns/Corefile
install -m 0755 deploy/openwrt/coredns.init /etc/init.d/coredns
install -m 0644 deploy/openwrt/coredns.config /etc/config/coredns
/etc/init.d/coredns enable
/etc/init.d/coredns start
```

## US配置示例

```corefile
.:53 {
    forward . 127.0.0.1:5302 127.0.0.1:5303 127.0.0.1:5301 {
        max_fails 2
        policy sequential
        health_check 5s
        max_concurrent 1000
    }
    hostlist {
        # 黑名单来源
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_29.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_21.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt
        url https://adguardteam.github.io/HostlistsRegistry/assets/filter_38.txt
        url https://raw.githubusercontent.com/Loyalsoldier/surge-rules/release/reject.txt

        # 用户自定义规则（不受远程更新影响）
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

        # 设置
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

## CN配置示例

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
