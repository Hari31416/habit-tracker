import numpy as np
import scipy.io.wavfile as wavfile
import scipy.signal as signal
import os
import subprocess

SAMPLE_RATE = 44100
DURATION = 30  # 30 seconds seamless loop

def apply_seamless_loop(audio, crossfade_sec=2.0, sr=SAMPLE_RATE):
    """Crossfade head and tail of audio to make it seamlessly loopable."""
    fade_len = int(crossfade_sec * sr)
    if len(audio.shape) == 1:
        out = audio[:-fade_len].copy()
        fade_in = np.linspace(0, 1, fade_len)
        fade_out = 1 - fade_in
        out[:fade_len] = out[:fade_len] * fade_in + audio[-fade_len:] * fade_out
        return out
    else:
        out = audio[:-fade_len, :].copy()
        fade_in = np.linspace(0, 1, fade_len)[:, np.newaxis]
        fade_out = 1 - fade_in
        out[:fade_len, :] = out[:fade_len, :] * fade_in + audio[-fade_len:, :] * fade_out
        return out

def normalize_audio(audio, target_db=-14.0):
    """Normalize audio peak/RMS to target dB."""
    rms = np.sqrt(np.mean(audio**2))
    if rms > 0:
        target_rms = 10 ** (target_db / 20.0)
        audio = audio * (target_rms / rms)
    # Clamp to avoid clipping
    peak = np.max(np.abs(audio))
    if peak > 0.95:
        audio = audio * (0.95 / peak)
    return audio

def generate_pink_noise(num_samples):
    """Generate 1/f pink noise via Voss-McCartney or FFT filtering."""
    white = np.random.randn(num_samples)
    fft_white = np.fft.rfft(white)
    frequencies = np.fft.rfftfreq(num_samples)
    frequencies[0] = 1.0  # avoid divide by zero
    # 1/sqrt(f) for pink noise in power spectrum (1/f)
    fft_pink = fft_white / np.sqrt(frequencies)
    fft_pink[0] = 0
    pink = np.fft.irfft(fft_pink, n=num_samples)
    return pink / np.max(np.abs(pink))

def generate_brown_noise(num_samples):
    """Generate 1/f^2 brownian noise."""
    white = np.random.randn(num_samples)
    brown = np.cumsum(white)
    brown -= np.mean(brown)
    return brown / np.max(np.abs(brown))

def synthesize_rain():
    total_samples = int((DURATION + 3) * SAMPLE_RATE)
    # Base pink noise background rain
    pink_l = generate_pink_noise(total_samples)
    pink_r = generate_pink_noise(total_samples)
    
    # Lowpass filter around 3500 Hz for gentle steady rainfall
    sos_lp = signal.butter(4, 3500, 'low', fs=SAMPLE_RATE, output='sos')
    rain_l = signal.sosfilt(sos_lp, pink_l)
    rain_r = signal.sosfilt(sos_lp, pink_r)
    
    # Add gentle high-pass layer (droplets texture)
    sos_hp = signal.butter(3, [1200, 6000], 'bandpass', fs=SAMPLE_RATE, output='sos')
    texture_l = signal.sosfilt(sos_hp, pink_l) * 0.4
    texture_r = signal.sosfilt(sos_hp, pink_r) * 0.4
    
    # Random gentle droplet impacts
    num_drops = int(DURATION * 60)
    drop_layer_l = np.zeros(total_samples)
    drop_layer_r = np.zeros(total_samples)
    
    for _ in range(num_drops):
        idx = np.random.randint(0, total_samples - 2000)
        pan = np.random.uniform(0.1, 0.9)
        freq = np.random.uniform(1500, 4000)
        t_drop = np.linspace(0, 0.04, int(SAMPLE_RATE * 0.04))
        envelope = np.exp(-t_drop * 100)
        sine = np.sin(2 * np.pi * freq * t_drop) * envelope * np.random.uniform(0.05, 0.15)
        
        drop_layer_l[idx:idx+len(sine)] += sine * (1 - pan)
        drop_layer_r[idx:idx+len(sine)] += sine * pan
        
    out_l = rain_l * 0.7 + texture_l + drop_layer_l
    out_r = rain_r * 0.7 + texture_r + drop_layer_r
    
    stereo = np.column_stack([out_l, out_r])
    stereo = apply_seamless_loop(stereo, crossfade_sec=2.5)
    return normalize_audio(stereo, -15.0)

