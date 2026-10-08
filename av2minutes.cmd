@echo off
rem av2minutes 管线启动器
rem 用法: av2minutes.cmd <音视频文件或目录> [--meeting] [--asr-engine cloud] [...]
rem 自动定位脚本所在目录并注入 venv\Scripts 到 PATH（demucs 等可执行文件依赖）。
rem 前置条件: ffmpeg/ffprobe 已在 PATH 中。
rem 默认行为: 自动追加 --flat —— 平铺输出，成稿直接放到素材同目录，
rem           工作子目录与中间件、md 底稿、.demucs_model 标记全部清除。
rem           如需保留中间件排查问题，直接用 .venv\Scripts\python.exe 跑 av2minutes.py。

set "PIPELINE_ROOT=%~dp0"
set "PIPELINE_ROOT=%PIPELINE_ROOT:~0,-1%"

set "PATH=%PIPELINE_ROOT%\.venv\Scripts;%PATH%"

"%PIPELINE_ROOT%\.venv\Scripts\python.exe" "%PIPELINE_ROOT%\av2minutes.py" %* --flat
exit /b %ERRORLEVEL%
