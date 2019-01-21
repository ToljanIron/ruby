/*globals $, document */
var sas = {};

sas.updatePushState = function() {

  $.get("/sa_setup/get_push_state", {},
    function(data, status) {
      if (status !== 'success') {
        console.error("Error in get_push_state: ", status);
      }

      if (data.status === 'error') {
        console.error('Error in historical collection: ', data.error_msg);
      }

      //////////////// Update the UI //////////////////////////////
      var files_bar = document.getElementById('sas-progress-bar');
      var percent = data.percent_complete;
      var border_width = Math.min( 17, 20 * (1 - (percent / 100)) );
      files_bar.innerHTML = percent + '%';
      var right_border = 'border-right: ' + border_width + 'rem solid #9fbb9f';
      files_bar.setAttribute('style', right_border);

      if (data.state !== 'done') {
        setTimeout( sas.updatePushState, 10000 );
      }
    }
  );
};
