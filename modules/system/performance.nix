# Perf tuning for a dev/multitask desktop (compilation, VMs/containers,
# multiple IDEs/browsers) -- not gaming latency. See hosts/nixos for the real
# hardware this targets: AMD Ryzen + NVMe root, 30G RAM, 8G disk swap.
{ config, lib, pkgs, ... }:

{
  # Compressed RAM swap ahead of the existing NVMe swap partition (it keeps
  # its own priority, untouched, as a fallback once zram fills up).
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
  };

  # zram's own guidance: with fast compressed swap as the primary tier,
  # swapping earlier (vs. the disk-swap-oriented default of 60) is cheap and
  # frees page cache for compiler/IDE workloads sooner.
  boot.kernel.sysctl."vm.swappiness" = 100;

  # cgroups-v2-based OOM handling (already the default on NixOS) instead of
  # earlyoom: kills the worst offender in the overloaded cgroup before a
  # runaway build/VM locks up the whole session.
  systemd.oomd.enable = true;

  nix.settings = {
    max-jobs = "auto";
    cores = 0;
    auto-optimise-store = true;
  };
}
