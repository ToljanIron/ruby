// THIS FILE IS WIERD. CAN WE DELETE IT??

 /*global angular, document, unused */
// angular.module('workships.directives').directive('mobileScrollToDirective', function ($document) {
//   'use strict';
//   return {
//     scope: {
//       scrollId: '@',
//       currentScroll: '@',
//       offsetScroll: '@'
//     },
//     link: function (scope, elem) {
//       scope.$watch('currentScroll', function (new_val) {
//         if (scope.scrollId === new_val) {
//           var from_top = elem[0].getBoundingClientRect().top;
//           var current_body_top = document.getElementsByTagName('body')[0].getBoundingClientRect().top;
//           if (from_top) {
//             //document.getElementsByTagName('body')[0].scrollTop = -current_body_top + from_top - (scope.offsetScroll / 1 || 0);
//             //var ele = angular.element(document.getElementsByTagName('body')[0]);
//             //$document.scrollToElement(ele, (scope.offsetScroll / 1 || 0), 2000);
//             $document.scrollTop(-current_body_top + from_top - (scope.offsetScroll / 1 || 0), 1000).then(function () {
//             });
//           }
//         }
//       }, true);
//     }

//   };
// });
