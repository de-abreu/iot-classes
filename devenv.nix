{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.devenv) root;
  zed-local = inputs.wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.zed-editor-fhs;
    env = {
      ZED_ENV = true;
      XDG_CONFIG_HOME = "${root}/.config";
    };
  };
in
{
  packages = with pkgs; [
    feh
    networkmanager
    opencode
    openssh
    pandoc
    rpi-imager
    sshpass
    xhost
    zed-local
  ];

  scripts.start.exec = "${lib.getExe zed-local} ${root}";

  languages.python = {
    enable = true;
    venv.enable = true;
    uv = {
      enable = true;
      sync.enable = true;
      sync.allGroups = true;
    };
  };

  dotenv.disableHint = true;
}
