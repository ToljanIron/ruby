/*global angular, JST, $compile, unused */
angular.module('workships.directives').directive('measurementGauge', function (tabService, $timeout) {
  'use strict';
  return {
    restrict: 'E',
    template:  JST['v2/measurement_gauge'](),
    scope: {
      minRange: '=',
      maxRange: '=',
      minRangeWanted: '=',
      maxRangeWanted: '=',
      backgroundColor: '=',
      wantedAreaColor: '=',
      companyMetricId: '=',
      titleName: '=',
      rate: '=',
      radius: '=',
      image: '=',
    },
    link: function (scope) {
      var prectenge = ((scope.maxRange - scope.minRange) / 100);
      scope.beta = { angle: (scope.maxRangeWanted - scope.minRange) / prectenge * 180 / 100};
      scope.alpha = { angle: (scope.minRangeWanted - scope.minRange) / prectenge  * 180 / 100};
      scope.getAreaSize = function () {
        var ratio = (scope.maxRangeWanted - scope.minRangeWanted) / (scope.maxRange - scope.minRange);
        return Math.PI * scope.radius * ratio + ' ' + Math.PI * 2 * scope.radius;
      };
      scope.getRectangleSize = function () {
        var rect = scope.alpha.angle + 180;
        return ('rotateZ(' + rect + 'deg)');
      };
      var getTextLocation = function (angle) {
        var x, y;
        var radius = scope.radius + 18;
        var radian = angle / 180 * Math.PI;
        if (radian < Math.PI / 2) {
          x = -radius * Math.cos(radian);
          y = -radius * Math.sin(radian);
        } else {
          x = radius * Math.cos(Math.PI - radian);
          y = -radius * Math.sin(Math.PI - radian);
        }
        return ('translate3d(' + x + 'px' + ', ' + y + 'px, 0px)');
      };
      scope.getStyleDiel = function () {
        var width = 0.2 * scope.radius;
        var style = {};
        style.width = width + 'px';
        style.height = scope.radius + 'px';
        style.bottom = '0px';
        style.position = 'absolute';
        style.left = (scope.radius - (width / 2)) + 'px';
        style.transition = 'transform 1s ease';
        style['transition-delay'] = '1s';
        style['transform-origin'] = 'bottom';
        style.transform =  scope.getGraugeHand();
        style['-ms-transform'] = scope.getGraugeHandExplorer();
        return style;
      };
      scope.getGraugeHand = function () {
        var ratio = (scope.rate - scope.minRange) / (scope.maxRange - scope.minRange);
        // var grague_hand_rect = -90 + (scope.rate) * (scope.maxRange - scope.minRange) / 180;
        var grague_hand_rect = -90 + ratio * 180;
        if (isNaN(grague_hand_rect) && !scope.companyMetricId) { grague_hand_rect = 0; }
        return ('rotateZ(' + grague_hand_rect + 'deg)');
      };

      scope.getGraugeHandExplorer = function () {
        var ratio = (scope.rate) / (scope.maxRange - scope.minRange);
        var grague_hand_rect = -90 + ratio * 180;
        return ('rotateZ(' + grague_hand_rect + 'deg)');
      };

      scope.getRateInPrectenge = function () {
        return scope.rate;
      };

      scope.getifNaN = function () {
        if(scope.companyMetricId ===930){
          console.log('rate: '+scope.rate);
        }
        
        // if (isNaN(scope.rate) && !scope.companyMetricId) {
          if (isNaN(scope.rate)) {
            return {'opacity': '0.45'};
          }
          return {};
      };
      scope.isEmptyGauge = function () {
        return isNaN(scope.rate) && !scope.companyMetricId;
      };

      scope.returnTextInsteadOf = function () {
        if (isNaN(scope.getRateInPrectenge())) {
          return 'The group does not meet the requirement for a gauge of this measurement';
        }
        return '';
      };

      scope.getStyleOfWanted = function (alpha) {
        var style = {};
        var size = 20;
        if (alpha === 0 || alpha === 180) {
          style.display =  'none';
          return style;
        }
        style.position = 'absolute';
        style.width = size + 'px';
        style.height = '0px';
        style.left = scope.radius - size / 2 + 'px';
        style.bottom = '0px';
        style['text-align'] = 'center';
        if (alpha) {
          style.transform = getTextLocation(alpha);
        }
        return style;
      };

      scope.getPrectengeStyle = function () {
        var style = {};
        var size = 46;
        style.position = 'absolute';
        style.bottom = -30 + 'px';
        style.color = scope.wantedAreaColor;
        style['font-size'] = 18 + 'px';
        style['font-weight'] = 400;
        style['text-align'] = 'left';
        style.left = scope.radius - size / 2 + 'px';
        return style;
      };
      scope.getSizeOfMinWanted = function () {
        var y, x, size, angle_of_min_wanted = ((scope.minRangeWanted - scope.minRange) / prectenge) * 180 / 100;
        x =  scope.radius * Math.cos(angle_of_min_wanted);
        y =  scope.radius * Math.sin(angle_of_min_wanted);
        size = { left: x + 'px', bottom: y + 'px' };
        return size;
      };
      scope.getLeftGauge = function () {
        return scope.radius + 'px';
      };

      scope.getCursorType = function () {
        if (tabService.current_tab === 'Dashboard') {
          return 'pointer';
        }
        return 'initial';
      };

      scope.goToTab = function (tab) {
        if (tabService.current_tab === 'Dashboard') {
          tabService.selectTab(tab);
        }
      };

      scope.$watch('[maxRangeWanted,minRangeWanted]', function (n) {
        if (!n) { return; }
        scope.chart_background = true;
        $timeout(function () {
          scope.chart_background = false;
        }, 0);
        prectenge = ((scope.maxRange - scope.minRange) / 100);
        scope.beta = { angle: (scope.maxRangeWanted - scope.minRange) / prectenge * 180 / 100};
        scope.alpha = { angle: (scope.minRangeWanted - scope.minRange) / prectenge  * 180 / 100};
      }, true);
    },
  };
});
