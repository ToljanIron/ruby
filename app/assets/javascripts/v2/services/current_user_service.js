/*globals angular, _*/
angular.module('workships.services').factory('currentUserService', function () {
  'use strict';
  var ADMIN =  'admin';
  var currentUser;
  var shouldDisplayEmails = false;

  return {
    setCurrentUser: function (user) {
      currentUser = user;
    },
    getCurrentUser: function () {
      return currentUser;
    },
    isCurrentUserAdmin: function () {
      return currentUser && currentUser.role === ADMIN;
    },
    setShouldDisplayEmails: function(shoud_display) {
      shouldDisplayEmails = shoud_display;
    },
    getShouldDisplayEmails: function() {
      return shouldDisplayEmails;
    }
  };
});
