TokamakView = require './tokamak-view'
CargoView = require './cargo-view'
MultirustToolchainView = require './multirust-toolchain-view'
CreateProjectView = require './create-project-view'
AboutView = require './about-view'

Utils = require './utils'

{BufferedProcess, CompositeDisposable} = require 'atom'

module.exports = Tokamak =
  # Config schema
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
    multirustBinPath:
      title: 'Path to the Multirust rust installation manager'
      type: 'string'
      default: '/usr/local/bin/multirust'
      order: 4
    racerBinPath:
      title: 'Path to the Racer executable'
      type: 'string'
      default: '/usr/local/bin/racer'
      order: 5
    rustSrcPath:
      title: 'Path to the Rust source code directory'
      type: 'string'
      default: '/usr/local/src/rust/src/'
      order: 6
    cargoHomePath:
      title: 'Cargo home directory (optional)'
      type: 'string'
      description: 'Needed when providing completions for Cargo crates when Cargo is installed in a non-standard location.'
      default: ''
      order: 7
    autocompleteBlacklist:
      title: 'Autocomplete Scope Blacklist'
      description: 'Autocomplete suggestions will not be shown when the cursor is inside the following comma-delimited scope(s).'
      type: 'string'
      default: '.source.go .comment'
      order: 8
    show:
      title: 'Show position for editor with definition'
      description: 'Choose one: Right, or New. If your view is vertically split, choosing Right will open the definition in the rightmost pane.'
      type: 'string'
      default: 'New'
      enum: ['Right', 'New']
      order: 9

    #TODO: Write autodetection of toolchain

  tokamakView: null
  cargoView: null
  multirustToolchainView: null
  createProjectView: null
  aboutView: null

  modalPanel: null
  aboutModalPanel: null
  subscriptions: null

  activate: (state) ->
    @tokamakView = new TokamakView(state.tokamakViewState)
    @cargoView = new CargoView(state.cargoViewState)
    @multirustToolchainView = new MultirustToolchainView(state.multirustToolchainViewState)
    @createProjectView = new CreateProjectView(state.createProjectView)
    @aboutView = new AboutView(state.aboutView)

    Utils.installDependencies()

    if atom.config.get('tokamak.binaryDetection')
      Utils.detectBinaries()

    Utils.watchConfig()

    @modalPanel = atom.workspace.addModalPanel(item: @tokamakView.getElement(), visible: false)
    @aboutModalPanel = atom.workspace.addModalPanel(item: @aboutView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'tokamak:toggle': => @toggle(@modalPanel)
      'tokamak:detect-binaries': => detectBinaries()

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'tokamak'

    @toolBar.addSpacer()

    @toolBar.addButton
      icon: 'package'
      callback: 'tokamak:create-project'
      tooltip: 'Create Project'

    @toolBar.addSpacer()

    @toolBar.addButton
      icon: 'ion ion-hammer'
      callback: 'tokamak:build'
      tooltip: 'Build'

    @toolBar.addButton
      icon: 'fi fi-x'
      callback: 'tokamak:clean'
      tooltip: 'Clean'

    @toolBar.addButton
      icon: 'ion ion-refresh'
      callback: 'tokamak:rebuild'
      tooltip: 'Rebuild'

    @toolBar.addButton
      icon: 'terminal'
      callback: 'tokamak:clean'
      tooltip: 'Terminal'

    @toolBar.addSpacer()

    @toolBar.addButton
      icon: 'eye'
      callback: 'tokamak:detect-binaries'
      tooltip: 'Detect Binaries'

    @toolBar.addButton
      icon: 'tools'
      callback: 'tokamak:multirust-select-toolchain'
      tooltip: 'Change Rust Toolchain'

    @toolBar.addButton
      icon: 'ion ion-nuclear'
      callback: 'tokamak:about'
      tooltip: 'About Tokamak'

    @toolBar.addSpacer()

    @toolBar.onDidDestroy ->
      @toolBar = null

  deactivate: ->
    @modalPanel.destroy()
    @aboutModalPanel.destroy()
    @subscriptions.dispose()
    @multirustToolchainView.destroy()
    @cargoView.destroy()
    @tokamakView.destroy()
    @createProjectView.destroy()
    @aboutView.destroy()
    @toolBar?.removeItems()

  serialize: ->
    tokamakViewState: @tokamakView.serialize()
    cargoViewState: @cargoView.serialize()
    multirustToolchainViewState: @multirustToolchainView.serialize()
    createProjectViewState: @createProjectView.serialize()

  toggle: (@modal)->
    console.log 'Modal was toggled!'

    if @modal.isVisible()
      @modal.hide()
    else
      @modal.show()
