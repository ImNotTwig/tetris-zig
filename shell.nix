{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.zig
    pkgs.zls
    pkgs.xorg.libX11
    pkgs.xorg.libXinerama
    pkgs.xorg.libXcursor
    pkgs.xorg.libXrandr
    pkgs.xorg.libXi.dev
    pkgs.xwayland
    pkgs.glfw
    pkgs.glfw-wayland
    pkgs.libGL
  ];
}
