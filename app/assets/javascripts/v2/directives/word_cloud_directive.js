/*global angular, JST, $, _, unused */

angular.module('workships.directives').directive('wordCloud', function () {
  'use strict';
  return {
    template: "<div id='wordcloud' class='wordcloud_container'> </div>",
    scope: {
      words: '=',
      color: '='

    },
    link: function (scope) {
      scope.init = function () {
        var arr = [];
        var res = scope.words;
        _.each(res, function (value, key) {
          arr.push({
            text: key,
            weight: value,
          });
        });
        if (arr.length > 0) {
          $("#wordcloud").jQCloud(arr);
        }
      };

      scope.$watch('words', function (n) {
        if (n === null) { return true; }
        _.each($('#wordcloud').find("span"), function (span) {
          $('#' + span.id).remove();
        });
        scope.init();
      }, true);
    }
  };
});
