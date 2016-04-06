{Disposable} = require 'atom';

currentService = null

isEnabled = ->
  Boolean(currentService)

module.exports =

getTerminalViews: ->
  if isEnabled()
    return currentService.getTerminalViews();
  else
    return -1;

destroyTerminalView: (view) ->
  if isEnabled()
    return currentService.destroyTerminalView(view);
  else
    return -1;

runInTerminal: (commands) ->
  if isEnabled()
    return currentService.run(commands);
  else
    return -1;

consumeRunInTerminal: (service) ->
  # Only first registered provider will be consumed
  if isEnabled()
    console.warn('Multiple terminal providers found.');
    return new Disposable(() => {});

  currentService = service;

  return new Disposable(() =>
    # Executed when provider package is deactivated
    currentService = null;
  );
