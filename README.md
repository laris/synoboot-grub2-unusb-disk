# synoboot-grub2-unusb-disk
Create grub2 bootloader to load synoboot in un-usb disk, HDD or SSD

Here is the reproduce procedure.
 - Environment, Intel Atom D2550 MB with 2 x 3.5" HDDs for RAID0, 2G RAM, 2xGbE NICs, successfully to install DSM6.2 using junboot 1.03b
 - Partition table list
```
--------------------------------------------------------------------------------------------------
root@DSM2550:~# fdisk -l /dev/sda (sdb have same partition table)
Disk /dev/sda: 931.5 GiB, 1000204886016 bytes, 1953525168 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x00077232

Device     Boot   Start        End    Sectors   Size Id Type
/dev/sda1          2048    4982527    4980480   2.4G fd Linux raid autodetect
/dev/sda2       4982528    9176831    4194304     2G fd Linux raid autodetect
/dev/sda3       9437184 1953320351 1943883168 926.9G fd Linux raid autodetect
--------------------------------------------------------------------------------------------------
```
- DEBUG console, i attached one TTY serial converter on ttyS1 to monitor boot log
- create host, Debian9/PVE5.2

- Precedure
 - 1, mount synoboot_Junboot_v1.03b_ds3617_6.2.img file and copy junboot file into new directory ${HOST temp dir}/boot for DSM
 - 2, create /boot/grub/i386-pc and copy host /usr/lib/grub/i386-pc/* into it.
 - 3, copy grub.cfg grubenv into /boot/grub
```
--------------------------------------------------------------------------------------------------
root@pvedsm1 ➜  boot ls bzImage extra.lzma info.txt rd.gz zImage
bzImage  extra.lzma  info.txt  rd.gz  zImage
root@pvedsm1 ➜  boot ls grub
grub.cfg  grubenv  i386-pc
--------------------------------------------------------------------------------------------------
```
- 4, create core.img, I add mdraid09_be so the grub can load the DSM raid1 /dev/md0 in /boot
```
grub-mkimage -v -C xz -O i386-pc -o ./boot/grub/i386-pc/core.img -p "(hd0,msdos1)/boot/grub" -d ./boot/grub/i386-pc biosdisk part_msdos mdraid09_be ext2
```
- 5, cp the ${HOST temp dir}/boot into DSM /boot
- 6, dd the boot.img and core.img into MBR and 2nd sector of /dev/sda
```--------------------------------------------------------------------------------------------------
root@DSM2550:/boot# dd if=grub/i386-pc/boot.img of=/dev/sda bs=446 count=1
1+0 records in
1+0 records out
446 bytes (446 B) copied, 0.000316455 s, 1.4 MB/s
root@DSM2550:/boot# dd if=grub/i386-pc/core.img of=/dev/sda bs=512 seek=1
60+1 records in
60+1 records out
30906 bytes (31 kB) copied, 0.0116049 s, 2.7 MB/s
--------------------------------------------------------------------------------------------------
```
- 7, then reboot and remove usb disk, the bootloader can work but then got "mount failed" error and vga screen stuck in info.txt
```
--------------------------------------------------------------------------------------------------
                          GNU GRUB  version 2.02-pve6

 +----------------------------------------------------------------------------+
 |*DS3617xs 6.2 Baremetal with Jun's Mod v1.03b                               |
 | DS3617xs 6.2 Baremetal with Jun's Mod v1.03b Reinstall                     |
 | DS3617xs 6.2 VMWare/ESXI with Jun's Mod v1.03b                             |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 +----------------------------------------------------------------------------+

      Use the ^ and v keys to select which entry is highlighted.
      Press enter to boot the selected OS, `e' to edit the commands
      before booting or `c' for a command-line.

mount failed
--------------------------------------------------------------------------------------------------
```
I also searched the xpenology forum but rare discussion about mount failed error, especially it will show in PVE/proxmox environment  when DSM as VM, but work when loader as sata disk.
https://xpenology.com/forum/topic/12952-dsm-62-loader/?page=5&tab=comments#comment-93988

what's mean of the mount failed? the ramdisk mount rootfs? or lacking of kernel module to mount rootfs/ramdisk?

Also try to build virtio-net kernel module but got panic after load extra.lzma, so if provide the .config file, that will be excellent to compile the kernel bzImage to debug.
```
--------------------------------------------------------------------------------------------------
Post init
Updating /tmpRoot//usr/lib/modules/update/virtio_net.ko...

==================== start udevd ====================
===== trigger device plug event =====
[   46.315103] general protection fault: 0000 [#1] SMP
[   46.316008] Modules linked in: broadwell_synobios(PO) aufs(F) 9p(F) fscache(F) 9pnet_virtio(F) 9pnet(F) virtio_mmio(F) virtio_pci(F) virtio_net(F) virtio_scsi(F) virtio_blk(F) virtio_ring(F) virtio(F) button(F) ax88179_178a(F) usbnet tg3(F) r8169(F) cnic(F) bnx2(F) vmxnet3(F) pcnet32(F) e1000(F) sfc(F) netxen_nic(F) qlge(F) qlcnic(F) qla3xxx(F) pch_gbe(F) ptp_pch(F) sky2(F) skge(F) jme(F) ipg(F) uio(F) alx(F) atl1c(F) atl1e(F) atl1(F) libphy(F) mii(F) exfat(O) btrfs synoacl_vfs(PO) zlib_deflate hfsplus md4 hmac bnx2x(O) libcrc32c mdio mlx5_core(O) mlx4_en(O) mlx4_core(O) mlx_compat(O) compat(O) qede(O) qed(O) atlantic(O) r8168(OF) tn40xx(O) i40e(O) ixgbe(O) be2net(O) igb(O) i2c_algo_bit e1000e(O) dca vxlan fuse vfat fat glue_helper lrw gf128mul ablk_helper arc4 cryptd ecryptfs sha256_generic sha1_generic ecb aes_x86_64 authenc des_generic ansi_cprng cts md5 cbc cpufreq_conservative cpufreq_powersave cpufreq_performance cpufreq_ondemand mperf processor thermal_sys cpufreq_stats freq_table dm_snapshot crc_itu_t crc_ccitt quota_v2 quota_tree psnap p8022 llc sit tunnel4 ip_tunnel ipv6 zram(C) sg etxhci_hcd mpt3sas(O) mpt2sas(O) megaraid_sas(F) mptctl(F) mptsas(F) mptspi(F) mptscsih(F) mptbase(F) scsi_transport_spi(F) megaraid(F) megaraid_mbox(F) megaraid_mm(F) vmw_pvscsi(F) BusLogic(F) usb_storage xhci_hcd uhci_hcd ohci_hcd(F) ehci_pci(F) ehci_hcd(F) usbcore usb_common mv14xx(O) p(OF) [last unloaded: broadwell_synobios]
[   46.328738] CPU: 0 PID: 7844 Comm: cat Tainted: PF        C O 3.10.105 #23739
[   46.328738] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS rel-1.11.0-0-g63451fca13-prebuilt.qemu-project.org 04/01/2014
[   46.328738] task: ffff880070588040 ti: ffff880070c70000 task.ti: ffff880070c70000
[   46.328738] RIP: 0010:[<ffffffff813fd761>]  [<ffffffff813fd761>] __ethtool_get_link_ksettings+0x61/0x110
[   46.328738] RSP: 0018:ffff880070c73e08  EFLAGS: 00010202
[   46.328738] RAX: ffffffffa0dd67c0 RBX: ffff880070c73e58 RCX: 0000000000000000
[   46.328738] RDX: ffffffffa0dd67c0 RSI: ffff880070c73e58 RDI: ffff88007bad8000
[   46.328738] RBP: ffff88007bad8000 R08: ffffea00018a24d8 R09: 000000000006c49f
[   46.328738] R10: 00000000000006e3 R11: 0000000000000246 R12: ffff8800709cc000
[   46.328738] R13: 0000000000020000 R14: ffff880037783a58 R15: ffff88007bad83f8
[   46.328738] FS:  00007f1ad7419700(0000) GS:ffff88007fc00000(0000) knlGS:0000000000000000
[   46.328738] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   46.328738] CR2: 0000000000404950 CR3: 0000000070955000 CR4: 00000000000006f0
[   46.328738] DR0: 0000000000000000 DR1: 0000000000000000 DR2: 0000000000000000
[   46.328738] DR3: 0000000000000000 DR6: 00000000ffff0ff0 DR7: 0000000000000400
[   46.328738] Stack:
[   46.328738]  ffff88007b85cc00 00000000000000a8 ffffffff810d3f3e ffff880000000000
[   46.328738]  0000000000000014 0000000000000000 ffff88007bad83e8 ffffffffffffffea
[   46.328738]  ffff8800709cc000 ffffffff8140f37f 0000000000000000 0000000000000000
[   46.328738] Call Trace:
[   46.328738]  [<ffffffff810d3f3e>] ? handle_mm_fault+0x13e/0x2a0
[   46.328738]  [<ffffffff8140f37f>] ? show_speed+0x4f/0x80
[   46.328738]  [<ffffffff812ff327>] ? dev_attr_show+0x17/0x50
[   46.328738]  [<ffffffff81166dc9>] ? sysfs_read_file+0x99/0x170
[   46.328738]  [<ffffffff810f6b49>] ? vfs_read+0x99/0x160
[   46.328738]  [<ffffffff810f81c9>] ? SyS_read+0x59/0xb0
[   46.328738]  [<ffffffff814bcc32>] ? system_call_fastpath+0x16/0x1b
[   46.328738] Code: c7 03 00 00 00 00 48 c7 43 40 00 00 00 00 48 89 de 48 83 e7 f8 48 29 f9 83 c1 48 c1 e9 03 f3 48 ab 48 89 ef 48 8b 85 98 01 00 00 <ff> 90 70 01 00 00 89 c5 48 83 c4 30 89 e8 5b 5d 41 5c c3 0f 1f
[   46.328738] RIP  [<ffffffff813fd761>] __ethtool_get_link_ksettings+0x61/0x110
[   46.328738]  RSP <ffff880070c73e08>
[   46.378135] ---[ end trace 95c4ea70a0ec5680 ]---
[   48.676664] bio: create slab <bio-2> at 2
--------------------------------------------------------------------------------------------------
```
https://xpenology.com/forum/topic/7884-xpenology-runing-on-docker/?do=findComment&comment=95342

Also research about the DDSM in this post
https://xpenology.com/forum/topic/13110-does-migrating-ddsm-to-linux-dockerlxc-make-sense/?do=findComment&comment=95486
