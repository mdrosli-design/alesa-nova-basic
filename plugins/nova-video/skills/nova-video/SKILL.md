---
name: nova-video
description: "Video, animation and media production done reliably: ffmpeg (convert, trim, join, scale, subtitles, loudness), programmatic animation (Manim, Blender with Python, Remotion), captions from speech, and clear rules on copyright and synthetic media. Use when the user edits or converts video or audio, makes an animation or explainer video, adds subtitles, or batch-processes media. BM: 'video', 'animasi', 'ffmpeg', 'sari kata', 'subtitle', 'render', 'edit video'."
---

# nova-video — check the file, not the exit code

## 1. Work on copies
Originals are read-only; outputs go to a separate folder with clear names. For batch jobs, run one file
first and check it before processing the rest.

## 2. Inspect before and after
`ffprobe -hide_banner <file>` shows codec, resolution, frame rate, duration and audio streams. Run it on
the input and on the output, then play the output (start, middle, end). A zero exit code does not prove
the video is watchable.

## 3. ffmpeg recipes — adapt, do not paste blindly
- Web-friendly MP4:
  `ffmpeg -i in.mov -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -movflags +faststart out.mp4`
- Trim without re-encoding:
  `ffmpeg -ss 00:01:00 -to 00:02:00 -i in.mp4 -c copy part.mp4` — with stream copy the start and end snap
  to keyframes, so check timestamps and playback; re-encode when the cut must be frame-exact.
- Join files with identical codecs: list them in `list.txt` with relative names (one `file 'a.mp4'` line
  each), then `ffmpeg -f concat -i list.txt -c copy joined.mp4`. Use `-safe 0` only for a reviewed local
  list that needs absolute paths — it turns off the demuxer's path safeguards.
- Scale to 720p keeping the aspect ratio: `-vf scale=-2:720`
- Even loudness: `-af loudnorm=I=-16:TP=-1.5:LRA=11 -ar 48000` (loudnorm can raise the sample rate, so set
  the output rate). The most accurate result needs two passes: measure first, then pass the measured values
  into the second run.
- Subtitles burned in: `-vf subtitles=subs.srt`. Kept selectable in an MP4: add the SRT as a subtitle
  stream with `-c:s mov_text`.
- GPU encoding only after checking it is available: `ffmpeg -hide_banner -encoders | grep -i nvenc`.

## 4. Programmatic animation — pick by need
- Maths and explainer diagrams: Manim Community — `manim -pql scene.py MyScene` for a quick preview,
  `-qh` for the final render.
- 3D, product shots, physics: Blender, scripted in Python and rendered in the background
  (`blender -b file.blend -P script.py`, `-a` to render the animation).
- Many versions of a video from data or templates: Remotion (React).
Keep the sources (scene code, .blend files, project) in version control; rendered outputs can be rebuilt.

## 5. Captions
Speech-to-text (e.g. Whisper or whisper.cpp) produces a first draft only. A person proofreads names,
technical terms and mixed Bahasa Malaysia/English before publishing, and checks the timing on playback.

## 6. Copyright, consent and synthetic media
- Use media the user owns, licensed stock, or openly licensed works with the required attribution. Music
  needs its own licence.
- Never create a realistic video or voice of a real person without their consent. Label AI-generated or
  AI-altered media as such, and follow the platform's rules and the local law.

## 7. Done = evidence

| Probe | Expected | Actual |
|---|---|---|
| `ffprobe` on the output | codec, resolution, duration as specified | |
| Playback at start, middle, end | picture and sound in sync | |
| Subtitles | correct text, on time | |
| Size and format | within the target platform's limits | |

## Honest limits
You cannot watch the video unless frames are extracted. Say what was checked (ffprobe, extracted frames)
and what the user still has to watch.
