const child_process = require('child_process')
const os = require('os')
const path = require('path')
const _ = require('underscore-plus')

const Logger = require('./logger')
const State = require('./state')
const StatusView = require('./status-view')

function getCargoPath() {
  let PATH = process.env.PATH
  PATH = PATH + ":" + path.dirname(atom.config.get("tokamak.cargoBinPath"))
  return PATH;
}

function getToolBinPath() {
  return atom.config.get("tokamak.toolBinPath");
}

function getRustSrcPath() {
  return atom.config.get("tokamak.rustSrcPath");
}

function exec(command) {
  return new Promise((resolve, reject) => {
    console.log("[TOKAMAK]", command)
    child_process.exec(command, {env: {PATH: getCargoPath()}}, (err, stdout, stderr) => {
      if (err != null) {
        reject(err);
        return;
      }

      resolve({stdout, stderr});
    })
  })
}

function atomPrompt(message, options, buttons) {
  return new Promise((resolve, reject) => {
    const notification = atom.notifications.addInfo(message, Object.assign({
      dismissable: true,
      buttons: buttons.map((button) => (
        {
          text: button,
          onDidClick: () => {
            resolve(button)
            notification.dismiss()
          },
        }
      ))
    }, options))

    notification.onDidDismiss(() => resolve(null))
  })
}

// Installs rustup
function installRustup () {
  return exec("curl https://sh.rustup.rs -sSf | sh -s -- -y")
}

// Installs nightly
function installNightly () {
  return exec(`${getToolBinPath()} toolchain install nightly`)
}

// Checks for rustup and nightly toolchain
// If not found, asks to install. If user declines, throws error
function checkToolchain () {
  return new Promise((resolve, reject) => {
    const toolBinPath = getToolBinPath()
    exec(`${toolBinPath} toolchain list`).then((results) => {
      const { stdout } = results;
      const matches = (/^(?=nightly)(.*)$/mi).exec(stdout);

      // If found, we're done
      if (matches) {
        return resolve(matches[0])
      }

      // If not found, install it
      // Ask to install
      atomPrompt("`rustup` missing nightly toolchain", {
        detail: "rustup toolchain install nightly",
      }, ["Install"]).then((response) => {
        if (response === "Install") {
          installNightly().then(checkToolchain).then(resolve).catch(reject)
        } else {
          reject();
        }
      })
    }).catch(() => {
      // Missing rustup
      // Ask to install
      atomPrompt("`rustup` is not available", {
        description: "From https://www.rustup.rs/",
        detail: "curl https://sh.rustup.rs -sSf | sh",
      }, ["Install"]).then((response) => {
        if (response === "Install") {
          // Install rustup and try again
          installRustup().then(checkToolchain).then(resolve).catch(reject)
        } else {
          reject();
        }
      })
    })
  })
}

// Check for and install RLS
function checkRLS() {
  const toolBinPath = getToolBinPath()
  return exec(`${toolBinPath} component list --toolchain nightly`).then((results) => {
    const { stdout } = results;
    if (stdout.search(/^rls.* \((default|installed)\)$/m) >= 0 &&
        stdout.search(/^rust-analysis.* \((default|installed)\)$/m) >= 0 &&
        stdout.search(/^rust-src.* \((default|installed)\)$/m) >= 0) {
      // Have RLS
      return;
    }

    // Don't have RLS
    return exec(`${toolBinPath} component add rls --toolchain nightly`).then(() =>
      exec(`${toolBinPath} component add rust-src --toolchain nightly`)
    ).then(() =>
      exec(`${toolBinPath} component add rust-analysis --toolchain nightly`)
    )
  })
}

class RLS {
  constructor () {
    this.statusView = new StatusView();
    this.statusTile = null;
  }

  getGrammarScopes () { return [ 'source.rust' ] }
  getLanguageName () { return 'Rust' }
  getServerName () { return 'Tokamak RLS' }

  onStartServerProcessError(error) {
    this.statusView.setState(State.ERROR);
  }

  startServerProcess () {
    let toolchain, toolBinPath;
    return checkToolchain().then((toolchain_) => {
      toolchain = toolchain_;
      toolBinPath = getToolBinPath();

      return checkRLS()
    }).then(() => {
      return child_process.spawn(`${toolBinPath}`, ['run', 'nightly', 'rls'],
        {
          env: _.extend(process.env, {
            PATH: getCargoPath(),
            RUST_SRC_PATH: getRustSrcPath(),
          })
        }).on('error', error => this.onStartServerProcessError(error));
    })
  }
}

module.exports = new RLS