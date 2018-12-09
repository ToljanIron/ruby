/*globals $, document */
var sas = {};

sas.updatePushState = function() {
  var PARTIALLEN = 0.33;


  // Assert whthere the collector is still working
  var inCollect = function(state) {
    return state === 'init' ||
           state === 'transfer_log_files' ||
           state === 'process_log_files';
  };

  // Assert whether system is creating snapshots
  var inCreateSnapshot = function(state) {
    return state === 'collector_done' ||
           state === 'count_snapshots' ||
           state === 'create_snapshots';
  };

  // Assert whether system is in precalculate stage
  var inPrecalculate = function(state) {
    return state === 'preprocess_snapshots' ||
           state === 'done';
  };

  // Assert whether is error state
  var inError = function(state) {
    return state === 'error';
  };

  $.get("/sa_setup/get_push_state", {},
    function(data, status) {
      if (status !== 'success') {
        console.error("Error in get_push_state: ", status);
      }

      //////////////// Calculate the fraction /////////////////////
      var fraction = 0;
      var local_fraction = 0;
      var state = data.state;

      if ( inCollect(state) ) {
        local_fraction = data.num_files > 0 ? data.num_files_processed / data.num_files : 0;
        fraction = PARTIALLEN * local_fraction;

      } else if ( inCreateSnapshot(state) ) {
        local_fraction = data.num_snapshots > 0 ? data.num_snapshots_created / data.num_snapshots : 0;
        fraction = PARTIALLEN * (1 + local_fraction);

      } else if ( inPrecalculate(state) ) {
        local_fraction = data.num_snapshots > 0 ? data.num_snapshots_processed / data.num_snapshots_created : 0;
        fraction =  PARTIALLEN * (2 + local_fraction);

      } else if ( inError(state) ) {
        throw new Error('Push processes ended with error: ' + data.error_message);

      } else {
        throw new Error('Illegal state: ' + state + ' in push_proc');
      }

      //////////////// Update the UI //////////////////////////////
      var files_bar = document.getElementById('sas-progress-bar');
      var percent = 100 * fraction;
      percent = percent.toFixed(1);
      var border_width = Math.min( 17, 20 * (1 - fraction) );
      files_bar.innerHTML = percent + '%';
      var right_border = 'border-right: ' + border_width + 'rem solid #9fbb9f';
      files_bar.setAttribute('style', right_border);

      if (data.state !== 'done') {
        setTimeout( sas.updatePushState, 10000 );
      }
    }
  );
};