def synthesize_waves():
    total_samples = int((DURATION + 3) * SAMPLE_RATE)
    pink_l = generate_pink_noise(total_samples)
    pink_r = generate_pink_noise(total_samples)
    brown_l = generate_brown_noise(total_samples)
    brown_r = generate_brown_noise(total_samples)
    
    # Wave surge period ~7.5 seconds
    t = np.linspace(0, (DURATION + 3), total_samples)
    surge = 0.5 + 0.5 * np.sin(2 * np.pi * t / 7.5 - np.pi/2)
    # Shape surge to have a swell and slow wash out
    surge = np.power(surge, 2.2)
    
    # Filter brown noise for deep ocean swell
    sos_low = signal.butter(4, 400, 'low', fs=SAMPLE_RATE, output='sos')
    deep_l = signal.sosfilt(sos_low, brown_l)
    deep_r = signal.sosfilt(sos_low, brown_r)
    
    # Filter pink noise for surf / spray
    sos_mid = signal.butter(3, [200, 2200], 'bandpass', fs=SAMPLE_RATE, output='sos')
    surf_l = signal.sosfilt(sos_mid, pink_l)
    surf_r = signal.sosfilt(sos_mid, pink_r)
    
    # Modulate surf with surge
    out_l = deep_l * 0.4 + surf_l * (0.3 + 0.7 * surge)
    out_r = deep_r * 0.4 + surf_r * (0.3 + 0.7 * np.roll(surge, int(SAMPLE_RATE * 0.3)))
    
    stereo = np.column_stack([out_l, out_r])
    stereo = apply_seamless_loop(stereo, crossfade_sec=3.0)
    return normalize_audio(stereo, -14.0)

def synthesize_campfire():
    total_samples = int((DURATION + 3) * SAMPLE_RATE)
    # Warm low frequency roar
    brown_l = generate_brown_noise(total_samples)
    brown_r = generate_brown_noise(total_samples)
    sos_roar = signal.butter(4, 300, 'low', fs=SAMPLE_RATE, output='sos')
    roar_l = signal.sosfilt(sos_roar, brown_l) * 0.5
    roar_r = signal.sosfilt(sos_roar, brown_r) * 0.5
    
    # Soft hissing
    pink_l = generate_pink_noise(total_samples)
    pink_r = generate_pink_noise(total_samples)
    sos_hiss = signal.butter(3, [500, 3000], 'bandpass', fs=SAMPLE_RATE, output='sos')
    hiss_l = signal.sosfilt(sos_hiss, pink_l) * 0.25
    hiss_r = signal.sosfilt(sos_hiss, pink_r) * 0.25
    
    # Wood crackles and pops
    pop_l = np.zeros(total_samples)
    pop_r = np.zeros(total_samples)
    num_pops = int(DURATION * 35)
    
    for _ in range(num_pops):
        idx = np.random.randint(0, total_samples - 4000)
        pan = np.random.uniform(0.15, 0.85)
        # Pop transient duration 5ms - 25ms
        pop_dur = np.random.uniform(0.005, 0.03)
        n_pts = int(SAMPLE_RATE * pop_dur)
        t_pop = np.linspace(0, pop_dur, n_pts)
        
        freq = np.random.uniform(800, 3500)
        decay = np.random.uniform(150, 400)
        envelope = np.exp(-t_pop * decay)
        noise_part = np.random.randn(n_pts) * envelope * np.random.uniform(0.2, 0.6)
        sine_part = np.sin(2 * np.pi * freq * t_pop) * envelope * np.random.uniform(0.1, 0.4)
        pop_sound = noise_part + sine_part
        
        pop_l[idx:idx+n_pts] += pop_sound * (1 - pan)
        pop_r[idx:idx+n_pts] += pop_sound * pan
        
    out_l = roar_l + hiss_l + pop_l
    out_r = roar_r + hiss_r + pop_r
    stereo = np.column_stack([out_l, out_r])
    stereo = apply_seamless_loop(stereo, crossfade_sec=2.5)
    return normalize_audio(stereo, -15.0)

