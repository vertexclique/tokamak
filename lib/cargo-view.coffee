{BufferedProcess} = require 'atom'
path = require 'path'
fs = require 'fs-plus'
_ = require 'underscore-plus'
{CronJob} = require 'cron';
{spawnSync} = require 'child_process',
{$, TextEditorView, View} = require 'atom-space-pen-views'

Utils = require './utils'

module.exports =
class CargoView extends View
  previouslyFocusedElement: null
  mode: null
  autoFormatJob: null
  projectPath: null

  constructor: (serializedState) ->
    super

  @content: ->
    @div class: 'tokamak-cargo', =>
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'error', outlet: 'error'
      @div class: 'message', outlet: 'message'

  initialize: ->
    @tokamakConfig = Utils.parseTokamakConfig()
    @commandSubscription = atom.commands.add 'atom-workspace',
      'tokamak:create-cargo-library': => @attach('lib')
      'tokamak:create-cargo-binary': => @attach('bin')
      'tokamak:build': =>
        if @tokamakConfig?.options?.save_buffers_before_run
          Utils.savePaneItems()
        @attachCargo('build')
      'tokamak:clean': => @attachCargo('clean')
      'tokamak:rebuild': =>
        if @tokamakConfig?.options?.save_buffers_before_run
          Utils.savePaneItems()
        @attachCargo('rebuild')
      'tokamak:format-code': =>
        @attachCargo('fmt')

    @miniEditor.on 'blur', => @close()
    atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @close()

  destroy: ->
    @panel?.destroy()
    @commandSubscription.dispose()

  attach: (@mode) ->
    @panel ?= atom.workspace.addModalPanel(item: this, visible: false)
    @previouslyFocusedElement = $(document.activeElement)
    @panel.show()
    @message.text("Enter cargo #{mode} project path")
    editor = @miniEditor.getModel()
    editor.setText(process.env.HOME)
    @miniEditor.focus()

  attachCargo: (@cmd) ->
    @cargoCmdRunner(@cmd, @cargoCmdExitCallback)

  cargoCmdExitCallback: (@cmd, code, stdoutData, stderrData) =>
    if code != 0
      atom.notifications.addError("Tokamak: Cargo #{@cmd} failed!", {
        detail: "#{stderrData}"
      })
    else
      atom.notifications.addSuccess("Tokamak: Cargo #{@cmd} successful!")

  runCargo: (@cmd, cargoPath, command, callback) ->
    [responseSuccess, responseError] = ["", ""]
    @runCommandOut(
      cargoPath
      [command]
      stderr = (data) -> responseError += data.toString()
      stdout = (data) -> responseSuccess += data.toString()
      exit = (code) => callback(@cmd, code, responseSuccess, responseError)
      )

  cargoCmdRunner: (@cmd, callback) ->
    cargoPath = atom.config.get("tokamak.cargoBinPath")
    @projectPath ?= _.first(atom.project.getPaths())
    fs.access(@projectPath, fs.F_OK, (err) =>
      if !err?
        process.chdir(@projectPath)
        switch @cmd
          when "build"
            @runCargo(@cmd, cargoPath, "build", callback)
          when "clean"
            @runCargo(@cmd, cargoPath, "clean", callback)
          when "rebuild"
            @runCargo(@cmd, cargoPath, "clean", callback)
            @runCargo(@cmd, cargoPath, "build", callback)
          when "fmt"
            @runCargo(@cmd, cargoPath, "fmt", callback)
          else null
      else
        atom.notifications.addError("Tokamak: Cargo #{@cmd} failed!")
    )

  serialize: ->

  getPackagePath: ->
    packagePath = fs.normalize(@miniEditor.getText().trim())
    packageName = _.dasherize(path.basename(packagePath))
    path.join(path.dirname(packagePath), packageName)

  validPackagePath: ->
    if fs.existsSync(@getPackagePath())
      @error.text("Path already exists at '#{@getPackagePath()}'")
      @error.show()
      false
    else
      true

  initPackage: (packagePath, callback) ->
    command = ['new', packagePath.toString()]
    if @mode == 'bin' then command.push '--bin' else null
    @runCommand(atom.config.get("tokamak.cargoBinPath"), command, callback)

  createPackage: (callback) ->
    packagePath = @getPackagePath()
    @initPackage(packagePath, callback)

  autoFormatting: ->
    cargoPath = atom.config.get("tokamak.cargoBinPath")
    if @tokamakConfig?.project?.auto_format_timing?
      if !@autoFormatJob?
        timing = @tokamakConfig?.project?.auto_format_timing
        @autoFormatJob = new CronJob(
          cronTime: "#{timing} * * * * *"
          onTick: =>
            console.log("RustFmt running...")
            spawnSync(cargoPath, ["fmt"])
            console.log("RustFmt finished!")
          start: false,
        )
        @autoFormatJob.start()
        if @tokamakConfig?.options?.general_warnings
          atom.notifications.addInfo("Tokamak: Auto Format started.")
      else
        console.log "Auto Format stopped."
        if @tokamakConfig?.options?.general_warnings
          atom.notifications.addInfo("Tokamak: Auto Format stopped.",
          {
            dismissable: true
          })
        @autoFormatJob.stop()
        @autoFormatJob = null

  confirm: ->
    if @validPackagePath()
      @createPackage =>
        packagePath = @getPackagePath()
        Utils.createDefaultTokamakConfig(packagePath)
        atom.open(pathsToOpen: [packagePath])
        @close()

  close: ->
    return unless @panel.isVisible()
    @panel.hide()
    @previouslyFocusedElement?.focus()

  runCommand: (command, args, exit) ->
    new BufferedProcess({command, args, exit})

  runCommandOut: (command, args, stderr, stdout, exit) ->
    new BufferedProcess({command, args, stderr, stdout, exit})
