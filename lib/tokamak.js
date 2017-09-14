/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Views
const TokamakView = require('./tokamak-view');
const CargoView = require('./cargo-view');
const ToolchainView = require('./toolchain-view');
const CreateProjectView = require('./create-project-view');
const AboutView = require('./about-view');

const {AutoLanguageClient} = require('atom-languageclient');
const State = require('./state')

// Helpers
const Utils = require('./utils');
const rls = require('./rls');

const {consumeRunInTerminal} = require('./terminal');
const {BufferedProcess, CompositeDisposable} = require('atom');

class Tokamak extends AutoLanguageClient {
  static initClass() {

    // Config schema
    this.prototype.consumeRunInTerminal = consumeRunInTerminal;
    this.prototype.config = {
      launchAlways: {
        title: 'Launch always on startup with Global Configuration',
        type: 'boolean',
        description: 'Launches токамак with Global configuration without looking for Project specific configuration file in Rust project.',
        default: true,
        order: 1
      },
      binaryDetection: {
        title: 'Detect binaries on startup',
        type: 'boolean',
        description: 'Set toolchain executables if it is found under PATH.',
        default: true,
        order: 2
      },
      rustcBinPath: {
        title: 'Path to the Rust compiler',
        type: 'string',
        default: '/usr/local/bin/rustc',
        order: 3
      },
      cargoBinPath: {
        title: 'Path to the Cargo package manager',
        type: 'string',
        default: '/usr/local/bin/cargo',
        order: 4
      },
      toolBinPath: {
        title: 'Path to the RustUp or Multirust rust installation manager',
        type: 'string',
        default: '$HOME/.cargo/bin/rustup',
        order: 5
      },
      toolChain: {
        title: 'Select RustUp or Multirust for toolchain management',
        type: 'string',
        default: 'rustup',
        order: 6
      },
      racerBinPath: {
        title: 'Path to the Racer executable',
        type: 'string',
        default: '/usr/local/bin/racer',
        order: 7
      },
      rustSrcPath: {
        title: 'Path to the Rust source code directory',
        type: 'string',
        default: '/usr/local/src/rust/src/',
        order: 8
      },
      cargoHomePath: {
        title: 'Cargo home directory (optional)',
        type: 'string',
        description: 'Needed when providing completions for Cargo crates when Cargo is installed in a non-standard location.',
        default: '',
        order: 9
      },
      autocompleteBlacklist: {
        title: 'Autocomplete Scope Blacklist',
        description: 'Autocomplete suggestions will not be shown when the cursor is inside the following comma-delimited scope(s).',
        type: 'string',
        default: '.source.go .comment',
        order: 10
      },
      show: {
        title: 'Show position for editor with definition',
        description: 'Choose one: Right, or New. If your view is vertically split, choosing Right will open the definition in the rightmost pane.',
        type: 'string',
        default: 'New',
        enum: ['Right', 'New'],
        order: 11
      }
    };

    this.prototype.tokamakView = null;
    this.prototype.cargoView = null;
    this.prototype.toolchainView = null;
    this.prototype.createProjectView = null;
    this.prototype.aboutView = null;

    this.prototype.modalPanel = null;
    this.prototype.aboutModalPanel = null;
    this.prototype.subscriptions = null;
  }

  constructor() {
    rls.statusView.setState(State.PENDING);
    super().activate();
    super.activate();
    Tokamak.initClass();
  }

  getGrammarScopes() {
    return rls.getGrammarScopes();
  }
  getLanguageName() {
    return rls.getLanguageName();
  }
  getServerName() {
    return rls.getServerName();
  }

  startServerProcess() {
    return rls.startServerProcess()
  }

  activate(state) {
    if (state === undefined) {
      state = {
        tokamakViewState: {},
        cargoViewState: {},
        toolchainViewState: {},
        createProjectView: {},
        aboutView: {}
      }
    }

    // DEBUGGING FOR LANGUAGE SERVER
    // atom.config.set('core.debugLSP', true)
    const launchAlways = atom.config.get("tokamak.launchAlways");
    if (launchAlways) {
      if (Utils.isTokamakProject()) {
        return this.tokamakProjectConfigLaunch(state);
      } else {
        return this.tokamakGlobalConfigLaunch(state);
      }
    } else {
      if (Utils.isTokamakProject()) {
        return this.tokamakProjectConfigLaunch(state);
      } else {
        return this.dontLoadTokamak();
      }
    }
  }

  tokamakGlobalConfigLaunch(state) {
    Utils.createGlobalTokamakConfig();
    this.tokamakConfig = Utils.parseGlobalTokamakConfig();
    this.launchActivation(state);
    return atom.config.set('tool-bar.visible', true);
  }

  tokamakProjectConfigLaunch(state) {
    this.tokamakConfig = Utils.parseTokamakConfig();
    this.launchActivation(state);
    return atom.config.set('tool-bar.visible', true);
  }

  dontLoadTokamak() {
    return atom.config.set('tool-bar.visible', false);
  }

