#!/usr/bin/env python3
"""Compose original, deterministic, seamless mono PCM chiptune loops. No dependencies."""
from array import array
from pathlib import Path
import math
import random
import sys
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets/audio'

def compose(name, bpm, bars, energetic):
    beat = 60 / bpm
    length = round(bars * 4 * beat * RATE)
    mix = array('d', [0.0]) * length
    rng = random.Random(917 + energetic)

    def note(at, midi, duration, gain, voice='bell'):
        freq = 440 * 2 ** ((midi - 69) / 12)
        count = round(duration * RATE)
        origin = round(at * RATE)
        for i in range(count):
            t = i / RATE
            phase = 2 * math.pi * freq * t
            attack = min(1, t / .007)
            release = min(1, (duration - t) / .025)
            if voice == 'bass':
                tone = math.sin(phase) + .18 * math.sin(phase * 2)
                env = attack * release * math.exp(-t * 4)
            elif voice == 'pad':
                tone = math.sin(phase) + .15 * math.sin(phase * 3)
                env = min(1, t / .08) * min(1, (duration - t) / .15)
            else:
                tone = math.sin(phase) + .3 * math.sin(phase * 2) + .1 * math.sin(phase * 3)
                env = attack * release * math.exp(-t * 6)
            mix[(origin + i) % length] += tone * env * gain

    def drum(at, kind, gain):
        duration = .16 if kind == 'kick' else .09
        origin = round(at * RATE)
        for i in range(round(duration * RATE)):
            t = i / RATE
            env = (1 - t / duration) ** 3 * min(1, t / .002)
            tone = math.sin(2 * math.pi * (78 * t - 130 * t * t)) if kind == 'kick' else rng.uniform(-1, 1)
            mix[(origin + i) % length] += gain * env * tone

    # A four-chord nighttime motif, with a responding phrase on alternate passes.
    chords = [(48, 52, 55, 59), (45, 48, 52, 55), (53, 57, 60, 64), (55, 59, 62, 65)]
    melody = [[76, 79, 83, 79, 76, 74, 72, 74], [76, 72, 69, 72, 76, 79, 76, 72],
              [77, 81, 84, 81, 79, 77, 76, 72], [74, 79, 83, 86, 83, 79, 74, 71]]
    for bar in range(bars):
        chord = chords[bar % 4]
        at = bar * 4 * beat
        for pitch in chord[1:]:
            note(at, pitch, beat * 3.9, .027, 'pad')
        for b in range(4):
            note(at + b * beat, chord[0] + (12 if b % 2 else 0), beat * .72, .18, 'bass')
            if energetic or b % 2 == 0:
                drum(at + b * beat, 'kick', .25 if energetic else .13)
            if energetic and b % 2:
                drum(at + b * beat, 'snare', .14)
            for half in range(2):
                if energetic:
                    drum(at + (b + half * .5) * beat, 'hat', .04)
        for step, pitch in enumerate(melody[bar % 4]):
            if energetic == 0 and step in (3, 7):
                continue
            if bar >= 4 and step in (2, 6):
                pitch += 12
            note(at + step * beat / 2, pitch, beat * .62, .115 if energetic < 2 else .14)
            # Quiet musical echo, including wraparound at the loop boundary.
            note(at + (step / 2 + .75) * beat, pitch, beat * .5, .025)
        if energetic == 2:
            for step in range(16):
                note(at + step * beat / 4, chord[step % 4] + 12, beat * .22, .04)
    peak = max(abs(x) for x in mix)
    pcm = array('h', (round(x / max(peak, 1) * 26000) for x in mix))
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as out:
        out.setparams((1, 2, RATE, len(pcm), 'NONE', 'not compressed'))
        out.writeframes(pcm.tobytes())
    print(f'{name}: {len(pcm)/RATE:.2f}s, peak {max(abs(x) for x in pcm)}, seam {abs(pcm[0]-pcm[-1])}')

if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    compose('shelter', 96, 8, 0)
    compose('night-walk', 128, 16, 1)
    compose('boss', 152, 16, 2)
