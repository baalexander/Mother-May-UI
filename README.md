## Intro

Mother May UI is an automated BDD framework for iOS apps using [UI
Automation](http://developer.apple.com/library/ios/documentation/DeveloperTools/Conceptual/InstrumentsUserGuide/Built-InInstruments/Built-InInstruments.html#//apple_ref/doc/uid/TP40004652-CH6-SW75).

Wait. What?

Xcode provides the Automation instrument, which allows for testing the UI for
iOS apps in JavaScript. The JavaScript framework can simulate user interactions
and test for conditions.

Mother May UI extends the Automation framework to make it simple to focus on
Behavior Driven Development. Really, Mother May UI just makes it easy to write
highly-readable scenario-based tests for user interface interactions.

Automate smoke tests, regression tests, system tests and make your QA team's
lives easier.

## Example

Let's begin with a basic scenario we'd like to automate and verify: Logging in
as a user then logging out.

```javascript
#import "mother-ios.js";

// Creates a new scenario to log in and log out
mother.may.I('Log in and log out as testUser')
  // First test case in the scenario logs a given user in
  .and('log in as testUser', function() {
    var usernameField = this.mainWindow.textFields()[0];
    usernameField.setValue('testUser');
    var passwordField = this.mainWindow.secureTextFields()[0];
    passwordField.setValue('testPassword');
    var loginButton = this.mainWindow.buttons()[0];
    loginButton.tap();
  })
  // The next test case in the scenario logs the user out ()
  .and('log out', function() {
    var backButton = this.mainWindow.navigationBar().leftButton();
    util.waitFor(backButton);
    assert.isTrue(backButton.isValid(), 'Unable to find Back button');
    backButton.tap();
  });
```

Pretty sweet, simply define a scenario and a set of tests to run inside the
scenario. Usually, a test case will refer to a single view on the iPhone or iPad
and a scenario will encompass multiple views.

But, the real beauty comes when reusing the test cases. Once a test case is
defined in any scenario, the test case can be reused by simply referencing the
test name. Here's another test scenario that would follow the `Log in and log
out as testUser`.

```javascript
mother.may.I('Log in, click a cell, then log out')
  // Since we already declared the log in test case in another scenario, we can
  // simply reference it here and not re-declare the function. So DRY.
  .and('log in as testUser')
  .and('select the Aston Martin', function() {
    var tableView = this.mainWindow.elements()[1];
    assert.isTrue(tableView.isValid(), 'Unable to find cars table view');
    var cell = tableView.cells().firstWithName('2012 Aston Martin Virage');
    tableView.scrollToElementWithName(cell);
    cell.tap();
  })
  .and('verify Aston Martin details', function() {
    // Validate the values
  })
  .and('back out to cars list', function() {
    var backButton = this.mainWindow.navigationBar().leftButton();
    assert.isTrue(backButton.isValid(), 'Unable to find Back button');
    backButton.tap();
  })
  // We can re-use the log out test case too
  .and('log out');
```

After a while, your test scenarios start looking like:

```javascript
mother.may.I('Log in, do something amazing, then log out')
  .and('log in as testUser')
  .and('do something amazing')
  .and('log out');
```

Mmm, succulent.

## But wait, there's more

In addition to a framework for easier UI testing of iOS apps, Mother May UI also
provides a bash script to run your tests from the command line. That's right,
include automated UI testing as part of your continuous integration solution.

```bash
mother.sh -w <device UDID> -a "Car Lot.app" -o runs -t tests.js -v
```

## Code Layout

The important thing to note when navigating the code is that the core mother.js
code is platform agnostic. `lib/mother.js` is meant to provide simple BDD UI
testing to all JavaScript environments, including the browser, Node.js and iOS.

iOS specific code will usually reside in an `ios` subdirectory.

 * `bin/` - Any shell scripts to help with running Mother May UI
 * `bin/ios/mother.sh` - iOS specific shell script for launching instruments
 * `examples/` - Example code
 * `examples/ios/Car Lot/` - Example iOS project
 * `examples/ios/Car Lot/UI Tests/test.js` - Test file for example iOS project
 * `lib/mother.js` - Cross-Platform Mother May UI framework
 * `lib/ios/` - iOS specific additions to Mother May UI

## License (MIT)

Copyright (c) 2011 Brandon Ace Alexander

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

