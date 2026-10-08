# av2minutes

**音视频 → 转写文稿 / 会议纪要 全自动管线**：一条命令跑完「拆轨 → 人声分离 → 说话人分离 → 转写 → 规范 docx 排版」。识别引擎可走云端（免本地显存）或本地离线模型；成稿平铺直出，过程件不留。

## 特性

- **一条命令全流程**：视频/音频 → 转写文稿（普通）或会议原文（带时间戳与说话人标签）；正式会议纪要可由 AI Agent 从会议原文进一步提炼。
- **识别引擎双通道**：
  - 云端：阿里云百炼 `qwen-audio-3.1-asr-message`（整文件直出字级时间戳，免本地大模型加载；含 omni / filetrans 子模型）
  - 本地：Qwen3-ASR-1.7B（多语言）／FireRedASR2-AED（中英粤更准）
- **说话人分离**：pyannote community-1（会议场景，重叠语音更准）／cam++ 声纹聚类（轻量）；支持 `--names` 映射真实姓名。
- **专名质量机制**：热词表（识别偏置）+ 纠错词典（确定性替换）双机制，放仓库根目录自动加载、可随核稿持续积累。
- **平铺输出**（`--flat`）：成稿 docx 直接放到素材同目录，工作目录、中间件、md 底稿、模型标记全部清除；素材目录只剩「原始音视频 + 成稿」。
- **断点续跑**：转写（最贵环节）按配置指纹缓存——识别引擎、热词、人名、字幕、纠错词典任一变化即不复用旧结果。
- **其他能力**：视频无损拆轨、Demucs 人声/背景音分离、噪声门清理、字级时间戳字幕（SRT）、中文逆文本正则化（ITN）、专名拼音模糊纠错、情绪分析、声纹库跨文件复用、双人分声道素材直接按声道分说话人。

## 快速开始

### 1. 环境准备

```bash
# 系统依赖：FFmpeg（需在 PATH 中）
# Windows: winget install ffmpeg 或从 ffmpeg.org 下载
# 本体：Python 3.10+
pip install -r requirements.txt

# GPU 加速（本地引擎需要，云端引擎可跳过）：
# 按 https://pytorch.org 指引先装对应 CUDA 版本的 torch
```

### 2. 云端识别（推荐，免显存）

```bash
pip install dashscope
# 设置环境变量 DASHSCOPE_API_KEY（阿里云百炼控制台获取）
```

### 3. 跑起来

```bash
# 会议录音 → 会议原文（带时间戳+说话人标签，供提炼纪要）
python av2minutes.py 会议录音.m4a --meeting --asr-engine cloud

# 普通音视频 → 转写文稿（跳过说话人分离更快）
python av2minutes.py 我的视频.mp4 --asr-engine cloud --no-diarize

# 平铺输出：成稿直接放素材同目录，过程件全清
python av2minutes.py 会议录音.m4a --meeting --asr-engine cloud --flat
```

Windows 下可用随附启动器（自动定位目录、注入 venv PATH、默认追加 `--flat`）：

```cmd
av2minutes.cmd "会议录音.m4a" --meeting --asr-engine cloud
```

## 输出说明

| 场景 | 输出 | 说明 |
| --- | --- | --- |
| `--meeting` | `会议原文-<名>.docx` | 每段 `[00:00] 说话人N：文本`，供提炼会议纪要 |
| 默认 | `转写文稿-<名>.docx` | 纯文本分段（每 4 句一段） |
| `--srt` | `<名>.srt` | 字级时间戳字幕 |

`--flat` 模式下上述成稿直接落在素材（音频/视频）同目录；不加 `--flat` 时落在 `<素材目录>/separated_out/<素材名>/`。

## 专名质量机制（提升人名/术语准确率）

在仓库根目录放置两个文件即自动生效（模板见 `*.example.txt`）：

```text
hotwords.txt        # 每行一个词：容易被听错的人名、公司名、产品名、行业词（识别阶段偏置）
replace_dict.txt    # 每行「错=>对」：确认过的错写映射（识别后确定性替换）
```

- 两个文件都可随核稿持续积累；内容计入转写缓存指纹（改动后旧缓存不复用）。
- 热词是偏置、纠错词典是兜底，两者配合效果最佳。
- `--replace-save` 可把本次 `--replace` 条目合并写回词典。

## 常用参数

| 参数 | 说明 |
| --- | --- |
| `--meeting` | 产出会议原文（时间戳+说话人标签） |
| `--asr-engine qwen\|aed\|auto\|cloud` | 识别引擎：本地 Qwen（默认）／AED（中英粤）／按语言自动路由／云端百炼 |
| `--no-diarize` | 单人素材跳过说话人分离（更快；云端走整文件一次调用） |
| `--names "0=张三,1=李四"` | 说话人真名映射（先听一段确认谁是谁） |
| `--flat` | 平铺输出（成稿放素材同目录，过程件全清） |
| `--clean` | 只删中间件，保留工作目录布局 |
| `--srt` | 额外产出字级时间戳字幕 |
| `--replace "错=>对"` | 确定性专名纠错（可配 `--asr-extra "--fuzzy"` 走拼音模糊） |
| `--itn` | 中文数字规范化（三百二十万 → 320万） |
| `--split-channels` | 双人分声道素材按声道分说话人 |
| `--force` | 重跑已处理过的素材 |

完整参数见 `python av2minutes.py --help`。

## 与会议纪要技能联动

会议场景推荐两步：

1. 本管线产出**会议原文**（`--meeting`）
2. AI Agent 按 [meeting-notes-expert](https://github.com/ADC1920/meeting-notes-expert) 技能把原文提炼为五段式会议纪要（基本信息 / 会议内容 / 核心要点 / 会议总结 / 待办事项）——仓库 `skills/` 内附技能副本。

## 目录结构

```text
av2minutes/
├── av2minutes.py                 # 全流程主脚本
├── av2minutes.cmd                # Windows 启动器（自动注入 PATH，默认 --flat）
├── requirements.txt
├── hotwords.example.txt          # 热词表示例（复制为 hotwords.txt 使用）
├── replace_dict.example.txt      # 纠错词典示例（复制为 replace_dict.txt 使用）
├── test_pipeline_e2e.py          # 端到端回归（自动合成素材，17 项断言）
└── skills/
    ├── funasr-transcribe/        # 转写引擎技能（脚本 + 说明）
    └── meeting-notes-expert/     # 会议纪要提炼技能（副本）
```

## 许可与来源

MIT License。本项目由作者早期管线 [av-to-transcript-and-minutes](https://github.com/ADC1920/av-to-transcript-and-minutes) 演进而来，在其基础上新增：云端识别引擎通道、平铺输出、专名质量机制（热词/词典自动加载）、HF 离线优化等。
