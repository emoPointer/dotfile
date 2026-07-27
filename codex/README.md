# Codex 配置

本目录保存个人 Codex 全局指令和默认配置：

- `AGENTS.md`：全局工作规范。
- `config.toml`：模型、推理强度、沙箱和审批策略的个人默认值。
- `install.sh`：导入配置。
- `uninstall.sh`：恢复导入前的配置。

## 一条指令导入

使用 `curl`：

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotfile/main/codex/install.sh | bash
```

或者使用 `wget`：

```bash
wget -qO- https://raw.githubusercontent.com/emoPointer/dotfile/main/codex/install.sh | bash
```

正式导入前可以先预览：

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotfile/main/codex/install.sh | bash -s -- --dry-run
```

默认目标目录是 `~/.codex`。脚本会：

1. 用仓库中的 `AGENTS.md` 更新 `~/.codex/AGENTS.md`。
2. 只把 `model`、`model_reasoning_effort`、`sandbox_mode` 和
   `approval_policy` 合并到现有 `config.toml`，保留项目授权和界面状态等
   机器相关内容。
3. 修改前创建带时间戳的备份，并在
   `~/.codex/.dotfiles-codex-state` 中保存首次导入前的状态。

如需导入到其他目录，可以设置 `CODEX_HOME`：

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotfile/main/codex/install.sh | CODEX_HOME=/path/to/codex-home bash
```

导入后重新启动 Codex 会话。

> 当前配置使用 `danger-full-access` 和 `approval_policy = "never"`，
> Codex 会获得完整文件系统和网络访问能力，并且不会弹出审批提示。只应在信任的
> 机器和项目中使用。

管道执行远程脚本前，应先在浏览器中检查脚本内容。也可以克隆仓库后在本目录执行
`./install.sh`；本地和远程模式的安装行为相同。

## 一条指令卸载

先预览卸载操作：

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotfile/main/codex/uninstall.sh | bash -s -- --dry-run
```

确认后卸载：

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotfile/main/codex/uninstall.sh | bash
```

卸载脚本根据安装时保存的状态恢复原来的 `AGENTS.md`，并只恢复
`config.toml` 中由安装脚本管理的四个键。卸载前也会备份当前文件。若导入时目标
配置已经完全一致、没有发生修改，则不会创建卸载状态，也无需卸载。

使用了自定义 `CODEX_HOME` 时，卸载必须传入同一个值：

```bash
curl -fsSL https://raw.githubusercontent.com/emoPointer/dotfile/main/codex/uninstall.sh | CODEX_HOME=/path/to/codex-home bash
```

该操作只卸载本仓库导入的配置，不会卸载 Codex 软件。
