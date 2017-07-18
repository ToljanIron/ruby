/*globals angular, console, _*/

angular.module('workships.services').factory('overlayBlockerService',
  function () {
    'use strict';

    // The Blocke z-index is 100000, so if you want to put somthing in front of the blocker you should set its z-index higher

    var BLOCK = false;
    var obs = {};
    var elements = [
      {
        name: 'update_filter_menu',
        displayed: false
      }, {
        name: 'company_select',
        displayed: false
      }, {
        name: 'report-modal-window',
        displayed: false
      }, {
        name: 'report-modal-window-directory',
        displayed: false
      }, {
        name: 'layout-menu',
        displayed: false
      }, {
        name: 'snapshot-menu',
        displayed: false
      }, {
        name: 'preset-menu',
        displayed: false
      }, {
        name: 'logout-menu-admin',
        displayed: false
      }, {
        name: 'logout-menu-hr',
        displayed: false
      }, {
        name: 'black-arrow',
        displayed: false
      }, {
        name: 'resend_all_modal',
        displayed: false
      }, {
        name: 'submit_results_modal',
        displayed: false
      }, {
        name: 'resend_emp_modal',
        displayed: false
      }, {
        name: 'reset_emp_quest_modal',
        displayed: false
      }, {
        name: 'choose_layer_filter',
        displayed: false
      }
    ];

    obs.mock_with = function (example_elements) {
      elements = example_elements;
    };

    obs.block = function (elem) {
      BLOCK = true;
      if (elem) {
        _.forEach(elements, function (element) {
          if (element.name === elem) {
            element.displayed = true;
          } else {
            element.displayed = false;
          }
        });
      }
    };

    obs.unblock = function () {
      BLOCK = false;
      _.forEach(elements, function (element) {
        element.displayed = false;
      });
    };

    obs.isBlocked = function () {
      return BLOCK;
    };

    obs.isElemDisplayed = function (elem) {
      var displayed_element;
      displayed_element = _.find(elements, function (element) {
        return element.name === elem;
      });
      if (displayed_element.displayed) {
        return true;
      }
      return false;
    };

    return obs;
  });
