class Logger {
  constructor() {
    this._name = 'Tokamak';
    this._debug = false;
  }

  setDebug(debug) {
    if (!(typeof debug === 'boolean')) {
      throw new TypeError('debug is not a boolean');
    }

    this._debug = debug;
  }

  debug(...args) {
    if (!this._debug) {
      return;
    }

    if (args.length > 1) {
      console.group(this._name);
      args.forEach(console.log);
      console.groupEnd(this._name);
    } else {
      console.log(`${this._name}:\n`, ...args);
    }
  }

  error(...args) {
    if (args.length > 1) {
      console.group(this._name);
      args.forEach(console.error);
      console.groupEnd(this._name);
    } else {
      console.error(`${this._name}:\n`, ...args);
    }
  }
}

module.exports = new Logger