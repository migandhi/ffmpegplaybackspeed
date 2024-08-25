@echo off
setlocal enabledelayedexpansion

REM Check if correct number of parameters are provided
if "%~5"=="" (
    echo Usage: %0 video_file start_time end_time output_file speed_factor
    echo Speed factor:
    echo   To speed up: Enter 2, 4, or 8
    echo   To slow down: Enter 0.5 for half speed, 0.25 for quarter speed, or 0.125 for eighth speed
    echo Example: %0 "comfyavatar.mp4" "00:00:07" "00:00:57" "testoutput1754.mp4" 8
    exit /b 1
)

REM Input parameters: video file, start time, end time, output file name, and speed factor
set "input_video=%~1"
set "start_time=%~2"
set "end_time=%~3"
set "output_file=%~4"
set "speed_factor=%~5"

REM Remove surrounding quotes from times
set "start_time=%start_time:"=%"
set "end_time=%end_time:"=%"

REM Convert times to seconds for processing
for /f "tokens=1-3 delims=:" %%a in ("%start_time%") do (
    set /a start_seconds=%%a*3600+%%b*60+%%c
)
for /f "tokens=1-3 delims=:" %%a in ("%end_time%") do (
    set /a end_seconds=%%a*3600+%%b*60+%%c
)

REM Debugging: Print out calculated seconds
echo Calculated start time in seconds: %start_seconds%
echo Calculated end time in seconds: %end_seconds%

REM Set video and audio speed factors based on input
if "%speed_factor%"=="8" (
    set "video_speed=0.125"
    set "audio_speed=8"
) else if "%speed_factor%"=="4" (
    set "video_speed=0.25"
    set "audio_speed=4"
) else if "%speed_factor%"=="2" (
    set "video_speed=0.5"
    set "audio_speed=2"
) else if "%speed_factor%"=="0.5" (
    set "video_speed=2"
    set "audio_speed=0.5"
) else if "%speed_factor%"=="0.25" (
    set "video_speed=4"
    set "audio_speed=0.25"
) else if "%speed_factor%"=="0.125" (
    set "video_speed=8"
    set "audio_speed=0.125"
) else (
    echo Invalid speed factor. Please use 2, 4, 8, 0.5, 0.25, or 0.125.
    exit /b 1
)

REM Define paths
set "ffmpeg_path=L:\ffmpeg-2021-03-09-git-c35e456f54-full_build\bin\ffmpeg.exe"
set "output_folder=%~dp1"

REM Step 1: Cut the part of the video to speed up/slow down
echo Running FFmpeg command: "%ffmpeg_path%" -ss %start_seconds% -i "%input_video%" -to %end_seconds% -c copy "%output_folder%\output.mp4"
"%ffmpeg_path%" -ss %start_seconds% -i "%input_video%" -to %end_seconds% -c copy "%output_folder%\output.mp4"

REM Step 2: Speed up or slow down the video by the specified factor
set "audio_filter=atempo=%audio_speed%"
if "%audio_speed%"=="8" set "audio_filter=atempo=2.0,atempo=2.0,atempo=2.0,atempo=2.0"
if "%audio_speed%"=="4" set "audio_filter=atempo=2.0,atempo=2.0"
if "%audio_speed%"=="2" set "audio_filter=atempo=2.0"
echo Running FFmpeg command: "%ffmpeg_path%" -i "%output_folder%\output.mp4" -filter_complex "[0:v]setpts=%video_speed%*PTS[v];[0:a]%audio_filter%[a]" -map "[v]" -map "[a]" "%output_folder%\outputmodified.mp4"
"%ffmpeg_path%" -i "%output_folder%\output.mp4" -filter_complex "[0:v]setpts=%video_speed%*PTS[v];[0:a]%audio_filter%[a]" -map "[v]" -map "[a]" "%output_folder%\outputmodified.mp4"

REM Step 3: Cut the part before the start time (if start time is valid)
if %start_seconds% GTR 0 (
    echo Running FFmpeg command: "%ffmpeg_path%" -i "%input_video%" -t %start_seconds% -c copy "%output_folder%\beginning.mp4"
    "%ffmpeg_path%" -i "%input_video%" -t %start_seconds% -c copy "%output_folder%\beginning.mp4"
    set "has_beginning=1"
) else (
    set "has_beginning=0"
)

REM Step 4: Cut the part after the end time (if end time is valid)
echo Running FFmpeg command: "%ffmpeg_path%" -i "%input_video%" -ss %end_seconds% -c copy "%output_folder%\end.mp4"
"%ffmpeg_path%" -i "%input_video%" -ss %end_seconds% -c copy "%output_folder%\end.mp4"

REM Step 5: Create the input.txt file for concatenation
(
if %has_beginning%==1 echo file '%output_folder%\beginning.mp4'
echo file '%output_folder%\outputmodified.mp4'
echo file '%output_folder%\end.mp4'
) > "%output_folder%\input.txt"

REM Step 6: Concatenate the files
echo Running FFmpeg command: "%ffmpeg_path%" -f concat -safe 0 -i "%output_folder%\input.txt" -c copy "%output_file%"
"%ffmpeg_path%" -f concat -safe 0 -i "%output_folder%\input.txt" -c copy "%output_file%"

REM Cleanup temporary files
del "%output_folder%\output.mp4"
del "%output_folder%\outputmodified.mp4"
if %has_beginning%==1 del "%output_folder%\beginning.mp4"
del "%output_folder%\end.mp4"
del "%output_folder%\input.txt"

echo Finished processing: "%output_file%"
pause
