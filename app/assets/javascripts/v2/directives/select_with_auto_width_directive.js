/*globals angular, _, document, console */
angular.module('workships.directives').directive('autoWidth', function () {
  'use strict';
  return {
    scope: {
      selectInx: '='
    },
    link: function (scope, element) {
      scope.select = element[0];

      function changeWidth(select) {
        var ruler = document.createElement('div');
        document.body.appendChild(ruler);
        ruler.className = 'ruler';
        var options = select.options[select.selectedIndex];
        var text = options !== undefined ? options.text : '';
        ruler.innerHTML = text;
        select.style.width = ruler.offsetWidth + 22 + 'px';
        document.body.removeChild(ruler);
      }

      scope.$watchCollection('select.options', function (options) {
        if (!options || !options[scope.select.selectedIndex] || options[scope.select.selectedIndex].text === '') { return; }
        changeWidth(scope.select);
      });

      scope.$watch('select.selectedIndex', function (index) {
        scope.selectInx = index;
        if (index === undefined) { return; }
        changeWidth(scope.select);
      });
    }
  };
});
