# DAVID DIE · 第一版可玩原型

玩家是灵芝。五场 Boss 战之间，串起一次腹痛就医、一副需要自己修好的眼镜，以及最终从 David 身上掉落的信。

## 开始试玩

- **Windows 10/11，64 位：** 解压 `DavidDie-Windows.zip`，双击 `DavidDie.exe`。不需要安装 Godot。
- **Mac：** 解压 `DavidDie-macOS.zip`，双击 `David Die.app`。包含 Apple Silicon、Intel 两种架构，不需要安装 Godot。
- Mac 应用使用临时签名，尚未经过 Apple 公证；这是本地试玩版本。通过网络分享后，系统可能要求在“系统设置 → 隐私与安全性”中确认打开。公开发行前需完成正式签名与公证。

## 操作

| 操作 | 按键 |
| --- | --- |
| 移动 | WASD / 方向键 |
| 攻击 | J / 鼠标左键，可按住 |
| 闪避 | 空格 / K |
| 互动、推进对白、读信 | E |
| 开始、重试、推进对白 | Enter |
| 暂停、继续 | Esc |
| 静音 | M |
| 全屏 | F11 |
| 安装鼻托 | 用鼠标拖动鼻托到中央金色槽，松开 |

近距离攻击会自动朝向 Boss。红色图案是攻击预警，闪避有短暂无敌时间；对手收招时反击伤害更高。战败后从当前 Boss 重试。每进入一场 Boss 战会自动保存章节；重新启动后，标题页的 E 可继续最近章节，Enter 开始新游戏。

## 已实现的流程

1. 第一位 Boss 正在看《Kill Bill》，灵芝与他交战。
2. 灵芝战后腹痛，沿街前往医院。
3. 途中眼镜鼻托掉落，场景变模糊；靠近闪光按 E 拾起，亲手拖动安装。界面文字保持清楚。
4. 进入医院，先找医生，再上 CT 检查床。检查完成后从右下出口离开。
5. 第二位 Boss 使用扇形弹道，第三位使用扩散冲击波。
6. 第四位 Boss 是奶牛 **1006**，使用冲锋，战败后通过对白给出寻找 David 的线索，不掉信。
7. 第五位、最终 Boss 是 **David**，组合使用前面的招式。战败后掉落信件，玩家靠近按 E 阅读，随后进入结尾。

## 留给你确定的内容

- 第二、第三位 Boss 的姓名、身份和剧情。当前使用“第二位对手”“第三位对手”占位，战斗可以正常游玩。
- David 掉落的信件正文。阅读界面明确标注内容待定。
- 当前全部对白和人物造型都是可修改的原型；1006 指向最后房间的线索也是临时文本。

## 工程

`source/project.godot` 可以用 **Godot 4.6.2 标准版**直接导入。没有插件、账号或联网依赖。完整源码也放在 `DavidDie-source.zip`。

- `story.gd`：Boss 名字、血量、对白、最终信件。
- `game.gd`：移动、战斗、流程、交互、界面和存档。
- `world.gd`：像素角色、场景与动画。
- `tests/run.gd`：玩法和流程自动检查。
- `export_presets.cfg`：Windows、macOS 导出配置。重新打包前，在 Godot 中安装同版本官方导出模板即可。

自动检查命令（将 `godot` 替换为你的 Godot 可执行文件）：

```sh
godot --headless --path source --script res://tests/run.gd
```

## 验证和边界

- 34 项自动检查通过，覆盖攻击冷却、闪避无敌、五场战斗可胜、鼻托真实鼠标拖动事件、医院 CT 门槛、Boss 顺序、1006 对白、最终信件和死亡重试。
- 标题、战斗、鼻托界面、医院、CT、1006、David、信件已实际渲染检查。
- Mac 成品已在 Apple Silicon 机器上脱离编辑器启动；应用临时签名校验通过。Intel 架构包含在应用中，未在 Intel Mac 实机测试。
- Windows 64 位可执行文件已成功导出；当前没有 Windows 实机环境，尚未实机试玩。
- 这是供你确认玩法方向的小型原型：键鼠操作、固定场景、简短流程，没有联机、手柄或额外关卡。

## 素材和许可

像素场景、角色和合成声音均为本项目制作。电视使用《Kill Bill》标题图案，没有嵌入电影视频或电影原声。

- 引擎：[Godot 4.6.2](https://godotengine.org/)，MIT 许可，完整文本见 `GODOT-LICENSE.txt`。
- 中文字体：[Noto Sans SC](https://github.com/google/fonts/tree/main/ofl/notosanssc)，SIL Open Font License，完整文本见 `FONT-LICENSE.txt` 和 `source/assets/OFL.txt`。
