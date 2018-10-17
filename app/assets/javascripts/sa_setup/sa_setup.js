/*globals $, document */
var sas = {};

sas.updatePushState = function() {

  $.get("/sa_setup/get_push_state", {},
    function(data, status) {
      if (status !== 'success') {
        console.error("Error in get_push_state: ", status);
      }

      // console.log( data );

      // Number of files
      document.getElementById('sas-files-num').innerHTML = data.num_files;
      var files_fraction = data.num_files > 0 ? data.num_files_processed / data.num_files : 0;
      var files_percent = 100 * files_fraction;
      var border_width = Math.min( 16, 20 * (1 - files_fraction) );
      var files_bar = document.getElementById('sas-files-bar');
      files_bar.innerHTML = files_percent + '%';
      var right_border = 'border-right: ' + border_width + 'rem solid #9fbb9f';
      files_bar.setAttribute('style', right_border);

      // Snapshots created
      document.getElementById('sas-snp-created-num').innerHTML = data.num_snapshots;
      var snpcre_fraction = data.num_snapshots > 0 ? data.num_snapshots_created / data.num_snapshots : 0;
      var snpcre_percent = Math.round(100 * snpcre_fraction);
      border_width = Math.min( 16, 20 * (1 - snpcre_fraction) );
      var snpcre_bar = document.getElementById('sas-snp-created-bar');
      snpcre_bar.innerHTML = snpcre_percent + '%';
      right_border = 'border-right: ' + border_width + 'rem solid #9fbb9f';
      snpcre_bar.setAttribute('style', right_border);

      // Snapshots processed
      document.getElementById('sas-snp-proced-num').innerHTML = data.num_snapshots_processed;
      var snpprc_fraction = data.num_snapshots > 0 ? data.num_snapshots_processed / data.num_snapshots : 0;
      var snpprc_percent = Math.round(100 * snpprc_fraction);
      border_width = Math.min( 16, 20 * (1 - snpprc_fraction) );
      var snpprc_bar = document.getElementById('sas-snp-proced-bar');
      snpprc_bar.innerHTML = snpprc_percent + '%';
      right_border = 'border-right: ' + border_width + 'rem solid #9fbb9f';
      snpprc_bar.setAttribute('style', right_border);

      if (data.state !== 'done') {
        setTimeout( sas.updatePushState, 10000 );
      }
    }
  );
};
