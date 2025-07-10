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

  git-hooks = {
    hooks = {
      # Nix files
      nixfmt-rfc-style.enable = true;

      # Commit messages
      commitizen.enable = true;

      # Markdown files
      markdownlint.enable = true;
      mdformat.enable = true;

      # Composer json file
      composer-validate = {
        enable = true;
        package = pkgs.php84Packages.composer;
        files = "composer\.*";
        entry = "${pkgs.php84Packages.composer}/bin/composer validate --no-check-publish";
        stages = [
          "pre-commit"
          "pre-push"
        ];
      };

      composer-audit = {
        enable = true;
        after = [ "composer-validate" ];
        package = pkgs.php84Packages.composer;
        files = "composer\.*";
        entry = "${pkgs.php84Packages.composer}/bin/composer audit";
        stages = [
          "pre-commit"
          "pre-push"
        ];
      };
    };
  };

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  enterShell = ''
    hello
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

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
