{BufferedProcess} = require 'atom'
_ = require 'underscore-plus'
{$, SelectListView} = require 'atom-space-pen-views'

module.exports =
class CreateProjectView extends SelectListView
  previouslyFocusedElement: null
  cmd: null
  items: [
    "create-cargo-library",
    "create-cargo-binary"
  ]

  constructor: (serializedState) ->
    super

  initialize: ->
    super
    @commandSubscription = atom.commands.add 'atom-workspace',
    'tokamak:create-project': => @attach()

  attach: () ->
    @addClass('overlay from-top')
    @setItems(@items)
    @previouslyFocusedElement = $(document.activeElement)
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  viewForItem: (item) ->
    eventName = _.humanizeEventName(item)
    "<li><span class='ion-flash'></span> #{eventName}</li>"

  confirmed: (item) ->
    console.info("Tokamak: Calling event #{item}")
    commandName = "tokamak:#{item}"
    console.log _.first($('atom-workspace'))
    retval = atom.commands.dispatch(_.first($('atom-workspace')), commandName)
    console.log retval

  cancelled: ->
    console.log "Tokamak: Create project view was cancelled"
    return unless @panel.isVisible()
    @panel.hide()
    @previouslyFocusedElement?.focus()

  serialize: ->