def synthesize_stream():
    total_samples = int((DURATION + 3) * SAMPLE_RATE)
    # Continuous flowing water noise
    pink_l = generate_pink_noise(total_samples)
    pink_r = generate_pink_noise(total_samples)
    
    sos_stream = signal.butter(3, [300, 3800], 'bandpass', fs=SAMPLE_RATE, output='sos')
    stream_l = signal.sosfilt(sos_stream, pink_l) * 0.5
    stream_r = signal.sosfilt(sos_stream, pink_r) * 0.5
    
    # Water bubbles
    bubble_l = np.zeros(total_samples)
    bubble_r = np.zeros(total_samples)
    num_bubbles = int(DURATION * 80)
    
    for _ in range(num_bubbles):
        idx = np.random.randint(0, total_samples - 3000)
        pan = np.random.uniform(0.1, 0.9)
        dur = np.random.uniform(0.02, 0.06)
        n_pts = int(SAMPLE_RATE * dur)
        t_b = np.linspace(0, dur, n_pts)
        f_start = np.random.uniform(400, 1800)
        f_end = f_start + np.random.uniform(100, 400) # upward frequency chirp for bubble
        f_chirp = np.linspace(f_start, f_end, n_pts)
        phase = 2 * np.pi * np.cumsum(f_chirp) / SAMPLE_RATE
        envelope = np.sin(np.pi * t_b / dur) * np.exp(-t_b * 60)
        b_sound = np.sin(phase) * envelope * np.random.uniform(0.1, 0.3)
        
        bubble_l[idx:idx+n_pts] += b_sound * (1 - pan)
        bubble_r[idx:idx+n_pts] += b_sound * pan
        
    out_l = stream_l + bubble_l
    out_r = stream_r + bubble_r
    stereo = np.column_stack([out_l, out_r])
    stereo = apply_seamless_loop(stereo, crossfade_sec=2.5)
    return normalize_audio(stereo, -15.0)

