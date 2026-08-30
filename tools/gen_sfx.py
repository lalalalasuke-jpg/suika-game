"""スイカゲーム用の効果音を stdlib だけで生成する。出力: suika-game/audio/*.wav"""
import math
import os
import struct
import wave

SR = 22050
OUT = r"C:\Users\PC_User\projects\suika-game\audio"
os.makedirs(OUT, exist_ok=True)


def write_wav(name, samples):
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        w.writeframes(frames)
    print("wrote", path, len(samples), "samples")


def env(i, n, attack=0.004, tau=0.05):
    t = i / SR
    a = min(1.0, t / attack)
    d = math.exp(-t / tau)
    # 末尾を線形でゼロに落としてプチノイズ回避
    tail = min(1.0, (n - i) / (0.006 * SR))
    return a * d * tail


def pop():
    n = int(0.14 * SR)
    out = []
    for i in range(n):
        t = i / SR
        f = 480 + 220 * min(1.0, t / 0.05)  # 軽く上へ
        s = math.sin(2 * math.pi * f * t) * 0.7
        s += math.sin(2 * math.pi * f * 2 * t) * 0.2  # 倍音を少し
        out.append(s * env(i, n, tau=0.045) * 0.4)
    return out


def gameover():
    notes = [(392.0, 0.18), (311.1, 0.20), (233.1, 0.40)]  # G4 -> Eb4 -> Bb3
    out = []
    for f, dur in notes:
        n = int(dur * SR)
        for i in range(n):
            t = i / SR
            s = math.sin(2 * math.pi * f * t) * 0.6 + math.sin(2 * math.pi * f * 2 * t) * 0.15
            out.append(s * env(i, n, tau=0.16) * 0.4)
    return out


write_wav("pop.wav", pop())
write_wav("gameover.wav", gameover())
