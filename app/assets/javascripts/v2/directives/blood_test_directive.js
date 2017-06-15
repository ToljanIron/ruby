/*globals angular, JST */

angular.module('workships.directives').directive('bloodTest', function () {

  'use strict';

  return {

    scope: {
      text: '@',
      name: '=',
      min: '=',
      max: '=',
      minvalidValue: '=',
      maxvalidValue: '=',
      value: '=',
      color: '=',
      validColor: '=',
    },
    template: JST["v2/blood_test"](),

    link: function (scope) {
      var SIZE = 285;
      scope.showBloodTestToolTip = false;
      scope.getValidSize = function (color, minvalidValue, maxvalidValue) {
        var style = {};
        style['background-color'] = color;
        var rel_valid_width = (maxvalidValue - minvalidValue) / (scope.max - scope.min);
        style.width = rel_valid_width * SIZE + 'px';

        var rel_left_pos = (minvalidValue - scope.min) / (scope.max - scope.min);
        style.left = (rel_left_pos * SIZE) + 'px';
        return style;
      };
      scope.getTextAreaStyle = function (color) {
        var style = {};
        style.background = 'repeating-linear-gradient(-55deg ,' + color +  ' ,white 5px, white 0px, white 0px)';
        return style;
      };
      scope.getValuePosition = function (value, color) {
        var style = {};
        style['background-color'] = color;
        var rel_niddle_pos = (value - scope.min) / (scope.max - scope.min);
        style.left = (rel_niddle_pos * SIZE) + 'px';
        return style;
      };
    }
  };
});

