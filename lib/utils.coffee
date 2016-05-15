child_process = require 'child_process'
pjson = require '../package.json'

_ = require 'underscore-plus'
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
    packageList = _.map(atom.packages.getLoadedPackages(), (pkg) -> return pkg.name)
    tbInstalled = _.difference(pjson["package-deps"], packageList);
    if tbInstalled.length != 0
      packageDeps.install()
        .then ->
          atom.notifications.addSuccess("Tokamak: Dependencies are installed!");

  @detectBinaries: ->
    tool_found = false
    for pkg in ["cargo", "racer", "multirust", "rustc","rustup"]
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
        if (pkg == "multirust" || pkg ="rustup") && tool_found == true
          console.log("Ignoring missing tool because alternative found")
        else
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

  @savePaneItems: ->
    atom.workspace.getPaneItems().map (item) -> if item.save? then item.save()
