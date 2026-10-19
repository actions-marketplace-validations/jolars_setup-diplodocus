{ pkgs, ... }:

{
  packages = with pkgs; [
    actionlint
    gh
    jq
    nodejs
    panache
    powershell
    shellcheck
    shfmt
    xz
  ];

  git-hooks.hooks = {
    actionlint.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
    panache = {
      enable = true;
      name = "Panache";
      entry = "${pkgs.panache}/bin/panache format --check";
      files = "\\.md$";
    };
  };
}
