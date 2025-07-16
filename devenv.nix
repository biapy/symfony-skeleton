{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  # https://devenv.sh/basics/
  env.GREET = "symfony-skeleton";

  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    lazygit # Git terminal UI

    lnav # Log files viewer
    lazyjournal # TUI for journalctl, file system logs, as well Docker and Podman containers.
    glow # TUI Markdown file viewer

    silver-searcher # ag, ack alternative
    f2 # Batch file renamer
    dust # du alternative
    dogdns # dig alternative
    gping # ping with data visualization

    jq # JSON processor
    yq-go # YAML processor

    ## Docker related
    lazydocker # Docker TUI
    ctop # Docker TUI, showing running container resources usage

    parallel # Run commands in parallel

    symfony-cli
  ];

  # https://devenv.sh/languages/
  # https://devenv.sh/reference/options/#languagesansibleenable
  languages = {
    php = {
      enable = true;
      version = "8.4";
    };
  };

  dotenv.enable = true;

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    # Nix files
    nil.enable = true;
    nixfmt-rfc-style.enable = true;
    statix.enable = true;

    # Commit messages
    commitizen.enable = true;

    # EditorConfig
    eclint.enable = true;
    editorconfig-checker.enable = true;

    # Markdown files
    markdownlint.enable = true;
    mdformat.enable = true;

    # Shell scripts
    shellcheck.enable = true;
    shfmt.enable = true;

    # Composer json file
    composer-normalize = {
      enable = true;
      name = "composer normalize";
      before = [ "composer-validate" ];
      package = pkgs.phpPackages.composer;
      extraPackages = [
        pkgs.parallel
        pkgs.git
      ];
      files = "composer.json";
      entry = "${pkgs.parallel}/bin/parallel ${pkgs.phpPackages.composer}/bin/composer bin composer-normalize normalize --dry-run \"$(${pkgs.git}/bin/git rev-parse --show-toplevel)/\"{} ::: ";
    };

    composer-validate = {
      enable = true;
      name = "composer validate";
      package = pkgs.phpPackages.composer;
      extraPackages = [ pkgs.parallel ];
      files = "composer\.(json|lock)$";
      entry = "${pkgs.parallel}/bin/parallel ${pkgs.phpPackages.composer}/bin/composer validate --no-check-publish {} ::: ";
      stages = [
        "pre-commit"
        "pre-push"
      ];
    };

    composer-audit = {
      enable = true;
      name = "composer audit";
      after = [ "composer-validate" ];
      package = pkgs.phpPackages.composer;
      extraPackages = [
        pkgs.parallel
        pkgs.coreutils
      ];
      files = "composer\.(json|lock)$";
      verbose = true;
      entry = "${pkgs.parallel}/bin/parallel ${pkgs.phpPackages.composer}/bin/composer --working-dir=\"$(${pkgs.coreutils}/bin/dirname {})\" audit ::: ";
      stages = [
        "pre-commit"
        "pre-push"
      ];
    };

    phpstan = {
      enable = true;
      name = "PHPStan";
      inherit (config.languages.php) package;
      pass_filenames = false;
      entry = "${config.languages.php.package}/bin/php vendor/bin/phpstan analyse";
      args = [ "--memory-limit=256m" ];
    };

    php-cs-fixer = {
      enable = true;
      inherit (config.languages.php) package;
      entry = "${config.languages.php.package}/bin/php vendor/bin/php-cs-fixer fix";
      args = [
        "--config"
        "${config.env.DEVENV_ROOT}/.php-cs-fixer.php"
        "--dry-run"
      ];
    };

  };

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts = {
    hello.exec = ''
      echo hello from $GREET
    '';
    parallel-will-cite.exec = ''
      yes 'will cite' | parallel --citation 2&>'/dev/null'
    '';
  };

  enterShell = ''
    hello
    parallel-will-cite
    git --version
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # See full reference at https://devenv.sh/reference/options/
}
