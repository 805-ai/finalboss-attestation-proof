# FinalBoss on an attested H100: 33 bundles, 33 VERIFIED

**What this is.** On October 27, 2026, FinalBoss Technology Inc. ran two of its engines, audited and hardened with Claude Mythos 5.1, inside an Intel TDX confidential VM with an NVIDIA H100 on VoltageGPU: the kernel gate (ring zero) and BEAST. During those runs the VM produced 29 attestation bundles. Each bundle binds a fresh challenge and a statement about the workload to an Intel TDX quote (signed by the CPU, chained to Intel's root) and to NVIDIA attestation tokens (signed by NVIDIA, chained to NVIDIA's root).

**Who checked them.** VoltageGPU (Julien Aubry, founder) ran voltage-verify 0.2.3 on all 29 attestation bundles from FinalBoss's October 27 runs. All 29 returned VERIFIED. (October 28, 2026, about 20:35 UTC, with Intel's and NVIDIA's signing material fetched live.) His 29 outputs are in `outputs_voltagegpu_20261028/`, exactly as he sent them.

**And the October 28 box.** On October 29, 2026 at 20:46 UTC, VoltageGPU ran voltage-verify 0.2.3 on four bundles from FinalBoss's October 28 kernel gate run (pod cmvse31cg0001jh081gdbrk8z, gate v9): cycle 1, cycle 4 (the cycle the signing key rotated), cycle 8 (the last cycle before the gate was killed on purpose) and cycle 14 (the last cycle, after the gate resumed). All four returned VERIFIED, 14 PASS lines each, no warnings. His four outputs are in `outputs_voltagegpu_box4_20261029/`, exactly as he sent them.

**Check it yourself.** All 33 bundles are in this repository, byte for byte what VoltageGPU checked. One command installs the same open-source tool and verifies all 33:

```
git clone https://github.com/805-ai/finalboss-attestation-proof.git
cd finalboss-attestation-proof
bash check.sh
```

It prints `FINGERPRINTS=33/33 OK`, then `VERIFIED=33/33`, then `CHECK=PASS`, or exactly which bundle failed. `bash check.sh --offline` does the same using only the Intel and NVIDIA material stored inside each bundle. Needs Python 3.10 or newer and about one minute. Nothing here needs a GPU, an account, or FinalBoss software.

## The two runs

| run | VoltageGPU pod | bundles | created (UTC, Oct 27 2026) | what each bundle binds |
|---|---|---|---|---|
| kernel gate (ring zero), gate v8 | cmvqydo2q0001k108zqfrojf7 | 16 (2 smoke + 14 of the 15 long-run cycles) | 17:39:59 to 18:08:19 | the cycle number, the session nonce, and the fingerprints of the two signing keys (Ed25519 and ML-DSA-87) behind the permit receipts |
| BEAST, continuous attestation | cmvr15pss0008l208s3g2nlss | 13 of the run's 115 chain links (every tenth plus the last) | 18:50:33 to 22:38:57 | a frozen snapshot of the live evidence, the root-command and SSH logs, the run key chain, and the SHA-256 of the previous chain link |

The long run has 15 cycles and 14 bundles because cycle 3 was a deliberate attestation failure injected by the operator: no bundle was produced, and the gate issued no permit that cycle ("attestation failed: no receipt, no permit"). That cycle's record is part of the full evidence set, not of this bundle set.

## What VERIFIED means, and what it does not

Each VERIFIED output is 14 PASS lines. In plain words:

