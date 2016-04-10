{BufferedProcess} = require 'atom'
_ = require 'underscore-plus'
{$, SelectListView} = require 'atom-space-pen-views'

module.exports =
class RustUpToolchainView extends SelectListView
  previouslyFocusedElement: null
  cmd: null
  items: null
  rustupBinPath: null

  constructor: (serializedState) ->
    super

  initialize: ->
    super
    @rustupBinPath = atom.config.get("tokamak.rustupBinPath")
    @getToolchainList(@items, @toolchainExitCallback)
    @commandSubscription = atom.commands.add 'atom-workspace',
    'tokamak:rustup-select-toolchain': => @attach()

  attach: () ->
    @addClass('overlay from-top')
    console.log "ITEMS", @items
    @setItems(@items)
    @previouslyFocusedElement = $(document.activeElement)
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  changeToolchain: (item, callback) ->
      [responseSuccess, responseError] = ["", ""]
      @runCommandOut(
        @rustupBinPath
        ['default', item]
        stderr = (data) -> responseError += data.toString()
        stdout = (data) -> responseSuccess += data.toString()
        exit = (code) => callback(item, code, responseSuccess, responseError)
      )

  rustupExitCallback: (item, code, stdoutData, stderrData) =>
    if code != 0
      atom.notifications.addError("Tokamak: Failed to change toolchain to #{item}", {
        detail: "#{stderrData}"
      })
    else
      atom.notifications.addSuccess("Tokamak: Changed toolchain to #{item}", {
        detail: "#{stdoutData}"
      })
      @cancelled()

  getToolchainList: (@items, callback) ->
      @cmd = "Listing toolchains"
      [responseSuccess, responseError] = ["", ""]
      @runCommandOut(
        @rustupBinPath
        ['toolchain', 'list']
        stderr = (data) -> responseError += data.toString()
        stdout = (data) -> responseSuccess += data.toString()
        exit = (code) => callback(@cmd, code, responseSuccess, responseError, @items)
      )

  toolchainExitCallback: (@cmd, code, stdoutData, stderrData, @items) =>
    if code != 0
      atom.notifications.addError("Tokamak: #{@cmd} failed!", {
        detail: "#{stderrData}"
      })
    else
      if atom.devMode
        atom.notifications.addInfo("Tokamak: Toolchains detected successfully!")

    @items = _.compact(stdoutData.split('\n'));

  viewForItem: (item) ->
    "<li><span class='ion-settings'></span> #{item}</li>"

  confirmed: (item) ->
    console.info("Tokamak: About the change toolchain #{item}")
    @changeToolchain(item, @rustupExitCallback)

  cancelled: ->
    console.log("This view was cancelled")
    return unless @panel.isVisible()
    @panel.hide()
    @previouslyFocusedElement?.focus()

  serialize: ->

  runCommandOut: (command, args, stderr, stdout, exit) ->
    new BufferedProcess({command, args, stderr, stdout, exit})
