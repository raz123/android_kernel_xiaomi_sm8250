# alioth-kernel-20260610-115846

**Build:** 2026-06-10 11:58 UTC  
**Device:** POCO F3 (alioth) SM8250  
**Kernel:** Linux 4.19.325 (LineageOS 23.2)  
**Base:** origin/lineage-23.2 (49c1c401df89)  
**Commits:** 67 ahead of base  

---

## Optimization Suite (Prompt E)

### LRNG — Linux Random Number Generator (14 patches)
- Main LRNG implementation + 4.19 backport
- DRNG per NUMA node
- sysctls, /proc interface, switchable DRNG
- SP800-90A DRBG, crypto API PRNG, Jitter RNG
- SP800-90B health tests, raw entropy interface
- Power-on and runtime self-tests
- Merged v45 from Linux 5.15.y
- Source: arrowos/arrow-13.1

### Binder Fixes (9 patches)
- kvcalloc for OOM mitigation
- Don't log on EINTR, use EINTR for interrupted wait
- Memory leak fix in binder_init()
- Memory leaks of spam/pending work
- Stop dmesg spam, suppress debug logging
- Fix MAX_USER_RT_PRIO usage
- Sources: kopsources/lineage-23, flicker/sixteen-qpr2

### KGSL GPU Memory Pool (6 patches)
- Lock-less list for page pools
- Stop slab shrinker when no reclaim
- Fix page_count type, cache mode kernel mapping
- kthread instead of workqueue for event work
- Fix NULL pointer dereference
- Sources: danda420/bpf, timisong/magictime-new, flicker/sixteen-qpr2

### EAS / Schedutil Tuning (5 patches)
- Tune uclamp values for efficiency
- Set cpu_shares with uclamp assist
- Condition EAS enablement on FIE support
- Don't enable EAS on SMT systems
- Avoid stale CPU util_est for schedutil
- **Reverted:** f3ab522d324c (incompatible kernel 6.8 EAS infrastructure)
- Sources: timisong/magictime-new, kopsources/lineage-23

### AstideLabs Cherry-Picks (6 patches)
- Binder bitmap faster descriptor lookup
- WALT eval_need cleanup + improvements
- mm: Increase min_free_kbytes to 32MB
- staging: Reclaim pages while using camera
- Source: astidelabs/android16-aptusitu

### BBRv1 Fixes (1 patch)
- Centralize gain-setting code
- (2 additional fixes already present in tree)
- Source: arrowos/arrow-13.1

### MGLRU — Multi-Gen LRU (20 patches)
- Full MGLRU backport: groundwork, minimal implementation
- Rmap locality exploitation, page table walk support
- Multi-memcg optimization, debugfs interface
- Thrashing prevention, kill switch, admin guide
- Qcom baseline fix + 10 additional fixup patches
- Source: kopsources/lineage-23

### Defconfig Changes
- CONFIG_LRNG=y
- CONFIG_UCLAMP_TASK=y (was disabled)
- CONFIG_LRU_GEN=y
- CONFIG_LRU_GEN_ENABLED=y

### Build Fixes (4 patches)
- SHA1_DIGEST_WORDS redefinition guard (cryptohash.h + sha.h)
- EAS overutilized revert (WALT-based restore)
- LRNG sha256 missing include
- KGSL unused param + snapshot init removal

---

## Known Issues
- BBRplus skipped (multi-file module, incompatible Kconfig)
- DVFS headroom series reverted (already reverted in base)
- macOS APFS case-sensitivity: 13 files under skip-worktree
