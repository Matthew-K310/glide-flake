{
  description = "An extensible and keyboard-focused web browser";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs =
    inputs:
    let
      inherit (inputs) nixpkgs self;
      inherit (nixpkgs) lib;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs platforms;
      versionData = builtins.fromJSON (builtins.readFile ./glide-versions.json);
      version = versionData.version;
      linuxHashes = versionData.linuxHashes;
      mkGlideLinux =
        pkgs:
        let
          system = pkgs.stdenv.hostPlatform.system;
        in
          pkgs.stdenv.mkDerivation {
            pname = "glide";
            inherit version;
            src = pkgs.fetchurl {
              url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-${
                if system == "aarch64-linux" then "arm64" else "x86_64"
              }.tar.xz";
              sha256 = linuxHashes.${system};
            };
            dontAutoPatchelf = true;
            dontWrapQtApps = true;
            nativeBuildInputs = with pkgs; [
              makeWrapper
              patchelf
            ];
            buildInputs = with pkgs; [
              glib
              gdk-pixbuf
              gtk3
              nspr
              nss
              dbus
              dbus-glib
              atk
              at-spi2-atk
              cups
              expat
              libxcb
              libxkbcommon
              at-spi2-core
              libx11
              libxcomposite
              libxdamage
              libxext
              libxfixes
              libxrandr
              mesa
              cairo
              pango
              systemd
              alsa-lib
              libdrm
              ffmpeg
              libvpx
              libevent
              libffi
              fontconfig
              freetype
              zlib
              icu
              libjpeg
              libpng
              libwebp
              qt6.qtbase
              gsettings-desktop-schemas
              glib-networking
              hicolor-icon-theme
              adwaita-icon-theme
              libXcursor
              libXi
              libXtst
              libXt
              libXScrnSaver
            ];
            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin $out/opt/glide
              cp -r ./* $out/opt/glide/

              for bin in glide glide-bin crashhelper glxtest pingsender; do
                if [ -f "$out/opt/glide/$bin" ]; then
                  patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" \
                    $out/opt/glide/$bin
                fi
              done

              makeWrapper $out/opt/glide/glide $out/bin/glide \
                --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath (with pkgs; [
                  glib
                  gdk-pixbuf
                  gtk3
                  nspr
                  nss
                  dbus
                  dbus-glib
                  atk
                  at-spi2-atk
                  cups
                  expat
                  libxcb
                  libxkbcommon
                  at-spi2-core
                  libx11
                  libxcomposite
                  libxdamage
                  libxext
                  libxfixes
                  libxrandr
                  mesa
                  cairo
                  pango
                  systemd
                  alsa-lib
                  libdrm
                  ffmpeg
                  libvpx
                  libevent
                  libffi
                  fontconfig
                  freetype
                  zlib
                  icu
                  libjpeg
                  libpng
                  libwebp
                  qt6.qtbase
                  stdenv.cc.cc.lib
                  libGL
                  libva
                  pipewire
                  libpulseaudio
                  gsettings-desktop-schemas
                  glib-networking
                  libXcursor
                  libXi
                  libXtst
                  libXt
                  libXScrnSaver
                ])}" \
                --prefix LD_LIBRARY_PATH : "$out/opt/glide" \
                --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
                --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share" \
                --prefix XDG_DATA_DIRS : "${pkgs.hicolor-icon-theme}/share" \
                --prefix XDG_DATA_DIRS : "${pkgs.adwaita-icon-theme}/share" \
                --set GDK_PIXBUF_MODULE_FILE "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
                --set GTK_PATH "${pkgs.gtk3}/lib/gtk-3.0"

              mkdir -p $out/share/applications
              cat > $out/share/applications/glide.desktop << EOF
              [Desktop Entry]
              Name=Glide
              Exec=$out/bin/glide %u
              Icon=glide
              Type=Application
              Categories=Network;WebBrowser;
              MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;x-scheme-handler/http;x-scheme-handler/https;
              EOF

              mkdir -p $out/share/pixmaps
              cp $out/opt/glide/browser/chrome/icons/default/default128.png $out/share/pixmaps/glide.png

              runHook postInstall
            '';
            meta = {
              inherit platforms;
              description = "An extensible and keyboard-focused web browser built on Firefox";
              homepage = "https://github.com/glide-browser/glide";
              license = lib.licenses.mpl20;
              mainProgram = "glide";
            };
          };
    in
      {
        packages = forAllSystems (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
            {
              glide = mkGlideLinux pkgs;
              default = self.packages.${system}.glide;
            }
        );
      };
}
