/*globals angular, document */
angular.module('workships.directives').directive('slotMachineDirective', function () {
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
    template: '<div style="display: none; height: {{height}}px; overflow: hidden;">' +
      '  <div ng-transclude style="transform: translate(0, 0)"></div>' +
      '</div>',
    scope: {
      height: '@',
      value: '=?',
      onSelectClass: '@?',
      onSelect: '&?',
    },
    link: function postLink(scope, elem) {
      var dragging = false;
      var origY = -1;
      var initialTranslation = 0;
      var currentTranslation = 0;
      var translationAtDragStart = 0;
      var transcludeElem;
      var contentElems;
      var contentElemHeight;

      angular.element(document).ready(function () {
        transcludeElem = angular.element(elem.children()[0]);
        contentElems = transcludeElem.children();
        if (contentElems.length === 0) {
          return;
        }
        var currContentElem = angular.element(contentElems[0]);
        currContentElem.addClass(scope.onSelectClass);
        scope.value = scope.value || String(currContentElem.attr('value'));
        elem.css('display', 'block');
        contentElemHeight = currContentElem[0].getBoundingClientRect().bottom - currContentElem[0].getBoundingClientRect().top;
        currentTranslation = scope.height / 2 - contentElemHeight / 2;
        initialTranslation = currentTranslation;
        scope.$apply();
      });

      scope.onDragStart = function (e) {
        dragging = true;
        origY = e.y || e.targetTouches[0].pageY;
        translationAtDragStart = currentTranslation;
      };

      scope.onDragEnd = function () {
        if (!dragging) {
          return;
        }
        currentTranslation = translationAtDragStart;
        transformElemOnY(transcludeElem, currentTranslation);
        dragging = false;
        origY = -1;
      };

      scope.onDrag = function (e) {
        if (!dragging) {
          return;
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

        if (direction < 0 && i < (contentElems.length - 1)) {
          nextContentElem = contentElems[i + 1];
        }
        if (direction > 0 && i > 0) {
          nextContentElem = contentElems[i - 1];
        }
        if (!nextContentElem) {
          return;
        }

        if (Math.abs(origY - newY) <= contentElemHeight / 2) {
          currentTranslation += direction;
          transformElemOnY(transcludeElem, currentTranslation);
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

      scope.$watch('value', function () {
        setTimeout(function () {
          var i;
          var currContentElem;
          var accumHeight = 0;
          if (!transcludeElem) {
            return;
          }
          contentElems = transcludeElem.children();

          for (i = 0; i < contentElems.length; ++i) {
            currContentElem = contentElems[i];
            angular.element(currContentElem).removeClass(scope.onSelectClass);
          }
          for (i = 0; i < contentElems.length; ++i) {
            currContentElem = contentElems[i];
            if (String(angular.element(currContentElem).attr('value')) === String(scope.value)) {
              break;
            }
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
});
