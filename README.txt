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

1) write image to 1GB (or larger) USB flash memory via gunzip(1) and dd(1)
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

- DCburn for 7.0 will fetch a raw GENERIC.bin kernel binary from
  the official ftp site.
- DCburn for 7.0 will also fetch cdrtools packages binary from
  the official ftp site to pkg_add(1) it.


6. Changes

20101114:
 - Initial revision

20101121:
 - Fix hostname from dcserv to dcburn (yes, bad pasto...)

20130522:
 - Update for NetBSD 6.1.

20151122:
 - Update for NetBSD 7.0.

---
Izumi Tsutsui
tsutsui@NetBSD.org
