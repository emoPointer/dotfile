# Codex 配置

本目录保存个人 Codex 全局指令和默认配置：

- `AGENTS.md`：全局工作规范。
- `config.toml`：模型、推理强度、沙箱和审批策略的个人默认值。
- `install.sh`：导入配置。
- `uninstall.sh`：恢复导入前的配置。

## 导入配置

先克隆私有仓库，再执行安装脚本：

```bash
gh repo clone emoPointer/dotfile
cd dotfile/codex
./install.sh --dry-run
./install.sh
```

也可以使用已经配置好 GitHub 身份验证的 Git：

```bash
git clone git@github.com:emoPointer/dotfile.git
cd dotfile/codex
./install.sh --dry-run
./install.sh
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
CODEX_HOME=/path/to/codex-home ./install.sh
```

导入后重新启动 Codex 会话。

> 当前配置使用 `danger-full-access` 和 `approval_policy = "never"`，
> Codex 会获得完整文件系统和网络访问能力，并且不会弹出审批提示。只应在信任的
> 机器和项目中使用。

## 卸载配置

在仓库的 `codex` 目录执行：

```bash
./uninstall.sh --dry-run
./uninstall.sh
```

卸载脚本根据安装时保存的状态恢复原来的 `AGENTS.md`，并只恢复
`config.toml` 中由安装脚本管理的四个键。卸载前也会备份当前文件。若导入时目标
配置已经完全一致、没有发生修改，则不会创建卸载状态，也无需卸载。

使用了自定义 `CODEX_HOME` 时，卸载必须传入同一个值：

```bash
CODEX_HOME=/path/to/codex-home ./uninstall.sh
```

该操作只卸载本仓库导入的配置，不会卸载 Codex 软件。
