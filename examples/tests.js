(function(exports){
  function run(repo, log) {
    log("--- testSetKey:"); return (
    repo.branch("master").then(function (master) { return (
    testSetKey(master, log).then(function () {
    log("\n--- testView:"); return (
    testView(master, log).then(function () {
    log("\n--- contents:"); return (
    listContents(master, ["dir"], log)
    )}))}))})
  )}

  function listContents(branch, dir, log) { return (
    branch.list(dir).then(function (paths) {
      for (var i in paths) {
	log("/" + paths[i].join("/"));
      }
    }))
  }

  function testView(branch, log) {
    var note = ["dir", "note"];
    var meta = irmin.commitMetadata("user", "testView"); return (
    branch.withMergeView(meta, [], function (view) { return (
      view.update(["dir", "3"], "hello").then(function () { return (
      listContents(view, ["dir"], log).then(function () { return (
      view.read(note).then(function (one) {
      if (one === null) { return view.update(note, "Initial note") }
      // else already set
      }).then(function () {
      branch.read(note).then(function (v) {
      log("Note in branch: " + v); return (
      view.read(note).then(function (v) {
      log("Note in view: " + v);
      }))})}))}))})
    )}).then(function (mergeConflict) {
    if (mergeConflict == null) {
      log("Merge successful")
      branch.read(note).then(function (v) {
      log("Note in branch: " + v);
      })
    } else throw("Merge conflict: " + mergeConflict)
    })
  )}

  function testSetKey(branch, log) { return (
    branch.read(['key']).then(function(val) {
    log("before update: key=" + val);
    var meta = irmin.commitMetadata("user", "Set key"); return (
    branch.update(meta, ['key'], 'value').then(function() { return (
    branch.read(['key']).then(function(val) {
    log("after update:  key=" + val); return (
    branch.head().then(function (head) {
    log("head: " + head);
    return listContents(head, [], log);
    }) )}) )}) )})
  )}

  exports.testIrmin = run
})(typeof exports === 'undefined' ? this['irmin_tests']={} : exports);