def synthesize_forest():
    total_samples = int((DURATION + 3) * SAMPLE_RATE)
    # Wind rustle in trees
    pink_l = generate_pink_noise(total_samples)
    pink_r = generate_pink_noise(total_samples)
    
    t = np.linspace(0, DURATION + 3, total_samples)
    wind_mod = 0.6 + 0.4 * np.sin(2 * np.pi * t / 9.0) * np.sin(2 * np.pi * t / 4.3)
    
    sos_wind = signal.butter(3, [150, 1600], 'bandpass', fs=SAMPLE_RATE, output='sos')
    wind_l = signal.sosfilt(sos_wind, pink_l) * wind_mod * 0.4
    wind_r = signal.sosfilt(sos_wind, pink_r) * wind_mod * 0.4
    
    # Crickets / gentle high-pitch background
    sos_crickets = signal.butter(4, [4500, 6500], 'bandpass', fs=SAMPLE_RATE, output='sos')
    cricket_mod = 0.5 + 0.5 * np.sin(2 * np.pi * t * 16.0)
    cricket_l = signal.sosfilt(sos_crickets, pink_l) * cricket_mod * 0.08
    cricket_r = signal.sosfilt(sos_crickets, pink_r) * cricket_mod * 0.08
    
    # Bird songs
    bird_l = np.zeros(total_samples)
    bird_r = np.zeros(total_samples)
    num_bird_motifs = int(DURATION * 0.8) # a bird chirp phrase every ~1.2s
    
    for _ in range(num_bird_motifs):
        idx = np.random.randint(0, total_samples - int(SAMPLE_RATE * 1.5))
        pan = np.random.uniform(0.15, 0.85)
        num_chirps = np.random.randint(2, 5)
        offset = idx
        base_freq = np.random.uniform(2200, 3800)
        
        for c in range(num_chirps):
            chirp_dur = np.random.uniform(0.06, 0.12)
            n_pts = int(SAMPLE_RATE * chirp_dur)
            t_c = np.linspace(0, chirp_dur, n_pts)
            # chirp frequency glide
            df = np.random.uniform(-400, 600)
            f_inst = np.linspace(base_freq, base_freq + df, n_pts)
            phase = 2 * np.pi * np.cumsum(f_inst) / SAMPLE_RATE
            envelope = np.maximum(0.0, np.sin(np.pi * t_c / chirp_dur)) ** 1.5
            chirp_sound = np.sin(phase) * envelope * np.random.uniform(0.15, 0.3)
            
            if offset + n_pts < total_samples:
                bird_l[offset:offset+n_pts] += chirp_sound * (1 - pan)
                bird_r[offset:offset+n_pts] += chirp_sound * pan
            offset += n_pts + int(SAMPLE_RATE * np.random.uniform(0.04, 0.1))
            base_freq += np.random.uniform(-200, 200)
            
    out_l = wind_l + cricket_l + bird_l
    out_r = wind_r + cricket_r + bird_r
    stereo = np.column_stack([out_l, out_r])
    stereo = apply_seamless_loop(stereo, crossfade_sec=2.5)
    return normalize_audio(stereo, -15.0)

def synthesize_white_noise():
    total_samples = int((DURATION + 3) * SAMPLE_RATE)
    # Pink noise is far more soothing than pure harsh white noise
    pink_l = generate_pink_noise(total_samples)
    pink_r = generate_pink_noise(total_samples)
    
    # Smooth off highest harsh frequencies above 8kHz
    sos_lp = signal.butter(2, 8000, 'low', fs=SAMPLE_RATE, output='sos')
    out_l = signal.sosfilt(sos_lp, pink_l)
    out_r = signal.sosfilt(sos_lp, pink_r)
    
    stereo = np.column_stack([out_l, out_r])
    stereo = apply_seamless_loop(stereo, crossfade_sec=2.5)
    return normalize_audio(stereo, -16.0)

def main():
    generators = {
        'rain': synthesize_rain,
        'waves': synthesize_waves,
        'campfire': synthesize_campfire,
        'forest': synthesize_forest,
        'stream': synthesize_stream,
        'white_noise': synthesize_white_noise,
    }
    
    output_dir = '/Users/hari/Desktop/sandbox/habit-tracker-android/assets/audio'
    os.makedirs(output_dir, exist_ok=True)
    temp_dir = '/tmp/ambient_synth'
    os.makedirs(temp_dir, exist_ok=True)
    
    for name, gen_fn in generators.items():
        print(f"Generating {name}...")
        audio = gen_fn()
        audio = np.nan_to_num(audio, nan=0.0, posinf=0.95, neginf=-0.95)
        # Convert float32 [-1, 1] to int16
        audio_int16 = np.clip(audio * 32767, -32767, 32767).astype(np.int16)
        wav_path = os.path.join(temp_dir, f"{name}.wav")
        mp3_path = os.path.join(output_dir, f"{name}.mp3")
        
        wavfile.write(wav_path, SAMPLE_RATE, audio_int16)
        # Convert to high-quality compressed MP3 with ffmpeg (128k stereo)
        subprocess.run([
            'ffmpeg', '-y', '-i', wav_path,
            '-codec:a', 'libmp3lame', '-b:a', '128k',
            mp3_path
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        file_size = os.path.getsize(mp3_path)
        print(f"Saved {mp3_path} ({file_size / 1024:.1f} KB)")

if __name__ == '__main__':
    main()
