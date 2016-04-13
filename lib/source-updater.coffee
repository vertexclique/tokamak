crypto = require 'crypto'
fs = require 'fs-plus'
request = require 'request'
tar = require 'tar'
zlib = require 'zlib'

SourceUpdaterView = require './source-updater-view'

module.exports =
class SourceUpdater
  @checkForUpdate: (channelName) ->
    folder = fs.getAppDataDirectory() + "/tokamak/source-checksums/"
    fs.mkdir(folder, (error) ->
      file = folder + "new-rustc-#{channelName}-src.tar.gz.sha256"
      out = fs.createWriteStream(file);

      req = request({
          method: 'GET',
          uri: "https://static.rust-lang.org/dist/rustc-#{channelName}-src.tar.gz.sha256"
      })

      req.pipe(out)

      req.on('end', ->
        fs.readFile(file, 'utf-8', (error, data) ->
          # TODO: Error handling
          checksum = data.substring(0, data.indexOf(" "))
          installedChecksumFile = folder + "installed-rustc-#{channelName}-src.tar.gz.sha256"

          fs.stat(installedChecksumFile, (error, stats) ->
            # TODO: Error handling
            if stats?
              fs.readFile(installedChecksumFile, 'utf-8', (error, data) ->
                # TODO: Error handling
                installedChecksum = data.substring(0, data.indexOf(" "))

                if installedChecksum is not checksum
                  SourceUpdater.updateSourceFiles(channelName, file)
              )
            else
              SourceUpdater.updateSourceFiles(channelName, file)
          )
        )
      )
    )

  @updateSourceFiles: (channelName, checksumFilePath = null) ->
    progressNotification = new SourceUpdaterView()
    folder = fs.getAppDataDirectory() + "/tokamak/"
    fs.mkdir(folder, (error) ->
      archivePath = folder + "#{channelName}_source.tar.gz"
      out = fs.createWriteStream(archivePath);

      req = request({
          method: 'GET',
          uri: "https://static.rust-lang.org/dist/rustc-#{channelName}-src.tar.gz"
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
        progressNotification.updateState("Validating")

        fs.readFile(checksumFilePath, 'utf-8', (error, data) ->
          # TODO: Error handling
          checksum = data.substring(0, data.indexOf(" "))
          sha256Hasher = crypto.createHash('sha256')
          sourceTar = fs.createReadStream(archivePath)
          sourceTar.on('data', (data) -> sha256Hasher.update(data))
          sourceTar.on('end', ->
            fileChecksum = sha256Hasher.digest('hex')

            if fileChecksum is checksum
              progressNotification.updateState("Extracting")

              sourceTar = fs.createReadStream(archivePath)
              extractor = tar.Extract({path: folder + 'rust-sources'})
                            .on('entry', (entry) -> progressNotification.updateExtractionProgress(entry.path))
                            .on('error', (error) -> console.error(error))

              sourceTar
                .pipe(zlib.createGunzip())
                .pipe(extractor)
                .on('end', ->
                  # Rename the new checksum file to 'installed' so future calls to checkForUpdate can use that for comparison.
                  fs.rename(checksumFilePath, folder + "/source-checksums/installed-rustc-#{channelName}-src.tar.gz.sha256", (error) ->
                    # TODO: Error handling
                    atom.notifications.addSuccess("Successfully updated Rust's #{channelName} source!")
                    progressNotification.dismiss()
                  )
                )
            else
              # TODO: Incorrect checksum handling.
          )
        )
      )
    )
