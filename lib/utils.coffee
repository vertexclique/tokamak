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
    for pkg in ["cargo", "racer", "multirust", "rustc"]
      console.log(pkg)
      data = @runCommandOut("which", [pkg])
      console.log(data)
      if data.status == 0 && data.stdoutData.length >= 0
        switch pkg
          when "cargo"
            atom.config.set("tokamak.cargoBinPath", data.stdoutData.replace(/^\s+|\s+$/g, ""))
            atom.config.set("linter-rust.cargoPath", data.stdoutData.replace(/^\s+|\s+$/g, ""))
          when "racer"
            atom.config.set("tokamak.racerBinPath", data.stdoutData.replace(/^\s+|\s+$/g, ""))
            atom.config.set("racer.racerBinPath", data.stdoutData.replace(/^\s+|\s+$/g, ""))
          when "multirust"
            atom.config.set("tokamak.multirustBinPath", data.stdoutData.replace(/^\s+|\s+$/g, ""))
          when "rustc"
            atom.config.set("tokamak.rustcBinPath", data.stdoutData.replace(/^\s+|\s+$/g, ""))
            atom.config.set("linter-rust.rustcPath", data.stdoutData.replace(/^\s+|\s+$/g, ""))
      else
        atom.notifications.addError("Tokamak: #{pkg} is not installed or not found in PATH",
        {
          detail: "If you have a #{pkg} executable, set it in токамак settings.
          If you are sure that PATH environment variable is set and includes
          #{pkg}, please start Atom from command line.
          ERROR: #{data.stderrData}"
          dismissable: true
        })

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
