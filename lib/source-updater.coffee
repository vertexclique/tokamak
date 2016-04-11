fs = require 'fs-plus'
request = require 'request'
tar = require 'tar'
zlib = require 'zlib'

SourceUpdaterView = require './source-updater-view'

module.exports =
class SourceUpdater
  @updateSourceFiles: ->
    progressNotification = new SourceUpdaterView()
    folder = fs.getAppDataDirectory() + "/tokamak/"
    fs.mkdir(folder, (error) ->
      out = fs.createWriteStream(folder + 'nightly_source.tar.gz');

      req = request({
          method: 'GET',
          uri: 'https://static.rust-lang.org/dist/rustc-nightly-src.tar.gz'
      })

      req.pipe(out)

      req.on('response', (data) ->
        progressNotification.updateState("Downloading")
        progressNotification.setStepAmount(data.headers['content-length'])
      )

      req.on('data', (chunk) ->
        progressNotification.updateDownloadProgress(chunk.length)
      )

      req.on('end', ->
        progressNotification.updateState("Extracting")
        archivePath = folder + 'nightly_source.tar.gz'
        sourceTar = fs.createReadStream(archivePath)
        extractor = tar.Extract({path: folder + 'rust-sources'})
                      .on('entry', (entry) -> progressNotification.updateExtractionProgress(entry.path))
                      .on('error', (error) -> console.error(error))
                      .on('end', ->
                        atom.notifications.addSuccess("Successfully updated Rust's source!")
                        progressNotification.dismiss()
                      )

        sourceTar
          .pipe(zlib.createGunzip())
          .pipe(extractor)
      )
    )
