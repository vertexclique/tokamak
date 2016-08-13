child_process = require 'child_process'
pjson = require '../package.json'

_ = require 'underscore-plus'
fs = require 'fs'
path = require 'path'
os = require 'os'
toml = require 'toml'
toml.dumper = require 'json2toml'
packageDeps = require 'atom-package-deps'
{runInTerminal} = require './terminal'

module.exports =
class Utils
  @runCommandOut: (executable, args) ->
    try
      result = child_process.spawnSync(executable, args);
      return {
        status: result.status,
        stdoutData: result.stdout.toString(),
        stderrData: result.stderr.toString()
      }
    catch e
      return e;

  @getVersion: ->
    pjson.version

  @installDependencies: ->
    tokamakConfig = @parseTokamakConfig()
    packageList = _.map(atom.packages.getLoadedPackages(), (pkg) -> return pkg.name)
    tbInstalled = _.difference(pjson["package-deps"], packageList);
    if tbInstalled.length != 0
      packageDeps.install()
        .then ->
          if tokamakConfig?.options?.general_warnings
            atom.notifications.addSuccess("Tokamak: Dependencies are installed!");

  @detectBinaries: ->
    tokamakConfig = @parseTokamakConfig()
    tool_found = false
    for pkg in ["cargo", "racer", "multirust", "rustc", "rustup"]
      data = @findBinary([pkg])

      if data.status == 0 && data.stdoutData.length > 0
        switch pkg
          when "cargo"
            atom.config.set("tokamak.cargoBinPath", data.stdoutData)
            atom.config.set("linter-rust.cargoPath", data.stdoutData)
          when "racer"
            atom.config.set("tokamak.racerBinPath", data.stdoutData)
            atom.config.set("racer.racerBinPath", data.stdoutData)
          when "multirust"
            atom.config.set("tokamak.toolBinPath", data.stdoutData)
            atom.config.set("tokamak.toolChain", "multirust")
            tool_found = true
          when "rustup"
            atom.config.set("tokamak.toolBinPath", data.stdoutData)
            atom.config.set("tokamak.toolChain", "rustup")
            tool_found = true
          when "rustc"
            atom.config.set("tokamak.rustcBinPath", data.stdoutData)
            atom.config.set("linter-rust.rustcPath", data.stdoutData)
      else
        if (pkg == "multirust" || pkg == "rustup") && tool_found == true
          console.log "Ignoring missing tool because alternative found"
        else
          if tokamakConfig?.options?.general_warnings
            atom.notifications.addError("Tokamak: #{pkg} is not installed or not found in PATH",
            {
              detail: "If you have a #{pkg} executable, set it in токамак settings.
              If you are sure that PATH environment variable is set and includes
              #{pkg}, please start Atom from command line.
              ERROR: #{data.stderrData}"
              dismissable: true
            })

  @findBinary: (pkg) ->
    if process.platform is "win32"
      return @runCommandOut("where", [pkg]);
    else
      data = @runCommandOut("which", [pkg]);

      if data.status == 0 && data.stdoutData.length >= 0
        data.stdoutData = data.stdoutData.replace(/^\s+|\s+$/g, "")

      return data

  @watchConfig: ->
    atom.config.onDidChange "tokamak.autocompleteBlacklist", ({newValue, oldValue}) ->
      atom.config.set("racer.autocompleteBlacklist", newValue)
    atom.config.onDidChange "tokamak.cargoBinPath", ({newValue, oldValue}) ->
      atom.config.set("linter-rust.cargoPath", newValue)
    atom.config.onDidChange "tokamak.cargoHomePath", ({newValue, oldValue}) ->
      atom.config.set("racer.cargoHome", newValue)
    atom.config.onDidChange "tokamak.racerBinPath", ({newValue, oldValue}) ->
      atom.config.set("racer.racerBinPath", newValue)
    atom.config.onDidChange "tokamak.rustSrcPath", ({newValue, oldValue}) ->
      atom.config.set("racer.rustSrcPath", newValue)
    atom.config.onDidChange "tokamak.rustcBinPath", ({newValue, oldValue}) ->
      atom.config.set("linter-rust.rustcPath", newValue)
    atom.config.onDidChange "tokamak.show", ({newValue, oldValue}) ->
      atom.config.set('racer.show', newValue)

  @openTerminal: (cmd) ->
    status = runInTerminal([cmd]);
    if -1 == status
      atom.notifications.addError('Tokamak: Terminal service is not registered.', {
        detail: 'Make sure that "tokamak-terminal" package is installed.',
        dismissable: true,
      });
    status

  @getHomePath: ->
    os.homedir() ? "/"

  @isTokamakProject: ->
    dir = _.find(atom.project.getPaths(), (x) -> x?)
    proj_path = if dir? then dir.toString() else @getHomePath()
    config_file = path.join(proj_path, 'tokamak.toml')
    console.log(config_file)
    fs.existsSync(config_file)

  @parseTokamakConfig: ->
    if @isTokamakProject()
      config_file = path.join(atom.project.rootDirectories[0].path, 'tokamak.toml')
      config_contents = fs.readFileSync(config_file, 'utf8');
      config = toml.parse(config_contents);
      config

  @createDefaultTokamakConfig: ->
    proj_path = atom.project.rootDirectories[0].path
    @createDefaultTokamakConfig(proj_path)

  @createDefaultTokamakConfig: (proj_path) ->
    default_config =
      helper:
        path: ""
      project:
        auto_format_timing: 5
      options:
        general_warnings: false
        save_buffers_before_run: false

    tokamak_config_path = path.join(proj_path, 'tokamak.toml')
    dumped_toml = toml.dumper(default_config)
    fs.writeFileSync(tokamak_config_path, dumped_toml, 'utf8');

  @savePaneItems: ->
    atom.workspace.getPaneItems().map (item) -> if item.save? then item.save()
