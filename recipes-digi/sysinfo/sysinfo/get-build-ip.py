#!/usr/bin/env python3
# Print the IPv4 address of the build host's "main" network interface.
#
# Selection order:
#   1. interface named on the command line (CUSTOM_BUILD_IF), if it has an IPv4 address
#   2. first wired physical NIC (lowest ifindex) that has an IPv4 address; this
#      skips lo, bridges, veth, docker, tun/tap, VLANs, bonds and wireless cards
#   3. interface of the default route (covers br0/bond0 setups and containers)
# Prints nothing if no address is found. Always exits 0.
import fcntl
import os
import socket
import struct
import sys

SYS_NET = "/sys/class/net"
SIOCGIFADDR = 0x8915


def ipv4_of(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        req = struct.pack("256s", ifname[:15].encode())
        res = fcntl.ioctl(s.fileno(), SIOCGIFADDR, req)
        return socket.inet_ntoa(res[20:24])
    except OSError:
        return None
    finally:
        s.close()


def ifindex(name):
    try:
        with open(os.path.join(SYS_NET, name, "ifindex")) as f:
            return int(f.read().strip())
    except (OSError, ValueError):
        return 1 << 30


def wired_physical(name):
    base = os.path.join(SYS_NET, name)
    return (os.path.exists(os.path.join(base, "device"))
            and not os.path.exists(os.path.join(base, "wireless"))
            and not os.path.exists(os.path.join(base, "phy80211")))


def default_route_iface():
    best = None
    try:
        with open("/proc/net/route") as f:
            next(f)
            for line in f:
                c = line.split()
                if len(c) >= 8 and c[1] == "00000000" and int(c[3], 16) & 1:
                    metric = int(c[6])
                    if best is None or metric < best[0]:
                        best = (metric, c[0])
    except (OSError, StopIteration, ValueError):
        pass
    return best[1] if best else None


def main():
    forced = sys.argv[1].strip() if len(sys.argv) > 1 else ""
    if forced:
        ip = ipv4_of(forced)
        if ip:
            print(ip)
            return

    try:
        names = sorted((n for n in os.listdir(SYS_NET) if n != "lo"), key=ifindex)
    except OSError:
        names = []
    for name in names:
        if wired_physical(name):
            ip = ipv4_of(name)
            if ip:
                print(ip)
                return

    name = default_route_iface()
    if name:
        ip = ipv4_of(name)
        if ip:
            print(ip)


if __name__ == "__main__":
    main()