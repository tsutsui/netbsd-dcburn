DCburn - NetBSD/dreamcast bootable CD-R burner


1. What's DCburn

This "DCburn" image provides easy setup to burn
bootable CD-R for NetBSD/dreamcast.


2. What DCburn image contains

This image contains a bootable NetBSD/i386 file system image
that has necessary cdrtools package, NetBSD/dreamcast kernel
and Makefile to burn bootable CD-R.  Some tools and files for
actual bootstrap are fetched via Internet.


3. Requirements

- x86 based PC with NIC and CD burner which can boot from USB devices
  (and is supported by NetBSD/i386 :-)
- Internet connection via DHCP


4. How to use DCburn

1) write image to 512MB (or larger) USB flash memory via gzip(1) and dd(1)
   (or Rawrite32.exe tool for Windows),
    Rawrite32.exe tool can be found here:
    http://www.NetBSD.org/~martin/rawrite32/
2) put it on your x86 PC and boot it (per machine specific procedure)
3) login as "root" on "login:" prompt
4) make sure you have Internet connection (by "ping www.netbsd.org" etc)
   (note you can ignore "no interfaces have a carrier" message during boot)
5) put blank CD-R media in your drive
6) just type "make" on shell prompt
7) you'll get it!


5. Misc

- DCburn image contains a raw binary GENERIC kernel of NetBSD/dreamcast
  generated from official NetBSD 5.1 netbsd-GENERIC ELF binary by objcopy(1).
- DCburn image also contains cdrtools-3.00.tgz packages binary for
  NetBSD/i386 5.0.2 fetched from ftp.NetBSD.org.


6. Changes

20101114:
 - Initial revision

20101121:
 - Fix hostname from dcserv to dcburn (yes, bad pasto...)

---
Izumi Tsutsui
tsutsui@NetBSD.org
