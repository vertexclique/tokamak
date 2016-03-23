{$, SelectListView} = require 'atom-space-pen-views'

module.exports =
class MultirustListView extends SelectListView
  previouslyFocusedElement: null

  initialize: ->
     super
     @commandSubscription = atom.commands.add 'atom-workspace',
     'tokamak:multirust-list-version': => @attach('list-version')

  attach: (@version) ->
     @addClass('overlay from-top')
     @setItems(['Hello', 'World'])
     @previouslyFocusedElement = $(document.activeElement)
     @panel ?= atom.workspace.addModalPanel(item: this)
     @panel.show()
     @focusFilterEditor()

  viewForItem: (item) ->
     "<li>#{item}</li>"

  confirmed: (item) ->
     console.log("#{item} was selected")

  cancelled: ->
     console.log("This view was cancelled")
     return unless @panel.isVisible()
     @panel.hide()
     @previouslyFocusedElement?.focus()
