/*globals angular, document */

angular.module('workships-mobile.directives').directive('slotMachineDirective', ['$timeout', function ($timeout) {
  'use strict';

  function transformElemOnY(elem, offset) {
    elem.css('-webkit-transform', 'translate(0, ' + offset + 'px)');
    elem.css('-webkit-transition', '0.3s');
    elem.css('transform', 'translate(0, ' + offset + 'px)');
    elem.css('transition', '0.3s');
  }

  return {
    restrict: 'E',
    transclude: true,
    replace: true,
    template: '<div style="margin-top: 170px; display: none; height: {{height - 170}}px; overflow: hidden;">' +
      '  <div ng-transclude style="transform: translate(0, 0)"></div>' +
      '</div>',
    scope: {
      height: '@',
      value: '=?',
      onSelectClass: '@?',
      onSelect: '&?',
      swipe: '=',
      loaded: '=',
      loadMore: '='
    },
// height: calc(100% - 170px);
    link: function postLink(scope, elem, attrs) {
      var dragging = false;
      var origY = -1;
      var initialTranslation = 0;
      var currentTranslation = 0;
      var translationAtDragStart = 0;
      var transcludeElem;
      var contentElems;
      var contentElemHeight;
      var origX;


      scope.initDirective = function () {
        transcludeElem = angular.element(elem.children()[0]);
        contentElems = transcludeElem.children();
        if (contentElems.length === 0) {
          return;
        }
        var currContentElem = angular.element(contentElems[0]);
        currContentElem.addClass(scope.onSelectClass);
        if (scope.value === -1 || !scope.value) {
          scope.value = (currContentElem.attr('value'));
        }
        elem.css('display', 'block');
        contentElemHeight = currContentElem[0].getBoundingClientRect().bottom - currContentElem[0].getBoundingClientRect().top;
        currentTranslation = scope.height / 2 - contentElemHeight / 2;
        initialTranslation = currentTranslation;
        scope.$apply();
      };

      scope.onDragStart = function (e) {
        var currContentElem;
        var i;
        for (i = 0; i < contentElems.length; ++i) {
          currContentElem = contentElems[i];
          if (String(angular.element(currContentElem).attr('value')) === String(scope.value)) {
            if (contentElems.length - i < 4) {
              scope.loadMore();
            }
            break;
          }
        }

        var like = currContentElem.getElementsByClassName("mobile-like-btn")[0];
        var dislike = currContentElem.getElementsByClassName("mobile-dislike-btn")[0];

        dragging = true;
        $timeout(function() {
          scope.swipe.left = false;
          scope.swipe.right = false;
        }, 0);

        if ((e.targetTouches && e.targetTouches[0].target.className === 'mobile-like-btn') || (e.targetTouches && e.targetTouches[0].target.className === 'v-icon')) {
          $timeout(function() {
          angular.element(like).triggerHandler('click');
          }, 500);
        }

        else if ((e.targetTouches && e.targetTouches[0].target.className === 'mobile-dislike-btn') || (e.targetTouches && e.targetTouches[0].target.className === 'x-icon')) {
          $timeout(function() {
          angular.element(dislike).triggerHandler('click');
          }, 500);
        }


        origY = e.y || e.targetTouches[0].pageY;
        if (e.targetTouches) {
          origX = e.targetTouches[0].pageX;
        }
        translationAtDragStart = currentTranslation;
      };

      scope.onDragEnd = function () {
        if (!dragging) {
          return;
        }
        $timeout(function() {
          scope.swipe.left = false;
          scope.swipe.right = false;
        }, 1000);
        currentTranslation = translationAtDragStart;
        transformElemOnY(transcludeElem, currentTranslation);
        dragging = false;
        origY = -1;
      };

      scope.onDrag = function (e) {
        e.preventDefault();
        if (!dragging) {
          return;
        }

        if ((e.targetTouches && (origX - e.targetTouches[0].pageX) > 300) || e.targetTouches[0].target.className === 'x-icon') {
          $timeout(function() {
          scope.swipe.left = true;
          }, 0);
        }

        else if ((e.targetTouches && (origX - e.targetTouches[0].pageX) < -300) || e.targetTouches[0].target.className === 'v-icon') {
          $timeout(function() {
          scope.swipe.right = true;
          }, 0);
        }

        var newY = e.y || e.targetTouches[0].pageY; 
        contentElems = transcludeElem.children();
        var direction = (origY - newY) < 0 ? 1 : -1;
        var currContentElem;
        var nextContentElem;
        var i;

        for (i = 0; i < contentElems.length; ++i) {
          currContentElem = contentElems[i];
          if (String(angular.element(currContentElem).attr('value')) === String(scope.value)) {
            break;
          }
        }

        if (scope.swipe.right || scope.swipe.left) {
          var employee_item = currContentElem.getElementsByClassName("employee-item")[0];
          var like = currContentElem.getElementsByClassName("mobile-like-btn")[0];
          var v_icon = currContentElem.getElementsByClassName("v-icon")[0];
          var dislike = currContentElem.getElementsByClassName("mobile-dislike-btn")[0];
          var x_icon = currContentElem.getElementsByClassName("x-icon")[0];
          var swipe_direction;
          if (scope.swipe.right) {
            swipe_direction = 'swipe-right';
            angular.element(like).addClass('activated');
            angular.element(v_icon).addClass('activated');
          } else if (scope.swipe.left) {
            swipe_direction = 'swipe-left';
            angular.element(dislike).addClass('activated');
            angular.element(x_icon).addClass('activated');
          }
          angular.element(employee_item).addClass(swipe_direction);
          if (scope.swipe.right) {
            $timeout(function() {
              angular.element(like).triggerHandler('click');
            }, 500);
          } else if (scope.swipe.left) {
            $timeout(function() {
              angular.element(dislike).triggerHandler('click');
            }, 500);
          }
          return;
        }

        if (direction < 0 && i < (contentElems.length - 1)) { nextContentElem = contentElems[i + 1]; }
        if (direction > 0 && i > 0) { nextContentElem = contentElems[i - 1]; }
        if (!nextContentElem) { return; }

        if (Math.abs(origY - newY) <= contentElemHeight / 2) {
          currentTranslation += direction;
          // transformElemOnY(transcludeElem, currentTranslation);
          return;
        }

        angular.element(currContentElem).removeClass(scope.onSelectClass);
        angular.element(nextContentElem).addClass(scope.onSelectClass);
        currContentElem = nextContentElem;
        scope.value = String(angular.element(currContentElem).attr('value'));
        currentTranslation = translationAtDragStart + (direction * contentElemHeight);
        transformElemOnY(transcludeElem, currentTranslation);
        dragging = false;
        origY = -1;
        setTimeout(function () {
          scope.$apply();
        }, 0);
      };

      var touchStartHandler = elem.bind('touchstart', scope.onDragStart);
      var mouseDownHandler = elem.bind('mousedown', scope.onDragStart);
      var touchEndHandler = elem.bind('touchend', scope.onDragEnd);
      var mouseUpHandler = elem.bind('mouseup', scope.onDragEnd);
      var touchMoveHandler = elem.bind('touchmove', scope.onDrag);
      var mouseMoveHandler = elem.bind('mousemove', scope.onDrag);

      scope.$on('destroy', function () {
        elem.unbind('touchstart', touchStartHandler);
        elem.unbind('mousedown', mouseDownHandler);
        elem.unbind('touchend', touchEndHandler);
        elem.unbind('mouseup', mouseUpHandler);
        elem.unbind('touchmove', touchMoveHandler);
        elem.unbind('mousemove', mouseMoveHandler);
      });

      scope.$watch('loaded', function (new_val, old_val) {
        if (angular.equals(new_val, old_val)) { return; }
        if (new_val) {
          setTimeout(scope.initDirective, 0);
        }
      }, true);

      scope.$watch('value', function () {
        setTimeout(function () {
          var i;
          var currContentElem;
          var accumHeight = 0;
          if (!transcludeElem) { return; }
          contentElems = transcludeElem.children();

          for (i = 0; i < contentElems.length; ++i) {
            currContentElem = contentElems[i];
            angular.element(currContentElem).removeClass(scope.onSelectClass);
          }
          for (i = 0; i < contentElems.length; ++i) {
            currContentElem = contentElems[i];
            if (String(angular.element(currContentElem).attr('value')) === String(scope.value)) { break; }
            accumHeight += currContentElem.getBoundingClientRect().bottom - currContentElem.getBoundingClientRect().top;
          }
          if (currContentElem) {
            currentTranslation = initialTranslation - accumHeight;
            transformElemOnY(transcludeElem, currentTranslation);
            setTimeout(function () {
              angular.element(currContentElem).addClass(scope.onSelectClass);
            }, 100);
          }
        }, 0);
      }, true);
    },
  };
}]);
