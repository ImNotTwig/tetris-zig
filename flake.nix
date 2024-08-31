{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    zls.url = "github:zigtools/zls";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, zls, zig-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
	    pkgs = nixpkgs.legacyPackages.${system};
		zig = zig-overlay.packages.${system}.master;
      in 
	  {
	    devShells.default =
          pkgs.mkShell { 
            buildInputs = [
              zig
			  zls.packages.${system}.zls
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
        };
      }
    );
}
