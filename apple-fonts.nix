{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "apple-fonts";
  version = "1";

  pro = pkgs.fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    sha256 = "sha256-g/eQoYqTzZwrXvQYnGzDFBEpKAPC8wHlUw3NlrBabHw=";
  };

  compact = pkgs.fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
    sha256 = "sha256-0mUcd7H7SxZN3J1I+T4SQrCsJjHL0GuDCjjZRi9KWBM=";
  };

  mono = pkgs.fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
    sha256 = "sha256-q69tYs1bF64YN6tAo1OGczo/YDz2QahM9Zsdf7TKrDk=";
  };

  ny = pkgs.fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
    sha256 = "sha256-HuAgyTh+Z1K+aIvkj5VvL6QqfmpMj6oLGGXziAM5C+A=";
  };

  nativeBuildInputs = with pkgs; [ p7zip ];

  sourceRoot = ".";

  dontUnpack = true;

  installPhase = ''
    7z x ${pro}
    cd SFProFonts 
    7z x 'SF Pro Fonts.pkg'
    7z x 'Payload~'
    mkdir -p $out/fontfiles
    mv Library/Fonts/* $out/fontfiles
    cd ..

    7z x ${mono}
    cd SFMonoFonts
    7z x 'SF Mono Fonts.pkg'
    7z x 'Payload~'
    mv Library/Fonts/* $out/fontfiles
    cd ..

    7z x ${compact}
    cd SFCompactFonts
    7z x 'SF Compact Fonts.pkg'
    7z x 'Payload~'
    mv Library/Fonts/* $out/fontfiles
    cd ..

    7z x ${ny}
    cd NYFonts
    7z x 'NY Fonts.pkg'
    7z x 'Payload~'
    mv Library/Fonts/* $out/fontfiles

    mkdir -p $out/usr/share/fonts/OTF $out/usr/share/fonts/TTF
    mv $out/fontfiles/*.otf $out/usr/share/fonts/OTF
    mv $out/fontfiles/*.ttf $out/usr/share/fonts/TTF
    rm -rf $out/fontfiles
  '';

  meta = {
    description = "Apple San Francisco, New York fonts";
    homepage = "https://developer.apple.com/fonts/";
    license = pkgs.lib.licenses.unfree;
  };
}
