# Terminator 配置

本目录中的 `config` 是从本机 `~/.config/terminator/config` 提取的个人
Terminator 配置。

## 导入配置

克隆私有仓库后执行：

```bash
gh repo clone emoPointer/dotfile
cd dotfile/terminator
./install.sh --dry-run
./install.sh
```

脚本默认把配置导入到 `~/.config/terminator/config`。如果目标文件已存在，
脚本会先创建带时间戳的备份，并在
`~/.config/terminator/.dotfiles-terminator-state` 中保存首次导入前的状态。
导入完成后重启 Terminator。

如果使用了自定义 `XDG_CONFIG_HOME`，可这样导入：

```bash
XDG_CONFIG_HOME=/path/to/config-home ./install.sh
```

## 卸载配置

在仓库的 `terminator` 目录执行：

```bash
./uninstall.sh --dry-run
./uninstall.sh
```

卸载脚本会恢复首次导入前的配置；如果导入前没有配置文件，则删除本仓库安装的
配置。执行恢复或删除前，当前配置也会保存为带时间戳的安全备份。

使用了自定义 `XDG_CONFIG_HOME` 时，卸载必须传入同一个值：

```bash
XDG_CONFIG_HOME=/path/to/config-home ./uninstall.sh
```

该操作只卸载本仓库导入的配置，不会卸载 Terminator 软件。