- the bundle has not been altered since the VM produced it (the quote's report data equals a hash of the manifest; the NVIDIA nonce equals another hash of it; change one byte anywhere and both checks fail);
- the TDX quote is real: its signature chain verifies up to Intel's pinned SGX Root CA, Intel's TCB status is UpToDate, the platform certificate is not revoked, and the VM was not in debug mode (so the host could not read its memory);
- the GPU attestation is real: two NVIDIA-signed tokens verify up to a pinned NVIDIA intermediate, the GPU's measurements match NVIDIA's reference values, secure boot is on, debug is off, and the token was issued within seconds of the bundle.

All 29 outputs carry the same two summary lines:

```
TDX: MRTD eea8b6a814569a52bd1e12f6b869bb2d...  TCB UpToDate  QE UpToDate
GPU: GPU-0 GH100 driver 595.71.05 vbios 96.00.CF.00.01 measurements success
```

Inside the NVIDIA-signed tokens, all 29 carry the same GPU identifier (ueid 590134725016752485576067934392677329593117434109, hwmodel GH100, secure boot on, debug disabled): one and the same physical GPU behind both runs.

What it does not prove: the attestation shows what hardware the runs used and that the bundles are the ones that hardware signed. It does not, by itself, show what the engines did inside the VM. That evidence (the permit receipts, the kernel deny counts, the BEAST evidence chain) is a separate, larger record that FinalBoss walks through with reviewers in a working session; the manifests in these bundles name the fingerprints that record has to match.

## The 29 fingerprints

`bundles/SHA256SUMS.txt` is byte for byte the list that was inside the zip sent to VoltageGPU (zip SHA-256 `b8bd5ddf001eaa67db6251513cf7b69674cae038994afa5900f2f8f2e0f3ff07`).

| # | bundle | SHA-256 |
|---|---|---|
| 1 | kernel gate, smoke, cycle 1 (`ring_zero_20261027T172151Z/PHASE_D_ATTEST_SMOKE/cycles/bundle_0001.json`) | `20a1d61fb75b46c01f5575a888a2f4f10419b838d85dce03f343069dc26bdb3b` |
| 2 | kernel gate, smoke, cycle 2 (`ring_zero_20261027T172151Z/PHASE_D_ATTEST_SMOKE/cycles/bundle_0002.json`) | `78aa4673e3f871df79e06f644f8f3ff287018262f4e9e416e0b49144ff93d179` |
| 3 | kernel gate, long run, cycle 1 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0001.json`) | `737d1c17869d7939fbc08a2302a867ac924cea13b1c46e8a7b84b288f3be9f53` |
| 4 | kernel gate, long run, cycle 2 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0002.json`) | `1f32f410e01e9956aad6131e32fe737d2ab5c987c10a144fe9419166c5c419ce` |
| 5 | kernel gate, long run, cycle 4 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0004.json`) | `b5adb195575e5b73332655e4d2eecb4975fb4ef4c899d556c0672777e7fda052` |
| 6 | kernel gate, long run, cycle 5 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0005.json`) | `494fe18559d05924c1de4fa5cee544aefa120cd9345a1cc984a1f3e80afe61b7` |
| 7 | kernel gate, long run, cycle 6 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0006.json`) | `2a56ba1c74a10b52aa1c74fab9acce958e5c5aa58bde828644f1fd7071e38c41` |
| 8 | kernel gate, long run, cycle 7 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0007.json`) | `98742f8f165749f974ee31f52a60143b870b9e1e40dcf14f149c8d0be56a07dc` |
| 9 | kernel gate, long run, cycle 8 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0008.json`) | `be2c218c8b74b9ec105d974ec826ea4c0b36dfec6a141eb85ca9c1b0db9e8f5a` |
| 10 | kernel gate, long run, cycle 9 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0009.json`) | `850acf67714b0dbd6d9ec7a8b272d7d0e9949d2238a3b7cdaa7319e825feb45e` |
| 11 | kernel gate, long run, cycle 10 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0010.json`) | `806c792f35595c36d90b5a106d2518219f63550909ec38207ee47e10804a19be` |
| 12 | kernel gate, long run, cycle 11 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0011.json`) | `59ace8bddffd636eb26f4a1a39056f3abec79035093a5de0b9291e8e71e4ef2e` |
| 13 | kernel gate, long run, cycle 12 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0012.json`) | `da3b9f2feda93e76df91cd72a70aee7bc3c885d0388d4ec69beef0599244815a` |
| 14 | kernel gate, long run, cycle 13 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0013.json`) | `9d7c658dab0c9e8163994c3b7714f4e02acb2b3874e4a660703394e610f45a87` |
| 15 | kernel gate, long run, cycle 14 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0014.json`) | `3f43d39bf2679b7a8c4dfebd6bd88cbf4df440c43f0afd4a6d08a21f3b7bf52d` |
| 16 | kernel gate, long run, cycle 15 (`ring_zero_20261027T172151Z/PHASE_E_LONG_RUN/cycles/bundle_0015.json`) | `6e53fb2b9f4a8ba0582027b910f54d8035852cb9821afc52da05c6845ab347bf` |
| 17 | BEAST, chain link 1 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0001/guest/BUNDLE.json`) | `5359182c76475347ab371723cb9875a52ba05fafc1efae1be498d355271bf312` |
| 18 | BEAST, chain link 10 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0010/guest/BUNDLE.json`) | `e4c9fbe99661e30cfb667dc61a7f709cc5cf2f1cbcfaa3c798f83aca9795868f` |
| 19 | BEAST, chain link 20 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0020/guest/BUNDLE.json`) | `92b458018184e9640bfc68fa8a1a9ba970d1a31921f7784e62867ae6d63b1e6a` |
| 20 | BEAST, chain link 30 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0030/guest/BUNDLE.json`) | `a4d03d5f986c895895a0a09afd33a445ec9e716e4936f616869ffa223eacc783` |
| 21 | BEAST, chain link 40 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0040/guest/BUNDLE.json`) | `447cfefb7f3a04f40be56e98e8bb40a4c4c35ee439f56551f7920d6fce3ae0a3` |
| 22 | BEAST, chain link 50 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0050/guest/BUNDLE.json`) | `3f04d98d1d9e0ec1b770e3ac31795e48ffd69e8429dda37b34ea5d4bd783c734` |
| 23 | BEAST, chain link 60 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0060/guest/BUNDLE.json`) | `b143e04c142b8fae234d4e04cbdbc3146382a3bf498763501263612c5f5ebe6d` |
| 24 | BEAST, chain link 70 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0070/guest/BUNDLE.json`) | `b0acc41cb6f8c2d9be66b5f4eda984e989821c6a1df6fb1b371375257ddb13f7` |
| 25 | BEAST, chain link 80 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0080/guest/BUNDLE.json`) | `9233f98615aea80a264249d810939b52f625077c2630b5c2b15067286b09aa3a` |
| 26 | BEAST, chain link 90 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0090/guest/BUNDLE.json`) | `5c4f1e54d6ee49c9c1b6aa2de9a7506597fa533985201de61532eb0dcbc120c5` |
| 27 | BEAST, chain link 100 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0100/guest/BUNDLE.json`) | `719f90eb0631f7e974369fdbd194cf0b974ddd81cf4843f50cdcc4f66343ab76` |
| 28 | BEAST, chain link 110 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0110/guest/BUNDLE.json`) | `fdb78ee5ee0874646ef32a9f57017a802f5f240431b053dffdb70e4283606768` |
| 29 | BEAST, chain link 115 (`beast_20261027T183938Z/CONTINUOUS_ATTESTATION/link-0115/guest/BUNDLE.json`) | `f873fda798c8787191a0e2ff22e88d8f468bd889c7f54d81cde06d18ef37954e` |


## What is in this repository

- `bundles/` the 29 October 27 bundles (format `voltage-verify-bundle/1`) at the paths they had in the runs, plus `SHA256SUMS.txt`.
- `bundles_box4_20261028/` the four October 28 bundles, plus `SHA256SUMS.txt`, byte for byte the list inside the zip sent to VoltageGPU (zip SHA-256 `f281e4c92a3f1c0957ddd2696216a8e794881edd9e3b746d7f5288266170b94b`).
- `outputs_voltagegpu_20261028/` VoltageGPU's 29 outputs for the October 27 bundles, one file per bundle exactly as printed, with `SHA256SUMS.txt` and `VERIFY_INFO.txt` (tool version, date, input zip SHA-256), as Julien Aubry sent them.
- `outputs_voltagegpu_box4_20261029/` VoltageGPU's four outputs for those bundles, with their own `SHA256SUMS.txt`, as Julien Aubry sent them.
- `check.sh` the one command above.
- `outputs_finalboss_20261029/` what voltage-verify 0.2.3 printed for each bundle when FinalBoss re-ran it on October 29, 2026 (online mode).
- No FinalBoss source code, no private keys, no credentials, no network addresses. The bundles contain public certificates and public keys, signed tokens, and the workload manifests described above; nothing else.

## The tool

voltage-verify is VoltageGPU's open-source verifier (MIT): [github.com/VoltageGPU/voltage-verify](https://github.com/VoltageGPU/voltage-verify), [pypi.org/project/voltage-verify](https://pypi.org/project/voltage-verify/). The write-up of the kernel gate run is at [finalbosstech.com/ring-zero](https://finalbosstech.com/ring-zero).

FinalBoss Technology Inc., Oxnard, California. abraham@finalbosstech.com
