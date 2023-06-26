# SPEC CPU 2006/2017 scripts, patches and configs

## SPEC CPU 2006/2017 Build

The two scripts `build_2006.sh` and `build_2017.sh` build SPEC CPU 2006 and 2017 respectively.

- They should be run on RISC-V machines (or in QEMU).
- The given configs are used to build on SiFive HiFive Unmatched.
- The scripts compile RISC-V tools first then use them to build the benchmark executables.
- Please note: during the script running, there will be some confirmations about "some perl tests failed", "type yes to continue", "one of SPEC CPU 2017 suite failed" etc. Yes to them.
- SPEC CPU suites files used are `cpu2006-1.2.tar.xz` and `cpu2017-1.1.8.tar.xz`, the original ISOs are not used.

## SPEC CPU 2006/2017 Run

Please refer to SPEC CPU's own doc
- https://www.spec.org/cpu2006/Docs/install-guide-unix.html
- https://www.spec.org/cpu2017/Docs/install-guide-unix.html
