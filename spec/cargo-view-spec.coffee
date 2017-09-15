CargoView = require '../lib/cargo-view'

describe "CargoView", ->

  [workspaceElement, activationPromise, cargoView] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('tokamak')
    cargoView = new CargoView({})

  describe "when CargoView activated", ->
    it "should load global tokamak configuration", ->
      expect(cargoView.tokamakConfig).not.toBe(null)
      expect(cargoView.tokamakConfig).not.toBe(undefined)

      # Check content of data
      expect(cargoView.tokamakConfig.helper.path)
        .toEqual("")
      expect(cargoView.tokamakConfig.project.auto_format_timing)
        .toBeGreaterThan( 0 )
      expect(cargoView.tokamakConfig.options.general_warnings)
        .toEqual(false)
      expect(cargoView.tokamakConfig.options.save_buffers_before_run)
        .toEqual(false)

    it "should create cargo library project view", ->
      expect(workspaceElement.querySelector('.tokamak')).not.toExist()

      atom.commands.dispatch(workspaceElement, 'tokamak:create-cargo-library')

      waitsForPromise ->
        activationPromise

      runs ->
        cargoPanel = atom.workspace.getModalPanels().slice(-1).pop()
        expect(cargoPanel.element.firstChild.className)
          .toEqual("tokamak-cargo")

        expect(cargoPanel.isVisible()).toBe true

    it "should create cargo binary project view", ->
      expect(workspaceElement.querySelector('.tokamak')).not.toExist()

      atom.commands.dispatch(workspaceElement, 'tokamak:create-cargo-binary')

      waitsForPromise ->
        activationPromise

      runs ->
        cargoPanel = atom.workspace.getModalPanels().slice(-1).pop()
        expect(cargoPanel.element.firstChild.className)
          .toEqual("tokamak-cargo")

        expect(cargoPanel.isVisible()).toBe true

    it "should launch build task", ->
      result = atom.commands.dispatch(workspaceElement, 'tokamak:build')

      waitsForPromise ->
        activationPromise

      runs ->
        expect(result).toBe true

    it "should launch clean task", ->
      result = atom.commands.dispatch(workspaceElement, 'tokamak:clean')

      waitsForPromise ->
        activationPromise

      runs ->
        expect(result).toBe true

    it "should launch rebuild task", ->
      result = atom.commands.dispatch(workspaceElement, 'tokamak:rebuild')

      waitsForPromise ->
        activationPromise

      runs ->
        expect(result).toBe true

    it "should launch format task", ->
      result = atom.commands.dispatch(workspaceElement, 'tokamak:format-code')

      waitsForPromise ->
        activationPromise

      runs ->
        expect(result).toBe true

    it "should launch format task", ->
      result = atom.commands.dispatch(workspaceElement, 'tokamak:format-code')

      waitsForPromise ->
        activationPromise

      runs ->
        expect(result).toBe true

    it "should destroy cargo view", ->
      atom.commands.dispatch(workspaceElement, 'tokamak:create-cargo-library')

      waitsForPromise ->
        activationPromise

      runs ->
        cargoPanel = atom.workspace.getModalPanels().slice(-1).pop()
        expect(cargoPanel.isVisible()).toBe true
        cargoPanel.destroy()
        expect(cargoPanel.isVisible()).toBe false

