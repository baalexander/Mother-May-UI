(function() {

  var root   = this
    , mother = null
    , assert = null
    , util   = null

  // Exports as CommonJS module
  if (typeof exports !== 'undefined') {
    mother = exports
  }
  // Exports for UI Automator or Browser
  else {
    mother = root.mother = {}
    assert = root.assert = {}
    util   = root.util   = {}
  }

  // Mother
  // ------

  mother.config = {
    verbose: false
  }


  // Each test case is referenced by name on the tests hash
  mother.tests = {}

  // Series of tests to run
  mother.scenarios = []

  // may is really just syntactic sugar
  mother.may = {}

  // Creates a new series of tests to run
  mother.may.I = function(scenarioName) {

    // Begins a new series of tests
    var scenario = {
      name:  scenarioName
    , tests: []
    }
    mother.scenarios.push(scenario)

    return this
  }

  // Adds a test to the current series
  mother.may.and = function(testName, testFunction) {

    if (testFunction !== undefined) {
      mother.tests[testName] = testFunction
    }
    else {
      testFunction = mother.tests[testName]
    }

    var currentScenario = mother.scenarios[mother.scenarios.length - 1]
    if (currentScenario) {
      var test = {
        name:         testName
      , testFunction: testFunction
      }
      currentScenario.tests.push(test)
    }
    else {
      // Error with message about no test to run and needing mother.may.I()
      // first.
    }

    return this
  }

  mother.may.please = function(name, test) {
    var currentScenario = mother.scenarios[mother.scenarios.length - 1]
    if (currentScenario) {
      runScenario(currentScenario)
    }
    else {
      // Error with message about no test to run and needing mother.may.I()
      // first.
    }

    return this
  }

  // Runs each set of tests
  mother.please = function() {
    for (var i = 0; i < mother.scenarios.length; i++) {
      var scenario = mother.scenarios[i]
      runScenario(scenario, this.config)
    }

    return this
  }

  mother.setUp = function() {
    this.target     = UIATarget.localTarget()
    this.app        = this.target.frontMostApp()
    this.mainWindow = this.app.mainWindow()
  }

  mother.tearDown = function() {

  }

  // Run all the tests in a scenario
  function runScenario(scenario, config) {
    UIALogger.logStart(scenario.name)
    mother.setUp.call(this)
    scenario.passedTests = []

    var test = null
    try {
      for (var i = 0; i < scenario.tests.length; i++) {
        test = scenario.tests[i]

        if (config.verbose) {
          UIALogger.logMessage(test.name)
        }

        test.testFunction.call(this)
        scenario.passedTests[i] = test
      }
      UIALogger.logPass(scenario.name)
    }
    catch (exception) {
      var failMessage = 'Error in test \'' + test.name + '\''
        + ' of scenario \'' + scenario.name + '\'.'
        + ' ' + exception.message;
      UIALogger.logFail(failMessage)
      this.target.logElementTree()
    }

    mother.tearDown.call(this)
  }

  // Assert
  // ------

  assert.isEqual = function(actual, expected, message) {
    if (actual != expected) {
      var exception = {}
      if (message) {
        exception.message = message
      }
      else {
        exception.message = 'Expected \'' + expected + '\' got \'' + actual + '\'.'
      }
      throw exception
    }
  }

  assert.isStrictEqual = function(actual, expected, message) {
    if (actual !== expected) {
      var exception = {}
      if (message) {
        exception.message = message
      }
      else {
        exception.message = 'Expected \'' + expected + '\' got \'' + actual + '\'.'
      }
      throw exception
    }
  }

  assert.isTrue = function(value, message) {
    if (!value) {
      var exception = {}
      if (message) {
        exception.message = message
      }
      else {
        exception.message = 'Expression \'' + value + '\' failed.'
      }
      throw exception
    }
  }

  // Util
  // ----

  util.waitFor = function(element, timeout) {
    if (timeout == null) {
      timeout = 5.0
    }

    var delay = 0.1

    for (var i = 0; i < timeout / delay; i++) {
      UIATarget.localTarget().delay(delay)

      if (element.isVisible()) {
        return
      }
    }

    var exception = {}
    exception.message = "Element never became visible"
    throw exception
  }

}).call(this)

