# script-kit

Windows 开发环境常用脚本集，按脚本类型分目录组织。

当前收录 `.cmd` 与 `.bat` 两类批处理脚本，用于快速启动、停止、重启本机服务及初始化开发环境。后续新增其他类型时，在仓库根目录下建立同名目录即可（如 `ps1/`、`py/`）。

## 目录结构

```
script-kit/
├── cmd/                  # 批处理脚本（.cmd）
│   ├── MySQL57.cmd
│   ├── MySQL80.cmd
│   ├── Oracle.cmd
│   ├── Redis.cmd
│   ├── SVN.cmd
│   ├── init_dev_env.cmd
│   ├── switch_jdk_version.cmd
│   └── nginx/
│       ├── Start.cmd
│       ├── Stop.cmd
│       ├── Quit.cmd
│       └── Reload.cmd
├── bat/                  # 批处理脚本（.bat）
│   └── RebuildIconCache.bat
├── LICENSE
└── README.md
```

## 脚本清单

### 服务管理（`cmd/`）

| 脚本 | 服务 | 说明 |
| ---- | ---- | ---- |
| `cmd/MySQL57.cmd` | MySQL57 | 启动 / 停止 / 重启 MySQL 5.7 服务 |
| `cmd/MySQL80.cmd` | MySQL80 | 启动 / 停止 / 重启 MySQL 8.0 服务 |
| `cmd/Oracle.cmd` | Oracle（可配置） | 启动 / 停止 / 重启 Oracle 服务，服务名、监听器名与 SID 可在启动时配置（默认 XE 版） |
| `cmd/Redis.cmd` | Redis | 启动 / 停止 / 重启 Redis 服务 |
| `cmd/SVN.cmd` | VisualSVNServer | 启动 / 停止 / 重启 VisualSVN 服务 |

### Nginx 管理（`cmd/nginx/`）

| 脚本 | 说明 |
| ---- | ---- |
| `cmd/nginx/Start.cmd` | 启动 Nginx |
| `cmd/nginx/Stop.cmd` | 快速停止 Nginx |
| `cmd/nginx/Quit.cmd` | 优雅停止 Nginx |
| `cmd/nginx/Reload.cmd` | 重载配置 |

> Nginx 脚本会自动检测 `nginx` 是否在 PATH 中，找不到时提示输入 `nginx.exe` 的完整路径。

### 开发环境（`cmd/`）

| 脚本 | 说明 |
| ---- | ---- |
| `cmd/init_dev_env.cmd` | 初始化开发环境：批量扫描 `C:\App\Env` 下的工具目录，写入用户环境变量与 PATH |
| `cmd/switch_jdk_version.cmd` | 切换 JDK 版本（基于 `C:\App\Env\Java` 下的目录列表） |

### 系统维护（`bat/`）

| 脚本 | 说明 |
| ---- | ---- |
| `bat/RebuildIconCache.bat` | 重建 Windows 图标缓存（停止 Explorer → 清理缓存文件 → 重启 Explorer） |

## 使用说明

- 服务管理脚本需以**管理员身份**运行；脚本内置 UAC 提权逻辑，双击或普通权限运行时会自动请求提权。
- `cmd/init_dev_env.cmd` 参数：
  - `--dry-run`：仅预览将要写入的环境变量与 PATH，不实际修改
  - `--apply`：实际写入（跳过交互确认）；写入前自动把当前 PATH 备份到 `%USERPROFILE%\.cmd-env-path-backup.txt`
  - `--restore`：从备份恢复 PATH，并删除本脚本曾设置的工具环境变量（完整回滚）
  - `--list`：排查模式（等同 `--dry-run --verbose`），只输出工具检测详情，不写任何东西
  - `--quiet` / `-q`：静默模式
  - `--verbose` / `-v`：详细输出
  - 无参数：交互式选择运行模式
- 脚本中的服务名与安装路径（如 `C:\App\Env`）为本机约定，换机使用前请按需修改。
- 脚本文件为 UTF-8 编码，中文注释在默认 GBK 代码页的控制台下可能显示乱码（不影响执行）；如需正常显示，可先执行 `chcp 65001`。

## 许可证

[MIT](LICENSE)
