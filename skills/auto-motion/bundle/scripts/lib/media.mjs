import { runProcess } from "./process.mjs";

/**
 * Probe a media file with FFprobe and return structured metadata.
 */
export async function probeMedia(filePath) {
  const result = await runProcess("ffprobe", [
    "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", filePath,
  ], { check: true, timeoutMs: 30_000 });

  const data = JSON.parse(result.stdout);
  const videoStreams = (data.streams ?? []).filter((s) => s.codec_type === "video");
  const audioStreams = (data.streams ?? []).filter((s) => s.codec_type === "audio");

  const videoStream = videoStreams[0];
  const width = videoStream?.width ?? 0;
  const height = videoStream?.height ?? 0;
  let fps = 0;
  if (videoStream) {
    // Parse r_frame_rate (e.g., "30/1")
    const [num, den] = (videoStream.r_frame_rate ?? "0/1").split("/").map(Number);
    fps = den > 0 ? num / den : 0;
  }
  const nbFrames = videoStream?.nb_frames ? parseInt(videoStream.nb_frames, 10) : null;
  const duration = parseFloat(data.format?.duration ?? "0");

  return {
    width,
    height,
    fps,
    nb_frames: nbFrames,
    duration,
    audio_streams: audioStreams.length,
    video_streams: videoStreams.length,
  };
}

/**
 * Detect if an MP4 is all black using FFmpeg blackdetect.
 */
export async function detectAllBlack(filePath, durationSeconds, fps) {
  const minBlackDuration = durationSeconds - (1 / fps);
  if (minBlackDuration <= 0) return false;

  const result = await runProcess("ffmpeg", [
    "-i", filePath, "-vf", "blackdetect=d=0.01:pix_th=0.10",
    "-an", "-f", "null", "-",
  ], { timeoutMs: 30_000 });

  // FFmpeg outputs blackdetect info to stderr
  const lines = result.stderr.split("\n");
  for (const line of lines) {
    const match = line.match(/black_start:\S+\s+black_end:\S+\s+black_duration:([\d.]+)/);
    if (match) {
      const blackDuration = parseFloat(match[1]);
      if (blackDuration >= minBlackDuration - 0.001) {
        return true;
      }
    }
  }
  return false;
}

/**
 * Validate a single scene's output against the output profile.
 */
export async function validateSceneMedia({ mediaPath, expectedWidth, expectedHeight, expectedFps, expectedFrames }) {
  const errors = [];

  const info = await probeMedia(mediaPath);

  if (info.video_streams !== 1) {
    errors.push({ code: "VIDEO_STREAM_COUNT", detail: `Expected 1 video stream, got ${info.video_streams}` });
  }
  if (info.audio_streams > 0) {
    errors.push({ code: "AUDIO_STREAM", detail: `Expected no audio streams, got ${info.audio_streams}` });
  }
  if (info.width !== expectedWidth || info.height !== expectedHeight) {
    errors.push({ code: "DIMENSIONS", detail: `Expected ${expectedWidth}x${expectedHeight}, got ${info.width}x${info.height}` });
  }
  if (Math.abs(info.fps - expectedFps) > 0.001) {
    errors.push({ code: "FPS", detail: `Expected ${expectedFps}fps, got ${info.fps}` });
  }

  // Frame count check
  let actualFrames = null;
  if (info.nb_frames !== null) {
    actualFrames = info.nb_frames;
    if (actualFrames !== expectedFrames) {
      errors.push({ code: "FRAME_COUNT", detail: `Expected ${expectedFrames} frames, got ${actualFrames}` });
    }
  } else if (info.duration > 0) {
    actualFrames = Math.round(info.duration * expectedFps);
    if (actualFrames !== expectedFrames) {
      errors.push({ code: "FRAME_COUNT", detail: `Expected ${expectedFrames} frames (from duration), got ~${actualFrames}` });
    }
  }

  // All-black check
  if (errors.length === 0 && info.duration > 0) {
    const isBlack = await detectAllBlack(mediaPath, Math.min(info.duration, expectedFrames / expectedFps), expectedFps);
    if (isBlack) {
      errors.push({ code: "ALL_BLACK", detail: "Content is all black" });
    }
  }

  return {
    ok: errors.length === 0,
    errors,
    meta: { width: info.width, height: info.height, fps: info.fps, nb_frames: actualFrames, duration: info.duration },
  };
}
