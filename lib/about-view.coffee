path = require 'path'
fs = require 'fs-plus'
Utils = require './utils'
{$, View} = require 'atom-space-pen-views'

module.exports =
class AboutView extends View
  previouslyFocusedElement: null

  @content: ->
    @div class: 'tokamak-about'

  constructor: (serializedState) ->
    super

    # Create view element
    templateData = fs.readFileSync(
      path.resolve(__dirname, '../templates/about-view.html'), {encoding: 'utf-8'});
    parser = new DOMParser();
    doc = parser.parseFromString(templateData, 'text/html');
    viewData = doc.querySelector('.tokamak-template-root').cloneNode(true);
    @setVersion(viewData)
    @element.appendChild(viewData)

  initialize: ->
    @commandSubscription = atom.commands.add 'atom-workspace',
      'tokamak:about': => @attach()

    $(@element).on 'click', => @close()
    atom.commands.add @element,
      'core:cancel': => @close()

  attach: (@mode) ->
    @previouslyFocusedElement = $(document.activeElement)
    @panel ?= atom.workspace.addModalPanel(item: this, visible: false)
    if @panel?.isVisible()
      @close()
    else
      @panel.show()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  setVersion: (viewData) ->
    ver = Utils.getVersion()
    vs = viewData.querySelector('.version-string');
    vs.textContent = ver

  # Tear down any state and detach
  destroy: ->
    @panel?.destroy()
    @commandSubscription.dispose()

  close: ->
    return unless @panel.isVisible()
    @panel.hide()
    @previouslyFocusedElement?.focus()

  getElement: ->
    @element
