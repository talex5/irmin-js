require('../_build/lib/irmin_js');

irmin.mem_repo()
  .then(function (repo) {
    console.log("repo: " + repo);
    repo.branch("master")
      .then(function (master) {
        console.log("branch: " + master);
        master.read('key').then(function(val) {
	  console.log("key=" + val);
	  master.update('key', 'value').then(function() {
	    console.log("update done");
	    master.read('key').then(function(val) {
	      console.log("key=" + val);
	      master.head().then(function (head) {
		console.log("head: " + head);
	      });
	    });
	  });
        });
      });
  });

console.log("waiting");
setTimeout(function () { console.log("done") }, 1000);
