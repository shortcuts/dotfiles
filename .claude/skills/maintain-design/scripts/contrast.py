#!/usr/bin/env python3
"""WCAG contrast ratios. Usage: contrast.py FG:BG [FG:BG ...]  (hex, with or without #).

Prints ratio plus AA verdicts: normal text needs 4.5, large text and UI parts need 3.
Why a script: the agent must report measured ratios, never estimated ones.
"""
import sys


def lum(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


for pair in sys.argv[1:]:
    fg, bg = pair.split(":")
    a, b = sorted((lum(fg), lum(bg)), reverse=True)
    ratio = (a + 0.05) / (b + 0.05)
    print(f"{fg} on {bg}: {ratio:.2f}:1  text {'PASS' if ratio >= 4.5 else 'FAIL'}  large/UI {'PASS' if ratio >= 3 else 'FAIL'}")
