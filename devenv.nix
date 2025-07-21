{
  pkgs,
  config,
  inputs,
  ...
}:
{
  name = "Symfony skeleton";

  imports = [
    "${inputs.devenv-recipes}/devenv-scripts.nix"
    "${inputs.devenv-recipes}/git.nix"
    "${inputs.devenv-recipes}/devcontainer.nix"
    "${inputs.devenv-recipes}/markdown.nix"
    "${inputs.devenv-recipes}/nix.nix"
    "${inputs.devenv-recipes}/gitleaks.nix"
    "${inputs.devenv-recipes}/dotenv.nix"
    "${inputs.devenv-recipes}/gnu-parallel.nix"
  ];

  starship.enable = true;

  # https://devenv.sh/basics/
  env.GREET = "symfony-skeleton";

  # https://devenv.sh/packages/
  packages = with pkgs; [

    lnav # Log files viewer
    lazyjournal # TUI for journalctl, file system logs, as well Docker and Podman containers.

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

  # https://devenv.sh/processes/
  # processes.symfony-server.exec = "symfony server:start";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts = {
    hello.exec = ''
      echo hello from $GREET
    '';
  };

  enterShell = ''
    hello
    git --version

    export PATH="${config.env.DEVENV_ROOT}/vendor/bin:${config.env.DEVENV_ROOT}/bin:$PATH"
  '';

  # https://devenv.sh/tasks/
  tasks = {
    "ci:format:composer-normalize".exec =
      "${pkgs.fd}/bin/fd 'composer\.json$' '${config.env.DEVENV_ROOT}' --exec ${config.languages.php.packages.composer}/bin/composer bin composer-normalize normalize {} \;";
    "ci:format:php-cs-fixer".exec =
      "${config.languages.php.package}/bin/php 'vendor/bin/php-cs-fixer' 'fix'";
    "ci:format:rector".exec = "${config.languages.php.package}/bin/php 'vendor/bin/rector' 'process'";
    # "devenv:enterShell".after = [ "myproj:setup" ];
  };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    # Commit messages
    commitizen.enable = true;

    # Shell scripts
    shellcheck.enable = true;
    shfmt.enable = true;

    # Composer json file
    composer-normalize = {
      enable = true;
      name = "composer normalize";
      before = [ "composer-validate" ];
      package = config.languages.php.packages.composer;
      extraPackages = [
        pkgs.parallel
        pkgs.git
      ];
      files = "composer.json";
      entry = "${pkgs.parallel}/bin/parallel ${config.languages.php.packages.composer}/bin/composer bin composer-normalize normalize --dry-run \"${config.env.DEVENV_ROOT}/\"{} ::: ";
    };

    composer-validate = {
      enable = true;
      name = "composer validate";
      package = config.languages.php.packages.composer;
      extraPackages = [ pkgs.parallel ];
      files = "composer\.(json|lock)$";
      entry = "${pkgs.parallel}/bin/parallel ${config.languages.php.packages.composer}/bin/composer validate --no-check-publish {} ::: ";
      stages = [
        "pre-commit"
        "pre-push"
      ];
    };

    composer-audit = {
      enable = true;
      name = "composer audit";
      after = [ "composer-validate" ];
      package = config.languages.php.packages.composer;
      extraPackages = [
        pkgs.parallel
        pkgs.coreutils
      ];
      files = "composer\.(json|lock)$";
      verbose = true;
      entry = "${pkgs.parallel}/bin/parallel ${config.languages.php.packages.composer}/bin/composer --working-dir=\"$(${pkgs.coreutils}/bin/dirname {})\" audit ::: ";
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
      entry = "${config.languages.php.package}/bin/php vendor/bin/phpstan 'analyse'";
      args = [ "--memory-limit=256m" ];
    };

    rector = {
      enable = true;
      name = "Rector";
      inherit (config.languages.php) package;
      files = ".*\.php$";
      entry = "${config.languages.php.package}/bin/php vendor/bin/rector 'process'";
      args = [ "--dry-run" ];
    };

    php-cs-fixer = {
      enable = true;
      name = "PHP Coding Standards Fixer";
      inherit (config.languages.php) package;
      files = ".*\.php$";
      entry = "${config.languages.php.package}/bin/php vendor/bin/php-cs-fixer 'fix'";
      args = [
        "--config"
        "${config.env.DEVENV_ROOT}/.php-cs-fixer.php"
        "--dry-run"
      ];
    };

    phpcs = {
      enable = true;
      name = "PHP CodeSniffer";
      inherit (config.languages.php) package;
      files = ".*\.php$";
      entry = "${config.languages.php.package}/bin/php vendor/bin/phpcs";
      args = [
        "-s"
      ];
    };
  };

  # See full reference at https://devenv.sh/reference/options/
}
