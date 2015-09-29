(function(exports){
  function run(repo, log) { return (
    repo.branch("master").then(function (master) { return (
    master.read(['key']).then(function(val) {
    log("before update: key=" + val);
    var meta = irmin.commitMetadata("user", "Set key"); return (
    master.update(meta, ['key'], 'value').then(function() { return (
    master.read(['key']).then(function(val) {
    log("after update:  key=" + val); return (
    master.head().then(function (head) {
    log("head: " + head)
    }) )}) )}) )}) )}) )
  }

  exports.testIrmin = run
})(typeof exports === 'undefined' ? this['irmin_tests']={} : exports);
