import os
import subprocess
import urllib.request

SOUNDS = {
    'rain': 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/rain/light-rain.mp3',
    'waves': 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/nature/waves.mp3',
    'campfire': 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/nature/campfire.mp3',
    'forest': 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/animals/birds.mp3',
    'stream': 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/nature/river.mp3',
    'white_noise': 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/noise/pink-noise.wav',
    'cafe': 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/places/cafe.mp3',
    'wind': 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/nature/wind-in-trees.mp3',
}

TEMP_DIR = '/tmp/ambient_curated'
OUTPUT_DIR = '/Users/hari/Desktop/sandbox/habit-tracker-android/assets/audio'

os.makedirs(TEMP_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)

TARGET_DURATION = 45  # 45 seconds loop
CROSSFADE = 3.0       # 3 seconds seamless crossfade

for name, url in SOUNDS.items():
    print(f"Downloading {name} from {url}...")
    ext = url.split('.')[-1]
    raw_path = os.path.join(TEMP_DIR, f"{name}_raw.{ext}")
    wav_path = os.path.join(TEMP_DIR, f"{name}.wav")
    final_mp3 = os.path.join(OUTPUT_DIR, f"{name}.mp3")
    
    urllib.request.urlretrieve(url, raw_path)
    
    # 1. Convert to standardized 44.1kHz stereo WAV, taking first (TARGET_DURATION + CROSSFADE) seconds
    subprocess.run([
        'ffmpeg', '-y', '-i', raw_path,
        '-t', str(TARGET_DURATION + CROSSFADE),
        '-ar', '44100', '-ac', '2',
        wav_path
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # 2. Apply acrossfade filter to make it perfectly seamless
    # The acrossfade filter crossfades the end of a clip with the beginning
    # Alternatively: split into main (0 to TARGET_DURATION) and tail (TARGET_DURATION to TARGET_DURATION+CROSSFADE)
    # and crossfade tail into start of main.
    filter_complex = (
        f"[0:a]asplit=2[main][tail];"
        f"[main]atrim=0:{TARGET_DURATION},asetpts=PTS-STARTPTS[m];"
        f"[tail]atrim={TARGET_DURATION}:{TARGET_DURATION + CROSSFADE},asetpts=PTS-STARTPTS[t];"
        f"[m]atrim=start={CROSSFADE},asetpts=PTS-STARTPTS[m_body];"
        f"[m]atrim=0:{CROSSFADE},asetpts=PTS-STARTPTS[m_head];"
        f"[t][m_head]acrossfade=d={CROSSFADE}:c1=tri:c2=tri[loop_head];"
        f"[loop_head][m_body]concat=n=2:v=0:a=1[out]"
    )
    
    subprocess.run([
        'ffmpeg', '-y', '-i', wav_path,
        '-filter_complex', filter_complex,
        '-map', '[out]',
        '-codec:a', 'libmp3lame', '-b:a', '128k',
        final_mp3
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    size_kb = os.path.getsize(final_mp3) / 1024
    print(f"Successfully processed {name}.mp3 ({size_kb:.1f} KB)")

print("All ambient tracks downloaded, seamlessly looped, and saved to assets/audio/.")
