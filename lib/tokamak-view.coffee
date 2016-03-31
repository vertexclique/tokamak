module.exports =
class TokamakView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('tokamak')

    # Create message element
    message = document.createElement('div')
    message.textContent = "The Tokamak package is Alive! It's ALIVE!"
    message.classList.add('message')
    @element.appendChild(message)
    #sleep 4
    #@element.remove(message)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  cancelled: ->
    @element.hide()
