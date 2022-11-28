#!/usr/bin/env bash

# Special thanks to:
# https://github.com/Leoyzen/KVM-Opencore
# https://github.com/thenickdude/KVM-Opencore/
# https://github.com/qemu/qemu/blob/master/docs/usb2.txt
#
# qemu-img create -f qcow2 mac_hdd_ng.img 128G
#
# echo 1 > /sys/module/kvm/parameters/ignore_msrs (this is required)

############################################################################
# NOTE: Tweak the "MY_OPTIONS" line in case you are having booting problems!
############################################################################

MY_OPTIONS="+ssse3,+sse4.2,+popcnt,+avx,+aes,+xsave,+xsaveopt,check"

# This script works for Big Sur, Catalina, Mojave, and High Sierra. Tested with
# macOS 10.15.6, macOS 10.14.6, and macOS 10.13.6.

# ALLOCATED_RAM="4096" # MiB
ALLOCATED_RAM="8192" # MiB
CPU_SOCKETS="1"
CPU_CORES="2"
CPU_THREADS="4"

REPO_PATH="."
OVMF_DIR="."
ISO_DIR="/mnt/allData/apps/ISOs/mac"
DISK_DIR="/mnt/allData/apps/vmdiskBackup"

# shellcheck disable=SC2054
args=(
  -enable-kvm -m "$ALLOCATED_RAM" 
  # -cpu Penryn,kvm=on,vendor=GenuineIntel,+invtsc,vmware-cpuid-freq=on,"$MY_OPTIONS"
  -cpu Haswell-noTSX,vendor=GenuineIntel,+invtsc,+hypervisor,kvm=on,vmware-cpuid-freq=on
  -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off
  # -global nec-usb-xhci.msi=off
  -machine q35
  -usb -device usb-kbd -device usb-mouse
  -smp "$CPU_THREADS",cores="$CPU_CORES",sockets="$CPU_SOCKETS"
  -device usb-ehci,id=ehci
  # -device usb-kbd,bus=ehci.0
  # -device usb-mouse,bus=ehci.0
  -device nec-usb-xhci,id=xhci,p2=7,p3=7
  -global nec-usb-xhci.msi=off
  # -device usb-host,vendorid=0x8086,productid=0x0808  # 2 USD USB Sound Card
  # -device usb-host,vendorid=0x1b3f,productid=0x2008  # Another 2 USD USB Sound Card
  -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
  -drive if=pflash,format=raw,readonly=on,file="$REPO_PATH/$OVMF_DIR/OVMF_CODE.fd"
  -drive if=pflash,format=raw,file="$REPO_PATH/$OVMF_DIR/OVMF_VARS-1024x768.fd"
  -smbios type=2
  -device ich9-intel-hda -device hda-duplex
  -device ich9-ahci,id=sata
  # -device ide-hd,bus=sata.1,drive=OpenCoreBoot
  # -drive if=none,id=OpenCoreBoot,format=qcow2,file="$REPO_PATH/OpenCore/OpenCore.qcow2"
  -drive if=none,id=OpenCoreBoot,file="$ISO_DIR/OpenCore-v19.iso"
  -device ide-hd,bus=sata.0,drive=OpenCoreBoot,bootindex=1
  -drive if=none,id=MacDisk,format=qcow2,file="$DISK_DIR/macOSVentura.img"
  -device ide-hd,bus=sata.1,drive=MacDisk
  -drive if=none,id=InstallMedia,file="$ISO_DIR/Ventura-full.img"
  -device ide-hd,bus=sata.2,drive=InstallMedia
  # -netdev tap,id=net0,ifname=tap0,script=no,downscript=no -device virtio-net-pci,netdev=net0,id=net0,mac=52:54:00:c9:18:27
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0,id=net0,mac=52:54:00:c9:18:27
  # -netdev user,id=net0 -device vmxnet3,netdev=net0,id=net0,mac=52:54:00:c9:18:27  # Note: Use this line for High Sierra
  -monitor stdio
  -device VGA,vgamem_mb=128
  -vga virtio
)

qemu-system-x86_64 "${args[@]}"