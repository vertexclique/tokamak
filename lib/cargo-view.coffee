{BufferedProcess} = require 'atom'
path = require 'path'
fs = require 'fs-plus'
_ = require 'underscore-plus'
{$, TextEditorView, View} = require 'atom-space-pen-views'

module.exports =
class CargoView extends View
  previouslyFocusedElement: null
  mode: null
  projectPath: null

  constructor: (serializedState) ->
    super

  @content: ->
    @div class: 'tokamak-cargo', =>
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'error', outlet: 'error'
      @div class: 'message', outlet: 'message'

  initialize: ->
    @commandSubscription = atom.commands.add 'atom-workspace',
      'tokamak:create-cargo-lib': => @attach('lib')
      'tokamak:create-cargo-binary': => @attach('bin')
      'tokamak:build': => @attachCargo('build')
      'tokamak:clean': => @attachCargo('clean')
      'tokamak:rebuild': => @attachCargo('rebuild')
      'tokamak:run': => @attachCargo('run')

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
    console.log code
    if code != 0
      atom.notifications.addError("Tokamak: Cargo #{@cmd} failed!", {
        detail: "#{stderrData}"
      })
    else
      atom.notifications.addSuccess("Tokamak: Cargo #{@cmd} successful!", {
        detail: "#{stdoutData}"
      })

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
    process.chdir(@projectPath)
    switch @cmd
      when "build"
        @runCargo(@cmd, cargoPath, "build", callback)
      when "clean"
        @runCargo(@cmd, cargoPath, "clean", callback)
      when "rebuild"
        @runCargo(@cmd, cargoPath, "clean", callback)
        @runCargo(@cmd, cargoPath, "build", callback)
      when "run"
        @runCargo(@cmd, cargoPath, "run", callback)
      else null

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

  confirm: ->
    if @validPackagePath()
      @createPackage =>
        packagePath = @getPackagePath()
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
