(function() {
  var root   = this
    , mother = root.mother;

  if (mother === undefined) {
    mother = root.mother = {};
    mother.config = {};
  }

  mother.config.takeScreenshotOptions = {
    NEVER  : 'NEVER'
  , ERROR  : 'ERROR'
  , ALWAYS : 'ALWAYS'
  };

  // Called before each scenario is run. Takes care of basic boiler plate code.
  // Can override in the test file with:
  // mother.setUp = function() { /* custom code */ }
  mother.setUp = function() {
    this.target     = UIATarget.localTarget();
    this.app        = this.target.frontMostApp();
    this.mainWindow = this.app.mainWindow();
  }

  // Run all the tests in a scenario. Overrides mother's default implementation
  // with UIALogger for logging.
  mother.runScenario = function(scenario) {
    UIALogger.logStart(scenario.name);
    mother.setUp.call(this);
    scenario.passedTests = [];

    var test = null;
    try {
      for (var i = 0; i < scenario.tests.length; i++) {
        test = scenario.tests[i];

        if (mother.config.verbose) {
          UIALogger.logMessage(test.name);
        }

        test.testFunction.call(this);

        if (mother.config.takeScreenshot == mother.config.takeScreenshotOptions.ALWAYS) {
          var screenshotName = scenario.name + ' (' + test.name + ')';
          UIATarget.localTarget().captureScreenWithName(screenshotName);
        }

        scenario.passedTests[i] = test;
      }
      UIALogger.logPass(scenario.name);
    }
    catch (exception) {
      var failMessage = 'Error in test \'' + test.name + '\''
        + ' of scenario \'' + scenario.name + '\'.'
        + ' ' + exception.message;
      UIALogger.logFail(failMessage);

      if (mother.config.takeScreenshot == mother.config.takeScreenshotOptions.ALWAYS ||
          mother.config.takeScreenshot == mother.config.takeScreenshotOptions.ERROR) {
        var screenshotName = scenario.name + ' (' + test.name + ')';
        UIATarget.localTarget().captureScreenWithName(screenshotName);
      }

      if (mother.config.verbose) {
        UIATarget.localTarget().logElementTree();
      }
    }

    mother.tearDown.call(this);
  }

}).call(this);