  launchActivation(state) {
    this.tokamakView = new TokamakView(state.tokamakViewState);
    this.cargoView = new CargoView(state.cargoViewState);
    this.toolchainView = new ToolchainView(state.toolchainViewState);
    this.createProjectView = new CreateProjectView(state.createProjectView);
    this.aboutView = new AboutView(state.aboutView);

    Utils.installDependencies();

    if (atom.config.get('tokamak.binaryDetection')) {
      Utils.detectBinaries();
    }

    Utils.watchConfig();

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable;

    // Register general commands
    return this.subscriptions.add(atom.commands.add('atom-workspace', {
      'tokamak:detect-binaries': () => Utils.detectBinaries(),
      'tokamak:settings': () => atom.workspace.open('atom://config/packages/tokamak/'),
      'tokamak:run': () => {
        if (this.tokamakConfig.options.save_buffers_before_run) {
          Utils.savePaneItems();
        }
        return Utils.openTerminal(atom.config.get("tokamak.cargoBinPath") + ' run');
      },
      'tokamak:test': () => {
        if (this.tokamakConfig.options.save_buffers_before_run) {
          Utils.savePaneItems();
        }
        return Utils.openTerminal(atom.config.get("tokamak.cargoBinPath") + ' test');
      },
      'tokamak:toggle-toolbar': () => {
        const editor = atom.workspace.getActiveTextEditor();
        return atom.commands.dispatch(atom.views.getView(editor), "tool-bar:toggle");
      },
      'tokamak:create-tokamak-configuration': () => {
        return Utils.createDefaultTokamakConfig();
      },
      'tokamak:toggle-auto-format-code': () => {
        return this.cargoView.autoFormatting();
      }
    }
    )
    );
  }

  consumeToolBar(toolBar) {
    this.toolBar = toolBar('tokamak');

    this.toolBar.addButton({
      icon: 'package',
      callback: 'tokamak:create-project',
      tooltip: 'Create Project'
    });

    this.toolBar.addButton({
      icon: 'cube',
      iconset: 'ion',
      callback: 'tokamak:create-tokamak-configuration',
      tooltip: 'Create Tokamak Configuration'
    });

    this.toolBar.addSpacer();

    this.toolBar.addButton({
      icon: 'hammer',
      iconset: 'ion',
      callback: 'tokamak:build',
      tooltip: 'Build'
    });

    this.toolBar.addButton({
      icon: 'x',
      iconset: 'fi',
      callback: 'tokamak:clean',
      tooltip: 'Clean'
    });

    this.toolBar.addButton({
      icon: 'refresh',
      iconset: 'ion',
      callback: 'tokamak:rebuild',
      tooltip: 'Rebuild'
    });

    this.toolBar.addButton({
      icon: 'play',
      iconset: 'ion',
      callback: 'tokamak:run',
      tooltip: 'Cargo Run'
    });

    this.toolBar.addButton({
      icon: 'check',
      iconset: 'fi',
      callback: 'tokamak:test',
      tooltip: 'Cargo Test'
    });

    this.toolBar.addButton({
      icon: 'document-text',
      iconset: 'ion',
      callback: 'tokamak:format-code',
      tooltip: 'Cargo Format'
    });

    this.toolBar.addButton({
      icon: 'terminal',
      callback: 'tokamak-terminal:new',
      tooltip: 'Terminal'
    });

    this.toolBar.addSpacer();

    this.toolBar.addButton({
      icon: 'eye',
      callback: 'tokamak:detect-binaries',
      tooltip: 'Detect Binaries'
    });

    this.toolBar.addButton({
      icon: 'tools',
      callback: 'tokamak:select-toolchain',
      tooltip: 'Change Rust Toolchain'
    });

    this.toolBar.addButton({
      icon: 'gear',
      callback: 'tokamak:settings',
      tooltip: 'Settings'
    });

    this.toolBar.addButton({
      icon: 'nuclear',
      iconset: 'ion',
      callback: 'tokamak:about',
      tooltip: 'About Tokamak'
    });

    return this.toolBar.onDidDestroy(function() {
      return this.toolBar === undefined ? null : this.toolBar = null;
    });
  }

  preInitialization(connection) {
    connection.onCustom('rustDocument/diagnosticsBegin', () => {
      rls.statusView.setState(State.ANALYZING);
    });
    connection.onCustom('rustDocument/diagnosticsEnd', () => {
      rls.statusView.setState(State.READY);
    });
  }

  consumeStatusBar(statusBar) {
    if (rls.statusTile) {
      rls.statusTile.destroy();
      rls.statusTile = null;
    }

    rls.statusTile = statusBar.addLeftTile({
      item: rls.statusView.element,
    });
  }

  deactivate() {
    if (this.modalPanel !== undefined)
      this.modalPanel.destroy();
    this.aboutModalPanel.destroy();
    this.subscriptions.dispose();
    this.toolchainView.destroy();
    this.cargoView.destroy();
    this.tokamakView.destroy();
    this.createProjectView.destroy();
    this.aboutView.destroy();
    if (rls.statusTile) {
      rls.statusTile.destroy();
      rls.statusTile = null;
    }
    return (this.toolBar != null ? this.toolBar.removeItems() : undefined);
  }

  serialize() {
    if (Utils.isTokamakProject()) {
      return {
        tokamakViewState: this.tokamakView.serialize(),
        cargoViewState: this.cargoView.serialize(),
        toolchainViewState: this.toolchainView.serialize(),
        createProjectViewState: this.createProjectView.serialize()
      };
    }
  }

  toggle(modal){
    this.modal = modal;
    console.log('Modal was toggled!');

    if (this.modal.isVisible()) {
      return this.modal.hide();
    } else {
      return this.modal.show();
    }
  }
}


module.exports = new Tokamak;