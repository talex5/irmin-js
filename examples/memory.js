require('../_build/lib/irmin_js');

function test_in_memory() { return (
  irmin.memRepo().then(function (repo) { return (
  repo.branch("master").then(function (master) { return (
  master.read(['key']).then(function(val) {
  console.log("before update: key=" + val);
  var meta = irmin.commitMetadata("user", "Set key"); return (
  master.update(meta, ['key'], 'value').then(function() { return (
  master.read(['key']).then(function(val) {
  console.log("after update:  key=" + val); return (
  master.head().then(function (head) {
  console.log("head: " + head)
  }) )}) )}) )}) )}) )}) )
}

console.log("test_in_memory: " + test_in_memory());
