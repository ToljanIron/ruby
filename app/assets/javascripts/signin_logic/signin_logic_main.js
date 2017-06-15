/*globals angular, document */
angular.module('workships').config(function ($httpProvider) {
  'use strict';
  var csrf_token = document.getElementsByName('csrf-token')[0].content;
  $httpProvider.defaults.headers.post['X-CSRF-Token'] = csrf_token;
  $httpProvider.defaults.headers.put['X-CSRF-Token'] = csrf_token;
  $httpProvider.defaults.headers.patch['X-CSRF-Token'] = csrf_token;
});

angular.element(document).ready(function () {
  'use strict';
  angular.bootstrap(document, ['workships']);
});