# S-UI Clash 规则

这个仓库只维护 **Clash Meta 订阅模板**（S-UI 设置里的 `subClashExt`），不改节点、用户、Reality 密钥。

现网主站：`ubuntu@13.196.71.52`  
订阅前缀：`https://clash.lobe.li/sub/`（例如 `/sub/canisminor?format=clash`）

分流改 `clash-ext.yaml` 即可。S-UI 每次生成订阅都会读数据库，**同步规则不会重启 sing-box**。

## 改规则

编辑 [`clash-ext.yaml`](clash-ext.yaml)：

| 段 | 作用 |
|----|------|
| `dns` / `tun` | 客户端 DNS、TUN、嗅探 |
| `proxy-groups` | `🚀 Proxy`、地区自动测速、AI / 开发 / Steam 等策略组 |
| `rule-providers` | perfect-panel 规则集 URL |
| `rules` | `RULE-SET` / 域名规则 → 策略组 |

不要把 `RULE-SET,Apple` 写进 S-UI「路由列表」——那是服务器 sing-box 的路由，对「国内直连」无效。

地区组用 `filter` 匹配节点名（`日本` / `新加坡` / `香港` / `美国`）。组名用 `🇯🇵 日本 Auto` 这类，避免和节点 tag 完全相同。

当前默认出口（客户端可改；已选过的组会记住上次选择）：

| 组 | 默认 |
|----|------|
| Cursor | DIRECT |
| Claude | 日本 Auto |
| OpenAI / Gemini / Copilot / Ollama / HuggingFace | 🚀 Proxy |
| Apple | DIRECT |
| Steam 国内 CDN | DIRECT |
| Steam 商店 / 社区 | 🚀 Proxy |

局域网、劫持站、HttpDNS 在规则最前；AI / 开发规则在 Google、Microsoft 大规则集之前。

## 同步到主站

本机已能 SSH `ubuntu@13.196.71.52` 时：

```powershell
powershell -File scripts/deploy.ps1
```

GitHub：把下面三个 Secrets 配好后，**push 到 `main`**（或手动跑 workflow）会自动写入主站。

| Secret | 值 |
|--------|-----|
| `SUI_HOST` | `13.196.71.52` |
| `SUI_USER` | `ubuntu` |
| `SUI_SSH_KEY` | 部署用私钥全文（见 `.deploy/id_ed25519`，不要提交） |

客户端里点一次「更新订阅」就能拿到新规则。

## 仓库结构

```
clash-ext.yaml                 # 源文件，写入 settings.subClashExt
scripts/sync_subclash.py       # 在主站上改 sqlite
scripts/deploy.ps1             # 本机 Windows 部署
scripts/deploy.sh              # 本机 / GitHub Actions 部署
.github/workflows/sync.yml     # push 后自动同步
.cursor/skills/s-ui-rule/      # Cursor 改规则时用的 skill
.deploy/                       # 部署私钥，已 gitignore
```
