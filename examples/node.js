require('../_build/lib/irmin_js.js');
var tests = require('./tests');

var memTest = irmin.memRepo().then(function (repo) { tests.testIrmin(repo, console.log) });
console.log("test_in_memory: " + memTest);
