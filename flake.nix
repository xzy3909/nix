{
  description = "Ace-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };
  
  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew}:
  let
    configuration = { pkgs, config, ... }: {
      nixpkgs.config.allowUnfree = true;
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
	  pkgs.mkalias
          pkgs.notion-app
	  pkgs.aldente
	  pkgs.moonlight-qt
	  pkgs.python3
	  pkgs.neofetch
	  pkgs.qbittorrent 
        ];

      homebrew = {
        enable = true;
	brews = [
	  "mas"
          "mpv"
	  "tmux"
	  "tpm"
	  "bc"
	  "coreutils"
	  "gawk"
	  "gh"
	  "glab"
	  "gsed"
	  "jq"
	  "nowplaying-cli"
	];
	casks = [
          #"tidal"
          "topnotch"
	  "raycast"
	  "crossover"
	  "calibre"
	  "anaconda"
	  "netnewswire"
	  "microsoft-office"
	  "font-monaspace-nerd-font"
	  "font-noto-sans-symbols-2"
          #"tor-browser"
	  "steam"
	  "rar"
	];
	masApps = { 
          #"Yoink" = 457622435;
          #"Microsoft Word" = 462054704;
          #"Microsoft Excel" = 462058435;
          #"Microsoft OneDrive" = 823766827;
	};
	onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };
      # Spotlight script
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = "/Applications";
       };
      in
       pkgs.lib.mkForce ''
       # Set up applications.
       echo "setting up /Applications..." >&2
       rm -rf /Applications/Nix\ Apps
       mkdir -p /Applications/Nix\ Apps
       find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
       while read -r src; do
         app_name=$(basename "$src")
         echo "copying $src" >&2
         ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
       done
           '';

      # macOS system settings.
      system.defaults = {
	dock.autohide = true;
	dock.persistent-apps = [
	  "${pkgs.notion-app}/Applications/Notion.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
	];
	finder.FXPreferredViewStyle = "clmv";
	loginwindow.GuestEnabled = false;
	NSGlobalDomain.AppleICUForce24HourTime = true;
	NSGlobalDomain.AppleInterfaceStyle = "Dark";
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      system.primaryUser = "xiaziyuan";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."mba" = nix-darwin.lib.darwinSystem {
      modules = [ 
	configuration 
        nix-homebrew.darwinModules.nix-homebrew
	{
          nix-homebrew = {
	    enable = true;
            # Apple silicon Only
	    enableRosetta = true;
            # User owning the Homebrew prefix
	    user = "xiaziyuan";

	  };
	}
	#nixvim.nixDarwinModules.nixvim
	#{
	  #programs.nixvim = {
	    #enable = true;
	  #};
	#}
      ];
    };
    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."mba".pkgs;
  };
}
