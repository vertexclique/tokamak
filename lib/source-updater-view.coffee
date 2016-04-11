module.exports =
class SourceUpdaterView
  constructor: ->
    @progressBar = document.createElement('progress')
    @progressBar.style.width = '100%'

    @stepProgress = 0

    @element = atom.notifications.addInfo("Updating Rust source...", {
      detail: "Initializing...",
      dismissable: true
      })

    notificationView = atom.views.getView(@element)
    detailContent = notificationView.querySelector('.detail-content')
    detailContent.appendChild(@progressBar)
    @detailText = detailContent.querySelector('.line')

  updateState: (name) ->
    @progressBar.value = 0
    @progressBar.max = 0
    @stepProgress = 0
    @detailText.innerHTML = "#{@name}..."

  setStepAmount: (size) ->
    @progressBar.max = size

  updateDownloadProgress: (bytesDownloaded = 0) ->
    @stepProgress += bytesDownloaded
    @progressBar.value = @stepProgress
    downloadPercent = Math.trunc((@stepProgress / @progressBar.max) * 100.0)
    @detailText.innerHTML = "Downloading... " + downloadPercent + "% completed."

  updateExtractionProgress: (currentFile) ->
    @detailText.innerHTML = "Extracting... " + currentFile

  dismiss: ->
    @element.dismiss()
