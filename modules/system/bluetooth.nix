# Bluetooth: Bluez with experimental features + auto-reconnect of paired
# devices at boot/user-session start (Bluetooth audio + input reliability).
{ config, pkgs, lib, ... }:

{
  # --- Bluez daemon config ---
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # BLE + experimental features (needed for some headsets/mice).
        Experimental = true;
        FastConnectable = true;
        JustWorksRepairing = "always";
      };
      Policy = {
        # Re-enable the controller automatically on resume/restart.
        AutoEnable = true;
      };
    };
  };

  # --- Auto-reconnect paired devices at session start (same logic as the
  # wb-bt toggle / BluetoothPage "Reconnecter tous"). bluetoothctl connect
  # is idempotent and offloaded with `&` so a slow device doesn't block the
  # rest of session startup.
  systemd.user.services.bluetooth-autoconnect = {
    unitConfig.Description = "Reconnect paired Bluetooth devices";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 2; bluetoothctl devices Paired 2>/dev/null | awk \"{print \\$2}\" | while read -r mac; do [ -n \"\\$mac\" ] && bluetoothctl connect \"\\$mac\" >/dev/null 2>&1 & done'";
    };
    wantedBy = [ "graphical-session.target" ];
  };
}
