/*globals _, angular, unused, window, document, localStorage, $, alert */

angular.module('workships.services').factory('utilService', function (currentUserService) {
  'use strict';

  var util = {};
  util.bubble = {};
  var MONTH = [];
  MONTH[0] = "Jan";
  MONTH[1] = "Feb";
  MONTH[2] = "Mar";
  MONTH[3] = "Apr";
  MONTH[4] = "May";
  MONTH[5] = "Jun";
  MONTH[6] = "Jul";
  MONTH[7] = "Aug";
  MONTH[8] = "Sep";
  MONTH[9] = "Oct";
  MONTH[10] = "Nov";
  MONTH[11] = "Dec";

  function capitalyze(str) {
    return str.replace(/\w\S*/g, function (txt) {
      return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
    });
  }

  util.dateToMonthAndYear = function (date) {
    var res = {};
    var str = date.toString().split(' ');
    res.month = MONTH[date.getMonth()];
    res.year = str[3];
    return res;
  };

  util.capitaliseAndTrimFirstWord = function (str) {
    var s = str.split('_')[0];
    return capitalyze(s);
  };

  util.splitAndCapitalise = function (str) {
    var strArr = str.split('_');
    var capArr = _.map(strArr, function (s) {
      return capitalyze(s);
    });
    return capArr.join(' ');
  };

  util.spiltBeforeDash = function (str) {
    return str.split('-')[0];
  };

  util.getObjKeys = function (obj) {
    if (obj) {
      return Object.keys(obj);
    }
    return null;
  };

  util.changeObjectKeys = function (obj, old_keys, new_keys) {
    var i, val;
    for (i = 0; i < old_keys.length; i++) {
      val = obj[old_keys[i]];
      delete obj[old_keys[i]];
      obj[new_keys[i]] = val;
    }
  };

  util.displayFormattedTitle = function (str) {
    // removing _ and capitalyzing
    var new_str;
    new_str = str.replace(/_/g, ' ');
    new_str = capitalyze(new_str);
    return new_str;
  };

  util.setPositionToBubble = function (left_size, index) {
    util.bubble[index] = parseInt(left_size, 10);
  };
  util.getPositionToBubble = function () {
    return util.bubble;
  };

  // When the application language is not English we may
  // wish to display the email instead of a name so data analysis
  // will be easier for people not using the local language
  util.employeeDisplayName = function(name, email, id) {
    var label = name;
    if (currentUserService.getShouldDisplayEmails() ) {
      if (id !== undefined) {
        label = email.split('@')[0] + '-' + id;
      } else {
        label = email.split('@')[0];
      }
    }
    return label;
  };

  return util;
});
