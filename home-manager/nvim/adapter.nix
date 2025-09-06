# ./nixvim/adapter.nix
{ lib, ... }:
{
  imports = [
    (lib.mkAliasOptionModule [ "programs" "nixvim" ] [ "nixvim" ])

    ./nvim.nix
    ./nvim-cmp.nix
    ./which-key.nix
  ];
}
