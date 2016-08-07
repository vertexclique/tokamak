# Views
TokamakView = require './tokamak-view'
CargoView = require './cargo-view'
ToolchainView = require './toolchain-view'
CreateProjectView = require './create-project-view'
AboutView = require './about-view'

# Helpers
Utils = require './utils'

{consumeRunInTerminal} = require './terminal'
{BufferedProcess, CompositeDisposable} = require 'atom'

module.exports = Tokamak =
  # Config schema
  consumeRunInTerminal: consumeRunInTerminal
  config:
    binaryDetection:
      title: 'Detect binaries on startup'
      type: 'boolean'
      description: 'Set toolchain executables if it is found under PATH.'
      default: true
      order: 1
    rustcBinPath:
      title: 'Path to the Rust compiler'
      type: 'string'
      default: '/usr/local/bin/rustc'
      order: 2
    cargoBinPath:
      title: 'Path to the Cargo package manager'
      type: 'string'
      default: '/usr/local/bin/cargo'
      order: 3
    toolBinPath:
      title: 'Path to the RustUp or Multirust rust installation manager'
      type: 'string'
      default: '$HOME/.cargo/bin/rustup'
      order: 4
    toolChain:
      title: 'Select RustUp or Multirust for toolchain management'
      type: 'string'
      default: 'rustup'
      order: 5
    racerBinPath:
      title: 'Path to the Racer executable'
      type: 'string'
      default: '/usr/local/bin/racer'
      order: 6
    rustSrcPath:
      title: 'Path to the Rust source code directory'
      type: 'string'
      default: '/usr/local/src/rust/src/'
      order: 7
    cargoHomePath:
      title: 'Cargo home directory (optional)'
      type: 'string'
      description: 'Needed when providing completions for Cargo crates when Cargo is installed in a non-standard location.'
      default: ''
      order: 8
    autocompleteBlacklist:
      title: 'Autocomplete Scope Blacklist'
      description: 'Autocomplete suggestions will not be shown when the cursor is inside the following comma-delimited scope(s).'
      type: 'string'
      default: '.source.go .comment'
      order: 9
    show:
      title: 'Show position for editor with definition'
      description: 'Choose one: Right, or New. If your view is vertically split, choosing Right will open the definition in the rightmost pane.'
      type: 'string'
      default: 'New'
      enum: ['Right', 'New']
      order: 10

    #TODO: Write autodetection of toolchain

  tokamakView: null
  cargoView: null
  toolchainView: null
  createProjectView: null
  aboutView: null

  modalPanel: null
  aboutModalPanel: null
  subscriptions: null

  activate: (state) ->
    if Utils.isTokamakProject()
      @tokamakConfig = Utils.parseTokamakConfig()
      @launchActivation(state)
      atom.config.set('tool-bar.visible', true)
    else
      atom.config.set('tool-bar.visible', false)

  launchActivation: (state) ->
    @tokamakView = new TokamakView(state.tokamakViewState)
    @cargoView = new CargoView(state.cargoViewState)
    @toolchainView = new ToolchainView(state.toolchainViewState)
    @createProjectView = new CreateProjectView(state.createProjectView)
    @aboutView = new AboutView(state.aboutView)

    Utils.installDependencies()

    if atom.config.get('tokamak.binaryDetection')
      Utils.detectBinaries()

    Utils.watchConfig()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register general commands
    @subscriptions.add atom.commands.add 'atom-workspace',
      'tokamak:detect-binaries': => Utils.detectBinaries()
      'tokamak:settings': => atom.workspace.open('atom://config/packages/tokamak/')
      'tokamak:run': =>
        if @tokamakConfig.options.save_buffers_before_run
          Utils.savePaneItems()
        Utils.openTerminal(atom.config.get("tokamak.cargoBinPath") + ' run')
      'tokamak:test': =>
        if @tokamakConfig.options.save_buffers_before_run
          Utils.savePaneItems()
        Utils.openTerminal(atom.config.get("tokamak.cargoBinPath") + ' test')
      'tokamak:toggle-toolbar': =>
        editor = atom.workspace.getActiveTextEditor()
        atom.commands.dispatch(atom.views.getView(editor), "tool-bar:toggle")
      'tokamak:create-tokamak-configuration': =>
        Utils.createDefaultTokamakConfig()
      'tokamak:toggle-auto-format-code': =>
        @cargoView.autoFormatting()

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'tokamak'

    @toolBar.addButton
      icon: 'package'
      callback: 'tokamak:create-project'
      tooltip: 'Create Project'

    @toolBar.addButton
      icon: 'cube'
      iconset: 'ion'
      callback: 'tokamak:create-tokamak-configuration'
      tooltip: 'Create Tokamak Configuration'

    @toolBar.addSpacer()

    @toolBar.addButton
      icon: 'hammer'
      iconset: 'ion'
      callback: 'tokamak:build'
      tooltip: 'Build'

    @toolBar.addButton
      icon: 'x'
      iconset: 'fi'
      callback: 'tokamak:clean'
      tooltip: 'Clean'

    @toolBar.addButton
      icon: 'refresh'
      iconset: 'ion'
      callback: 'tokamak:rebuild'
      tooltip: 'Rebuild'

    @toolBar.addButton
      icon: 'play'
      iconset: 'ion'
      callback: 'tokamak:run'
      tooltip: 'Cargo Run'

    @toolBar.addButton
      icon: 'check'
      iconset: 'fi'
      callback: 'tokamak:test'
      tooltip: 'Cargo Test'

    @toolBar.addButton
      icon: 'document-text'
      iconset: 'ion'
      callback: 'tokamak:format-code'
      tooltip: 'Cargo Format'

    @toolBar.addButton
      icon: 'terminal'
      callback: 'tokamak-terminal:new'
      tooltip: 'Terminal'

    @toolBar.addSpacer()

    @toolBar.addButton
      icon: 'eye'
      callback: 'tokamak:detect-binaries'
      tooltip: 'Detect Binaries'

    @toolBar.addButton
      icon: 'tools'
      callback: 'tokamak:select-toolchain'
      tooltip: 'Change Rust Toolchain'

    @toolBar.addButton
      icon: 'gear'
      callback: 'tokamak:settings'
      tooltip: 'Settings'

    @toolBar.addButton
      icon: 'nuclear'
      iconset: 'ion'
      callback: 'tokamak:about'
      tooltip: 'About Tokamak'

    @toolBar.onDidDestroy ->
      @toolBar = null

  deactivate: ->
    @modalPanel.destroy()
    @aboutModalPanel.destroy()
    @subscriptions.dispose()
    @toolchainView.destroy()
    @cargoView.destroy()
    @tokamakView.destroy()
    @createProjectView.destroy()
    @aboutView.destroy()
    @toolBar?.removeItems()

  serialize: ->
    if Utils.isTokamakProject()
      tokamakViewState: @tokamakView.serialize()
      cargoViewState: @cargoView.serialize()
      toolchainViewState: @toolchainView.serialize()
      createProjectViewState: @createProjectView.serialize()

  toggle: (@modal)->
    console.log 'Modal was toggled!'

    if @modal.isVisible()
      @modal.hide()
    else
      @modal.show()
