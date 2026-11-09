# Mac mini RAM upgrade

The lite Mac mini (Macmini8,1, Late 2018, i7-8700B) ships with 8 GB. That is too little
for 3–4 concurrent agent sessions: each Claude session uses about 400 MB plus its MCP
servers, and the machine swaps (1.7 GB swap in use, measured 2026-11-09).

## Compatible memory

- 2 SO-DIMM slots, up to 64 GB total
- DDR4-2666, 260-pin, unbuffered, non-ECC
- Any mix of 8, 16 or 32 GB modules works. Install a matched pair for dual-channel speed.
- 32 GB (2×16) covers agent work. 64 GB (2×32) removes RAM as a limit.

Apple states the RAM is not user-installable and sends upgrades to an Apple Store or an
Authorised Service Provider. A DIY install is at your own risk.

## Install

Takes 10–20 minutes. Tools: T6 and T9 Torx drivers, a spudger, an opening tool.
The logic board slides out of the case to reach the slots.

1. Follow the iFixit guide step by step.
2. After boot, check the new size: `sysctl -n hw.memsize`.

## References

- [iFixit: Mac mini Late 2018 Memory (RAM) Replacement](https://fr.ifixit.com/Tutoriel/Mac+mini+Late+2018+Memory+(RAM)+Replacement/115309?lang=en)
- [9to5Mac: How to upgrade RAM on the 2018 Mac mini](https://9to5mac.com/2018/11/08/how-to-upgrade-ram-on-2018-mac-mini/)
- [9to5Mac: video walkthrough](https://9to5mac.com/2018/11/20/how-to-upgrade-ram-2018-mac-mini-video/)
- [MacRumors: RAM upgrade process for the 2018 Mac mini](https://www.macrumors.com/2018/11/08/2018-mac-mini-ram-upgrade-process/)
- [iMore: Which RAM can you use in the 2018 Mac mini?](https://www.imore.com/which-ram-can-you-use-2018-mac-mini)
- [Apple: Upgrade or install memory in your Mac mini](https://support.apple.com/en-in/102328)

## Where to buy

- [OWC memory for Macmini8,1](https://eshop.macsales.com/upgrades/mac-mini-late-2018-3.6-ghz/memory): the link opens the 3.6 GHz page. Select the 3.2 GHz i7 model.
- [A-Tech 64 GB kit (2×32 GB DDR4-2666 SO-DIMM)](https://atechmemory.com/products/apple-mac-mini-late-2018-memory-ram-64gb-kit-2x32gb-ddr4-2666-sodimm): about $353 in 2026.
