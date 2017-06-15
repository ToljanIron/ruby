/*globals angular, document, window, localStorage, _ */
angular.module('workships.services').factory('tokenService', ['ajaxService', '$q',
  function (ajaxService, $q) {
    'use strict';
    // var self = this;
    var tokenService = {
      tokenValid: false,
    };

    tokenService.check = function () {
      return $q(function (resolve, reject) {
        var urlArr = window.location.href.split(/\?|\=/);
        var set_password_token = urlArr[1];
        ajaxService.getPromise('POST', '/verify_password_token', { token: set_password_token }).then(
          function (response) {
            resolve(response);
          },
          function (msg) {
            reject(msg);
          }
        );
      });
    };
    return tokenService;
  }]);
