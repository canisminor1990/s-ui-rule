---
name: s-ui-rule
description: >-
  Maintains Clash Meta subClashExt rules in clash-ext.yaml and deploys them
  to the S-UI hub via SSH. Use when editing Clash rules, proxy-groups,
  rule-providers, RULE-SET, or syncing rules to the Lightsail S-UI server.
---

# S-UI Clash 规则维护

## 范围

只改本仓库根目录的 `clash-ext.yaml`（S-UI `subClashExt`）。

不要：

- 改 OpenWrt / OpenClash / 路由器
- 重建 inbound / TLS / 客户端（那是 `s-ui-lightsail-restore` 的部署 skill）
- 把 `RULE-SET` 写进 S-UI「路由列表」
- 把面板密码、UUID、Reality 私钥、SSH 主机/账号提交进 git
- 把 SSH 地址、用户名、sudo 策略写进本 skill
- 重启 s-ui / sing-box 来刷新规则（没必要）

## 主站

不要在本文件里写 SSH 主机、用户或 sudo 方式。连接信息只存在于本机环境变量、`.deploy/config`（gitignore）或 GitHub Secrets（`SUI_HOST`、`SUI_USER`、`SUI_SSH_KEY`）。

- 订阅由 S-UI `subDomain` + `subPath` 生成，不要把具体客户端名写进 skill
- 远端写入：`settings.key=subClashExt`（sqlite 路径由 `scripts/sync_subclash.py` 默认值决定）

## 怎么改

1. 编辑 `clash-ext.yaml`（LF 换行；Windows 下 `.gitattributes` 已强制）。
2. 地区策略组用 `filter` 匹配节点名：`日本` / `新加坡` / `香港` / `美国`。组名不要和节点 tag 完全相同。
3. 规则集继续用 `cdn.jsdmirror.com/gh/perfect-panel/rules/...`，不要擅自换成更小的 Loyalsoldier-only 集，除非用户明确要求。
4. 部署：

```powershell
powershell -File scripts/deploy.ps1
```

脚本会 `scp` yaml + `sync_subclash.py`，在主站 `UPDATE settings`，并 `curl` 本地订阅做校验。

5. 告诉用户：客户端「更新订阅」。不要 commit / push，除非用户要求。

## 自动同步

`.github/workflows/sync.yml` 在 `main` 上变更 `clash-ext.yaml` 时 SSH 部署。需要 GitHub Secrets：`SUI_HOST`、`SUI_USER`、`SUI_SSH_KEY`。
