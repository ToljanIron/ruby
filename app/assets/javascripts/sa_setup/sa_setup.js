/*globals $, document */
var sas = {};

sas.updatePushState = function() {

  $.get("/sa_setup/get_push_state", {},
    function(data, status) {
      if (status !== 'success') {
        console.error("Error in get_push_state: ", status);
      }

      document.getElementById('sasNumOfLogfiles').innerHTML = data.num_files;
      document.getElementById('sasNumOfLogfilesProcessed').innerHTML = data.num_files_processed;
      document.getElementById('sasNumOfSnapshots').innerHTML = data.num_snapshots;
      document.getElementById('sasNumOfSnapshotsCreated').innerHTML = data.num_snapshots_created;
      document.getElementById('sasNumOfSnapshotsProcessed').innerHTML = data.num_snapshots_processed;

      console.log( data )
      if (data.state !== 'done') {
        setTimeout( sas.updatePushState, 10000 );
      }
    }
  );
};

