{ config, lib, pkgs, system, inputs, ... }:

{
  imports = [
    ../base
  ];

  # Override: Ubuntu-specific oh-my-zsh plugins
  modules.shell.zsh.ohmyzsh.plugins = [ "git" "ubuntu" "docker" ];

  # Extra shell config
  modules.shell.zsh.extraConfig = lib.mkAfter ''
    # Auto-start tmux (an toàn)
    if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -n "$PS1" ]; then
      if tmux has-session 2>/dev/null; then
        tmux attach-session
      else
        tmux new-session
      fi
    fi
    
    neofetch
    export PATH="''${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
    
    # Container runtime detection (Colima)
    if [[ -S $HOME/.colima/default/docker.sock ]]; then
      export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
    elif [[ -S /var/run/docker.sock ]]; then
      export DOCKER_HOST='unix:///var/run/docker.sock'
    fi

    # Rustup
    source "$HOME/.cargo/env"

    # Bun
    export PATH="/home/rnd/.bun/bin:$PATH"
    
    # Greeting
    echo "Welcome to your Ubuntu development environment, RND!"
    echo "Remember to stay hydrated and take breaks while coding!"
  '';

  # Git Identity
  programs.git = {
    userName = "architectureman";
    userEmail = "vnknowledge2014@gmail.com";
  };

  # RND specific packages
  home.packages = with pkgs; [
    # Fonts
    nerd-fonts.fira-code
    
    # CLI utilities
    atuin
    yazi
    lazygit
    btop
    eza
    bat
    fzf
    ripgrep
    fd
    jq
    gh
    
    # Container tools
    colima
    docker-client
    docker-compose
    nerdctl
    incus
    docker-credential-helpers
    lazydocker
    
    # Kubernetes
    kubectl
    kubernetes-helm
    k9s
    
    # Others
    neofetch
  ];

  # Ubuntu-specific env vars
  home.sessionVariables = {
    PATH = lib.mkForce "$HOME/.cargo/bin:$HOME/.local/bin:/snap/bin:$PATH";
  };
}
