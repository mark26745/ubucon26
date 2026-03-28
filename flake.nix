{
  description = "A custom ROS 2 project powered by AeroNix";

  inputs = {
    aeronix.url = "github:mark26745/aeronix";
    nixpkgs.follows = "aeronix/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      aeronix,
    }:
    aeronix.inputs.nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        rosDistro = "humble";
        overlays = [ aeronix.overlays.default ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

        droneEnv = aeronix.lib.mkDroneEnv {
          inherit pkgs;
          distro = rosDistro;
        };

        rosPkgs = pkgs.rosPackages.${rosDistro};

        basePackages = with pkgs; [
          gnugrep
          gnused
          gawk
          findutils
          procps
          libxml2
          libxslt
          libzip
          jsoncpp
          tinyxml-2
          protobuf
          libuuid
          cppzmq
          zeromq
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          cmake
          gnumake
          ninja
          binutils
          gcc
          git
          pkg-config
          uv
          colcon
          hivemind
          just
          nix-ld
          ffmpeg
          qt5.qtquickcontrols2
          qt5.qtgraphicaleffects
          qt5.qtwayland
          qt5.qtbase
          qgroundcontrol
          droneEnv
        ];

        # 2. Create a symlinked environment for the container PATH
        container-env = pkgs.buildEnv {
          name = "aeronix-container-env";
          paths =
            with pkgs;
            [
              bashInteractive
              cacert
              coreutils
              python312
            ]
            ++ basePackages;

          # 2. This is the magic fix for the "conflicting subpath" error
          ignoreCollisions = true;
        };

      in
      {
        packages = {
          demo-container = pkgs.dockerTools.buildLayeredImage {
            name = "aeronix-drone-workspace";
            tag = "latest";
            maxLayers = 50;
            fakeRootCommands = ''
              # Create the standard Linux hierarchy
              mkdir -p tmp
              chmod 1777 tmp

              mkdir -p app
              chmod 755 app

              # This ensures /usr/bin exists so usrBinEnv can link into it
              mkdir -p usr/bin
            '';
            contents = [
              container-env
              pkgs.dockerTools.usrBinEnv
            ];

            config = {
              Cmd = [ "${pkgs.bashInteractive}/bin/bash" ];
              WorkingDir = "/app";
              Env = [
                "PATH=${container-env}/bin:/usr/local/bin:/usr/bin:/bin"
                "PYTHONPATH=${container-env}/${pkgs.python3.sitePackages}"
                "LD_LIBRARY_PATH=${container-env}/lib"
                "AMENT_PREFIX_PATH=${container-env}"
                "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                "ROS_DISTRO=${rosDistro}"
                "ROS_LOG_DIR=/app/.ros/log"
                "QT_X11_NO_MITSHM=1"
                "QT_QPA_PLATFORM=xcb"
                "UV_PYTHON=${container-env}/bin/python3.12"
                "UV_PYTHON_PREFERENCE=only-system"
                "UV_PROJECT_ENVIRONMENT=.venv_container"
                "UV_PYTHON_INSTALL_DIR=/app/.uv_python"
              ];
            };
          };
        };

        devShells.default = pkgs.mkShell {
          name = "aeronix-dev-shell";
          packages = basePackages;

          shellHook = ''
            export QT_PLUGIN_PATH="${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtPluginPrefix}"
            export QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.qt5.qtbase.bin}/lib/qt-5.15/plugins"
            export QT_QPA_PLATFORM="xcb"
            echo "🚀 Welcome to your AeroNix-powered workspace!"
          '';
        };
      }
    );
}
