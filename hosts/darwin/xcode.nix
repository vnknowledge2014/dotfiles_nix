{ config, lib, pkgs, ... }:

{
  # Auto-accept Xcode license
  system.activationScripts.preActivation.text = lib.mkBefore ''
    echo "Accepting Xcode license..."
    # Use a direct path to xcodebuild and run with appropriate privileges
    if [ -f /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]; then
      /usr/bin/sudo /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -license accept 2>/dev/null || true
    elif [ -f /usr/bin/xcodebuild ]; then
      /usr/bin/sudo /usr/bin/xcodebuild -license accept 2>/dev/null || true
    else
      echo "xcodebuild not found, skipping license acceptance"
    fi
  '';
}