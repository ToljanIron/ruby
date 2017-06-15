/*globals angular, _*/

angular.module('workships.services').factory('passwordsService', function () {
  'use strict';

  var passwordsService = {};

  passwordsService.verifyPasswords = function (password, password_confirmation) {
    var regex = /(?=^.{6,}$)((?!.*\s)(?=.*[A-Z])(?=.*[a-z]))((?=(.*\d){1,})(?=(.*\W){1,}))^.*$/;
    var p1 = password;
    var p2 = password_confirmation;
    if (regex.test(p1) && (p1 === p2)) {
      return true;
    }
    return false;
  };

  return passwordsService;
});