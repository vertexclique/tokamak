{$} = require 'atom-space-pen-views'

module.exports =
class AboutView
  previouslyFocusedElement: null

  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('tokamak-about')

    # Create view element
    templateData = fs.readFileSync(
      path.resolve(__dirname, '../templates/about-view.html'), {encoding: 'utf-8'});
    parser = new DOMParser();
    doc = parser.parseFromString(templateData, 'text/html');
    viewData = doc.querySelector('.tokamak-template-root').cloneNode(true);
    @element.appendChild(viewData)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
