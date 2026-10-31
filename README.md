# AnkiPortable

官方从未发布 Windows 便携版。本仓库把官方安装包**自动**转成便携版，全程在 GitHub 上完成，不需要本地机器参与。

一切资源来自官方 [ankitects/anki](https://github.com/ankitects/anki)，本仓库只做「解包 + 改写启动方式」，不修改、不重编译 Anki 的任何代码。

## 下载

👉 [**最新发布页 / Releases**](https://github.com/StellarFab/AnkiPortable/releases/latest)

下载 `Anki-Portable-<版本>-win-x64.zip`，解压到任意目录，双击 `启动 Anki.bat` 即可。

## 它和官方版的区别

只有一点：数据目录。

| | 官方安装版 | 本便携版 |
| --- | --- | --- |
| 程序位置 | `%LOCALAPPDATA%\Programs\Anki` | 包内 `App\` |
| 数据位置 | `%APPDATA%\Anki2` | 包内 `Data\` |
| 注册表 / 开始菜单 / 文件关联 | 有 | 无 |
| 换电脑 | 需重装 + 迁移数据 | 整个文件夹拷走 |

启动器通过 `ANKI_BASE` 环境变量和 `--base` 参数把数据目录指向包内的 `Data\`。

## 自动化是怎么跑的

`.github/workflows/build-portable.yml`：

1. **每 6 小时**（以及手动触发时）查询上游 `ankitects/anki` 的 `releases/latest`
2. 只接受正式版号（`26.09`、`26.09.3` 这种），beta / rc 自动跳过
3. 如果本仓库已有同版本 Release，直接结束，不重复构建
4. 否则下载官方 `anki-<版本>-win-x64.msi`，在 `windows-latest` 上：
   - 用 `msiexec /a` 管理安装解包（官方安装后长什么样，包里就是什么样）
   - 拼上 `skeleton/` 里的启动器、升级脚本、说明文档
   - `7z` 打成 zip，算 SHA-256，读取官方安装包的数字签名信息
5. 创建 Release：tag 与上游**完全同名**（如 `26.09.3`），标题、说明、校验值全部自动生成

上游发新版 → 通常几分钟内本仓库就多一个同版本 Release。全流程无人值守。

### 手动补一次

Actions → 构建 Anki 便携版 → Run workflow：

- `version` 留空 = 用上游最新正式版；填 `26.09` = 构建指定版本
- `force` 勾上 = 已有同版本 Release 时先删掉再重建

## 仓库结构

```
.github/workflows/build-portable.yml   自动化本体
skeleton/                              每次构建都会塞进 zip 的固定文件
  启动 Anki.bat                        启动器（有控制台窗口）
  启动 Anki（无黑框）.vbs               启动器（静默）
  升级到新版本.bat                      本地一键升级：把新版 msi 丢进「升级包」再运行
  升级包/把安装包放这里.txt              升级说明
  使用说明.txt.tmpl                     生成 使用说明.txt 的模板（版本号等由工作流填入）
```

## 校验

每个 Release 的说明里都有：

- 本包 zip 的 SHA-256
- 上游 msi 的文件名、大小、SHA-256
- 上游 msi 的 Authenticode 数字签名主体（应为 `CN=Anki Software LLC`）

想自己核对，就用 `Get-FileHash` 比一下。

## 已知限制

- **只有 Windows x64**。官方没有 macOS / Linux 便携版概念，本仓库也不做。
- GitHub 的定时任务在仓库连续 60 天无提交活动后可能被自动停用，届时 GitHub 会发邮件提醒，去 Actions 页面点一下 Enable 即可；手动触发一次也能续命。
- 定时任务是"尽力而为"的：上游发布后可能要等到下一个触发窗口才会被发现，最长约 6 小时延迟。
- 便携版不要用 Anki 自带的"检查更新"，那会装成普通安装版。升级请用 Release 里的新包，或本地「升级到新版本.bat」。

## 版权

程序本体版权归 [Anki Software LLC](https://apps.ankiweb.net/) 所有，遵循 AGPL-3.0，许可证全文随包附带在 `App\LICENSE.txt`。
