# ./nixvim/adapter.nix
{ lib, config, ... }:
{
  # Make `nixvim` an alias of `programs.nixvim`
  imports = [
    (lib.mkAliasOptionModule [ "nixvim" ] [ "programs" "nixvim" ])
    ./nvim.nix
    ./nvim-cmp.nix
    ./which-key.nix
  ];

  # Forward all *definitions* made under programs.nixvim to nixvim as well
  # (useful when something reads `config.nixvim` in the same evaluation)
  config.nixvim = lib.mkAliasDefinitions config.programs.nixvim;
}
