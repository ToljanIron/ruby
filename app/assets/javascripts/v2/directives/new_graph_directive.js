/*globals angular, KeyLines, $, window, setTimeout, _ */
angular.module('workships.directives')
  .directive('newGraph', function (graphService, $window, $log, $timeout, utilService, analyzeMediator) {
    'use strict';

    return {
      restrict: 'E',
      scope: true,
      template: '<div id="chart-element"></div>',
      link: function postLink(scope) {
        // Init ============================================================================================

        $log.debug("In postLink()");
        scope.graphService = graphService;

        var init = false;
        // canvas sizing
        var padding = 1,
            handleHeight = 50,
            allOthersHeight = 225;
        // types
        var SINGLE = 'single',
            COMBO = 'combo',
            OVERLAY_ENTITY = 'overlay_entity';
        // node sizes
        var NODE_INTERVAL = [{ min: -1, max: 20, size: 1 }, { min: 20, max: 40, size: 1.5 }, { min: 40, max: 60, size: 2 }, { min: 60, max: 80, size: 2.5 }, { min: 80, max: 99, size: 3 }, { min: 99, max: 1000, size: 4.5 }],
            EDGE_INTERVAL = [{ min: 0, max: 1, size: 1.5 }, { min: 1, max: 2, size: 6 }, { min: 2, max: 3, size: 9 }, { min: 3, max: 4, size: 13.5 }, { min: 4, max: 5, size: 20 }, { min: 5, max: 6, size: 30 }];
        // colors
        var LINK_COLOR = '#f2d4d2';

        // chart sizing functions
        function zoomChart(chart) {
          $timeout(function () {
            chart.zoom('fit', {
              animate: true,
              time: 500
            });
          });
        }

        function setChartSize() {
          if (!scope.chart) { return; }
          allOthersHeight = 130;
          var sidebarWidth = scope.showMenu ? 244 : 0;
          var newWidth = $window.innerWidth - sidebarWidth - 10;
          var newHeight = $window.innerHeight - allOthersHeight;
          KeyLines.setSize('chart-element', newWidth - padding, newHeight - handleHeight - 2 * padding);
          zoomChart(scope.chart);
        }

        // attributes helpers
        function comboId(node_id) {
          return COMBO + String(node_id);
        }

        function overlayEntityId(node_id) {
          return OVERLAY_ENTITY + String(node_id);
        }

        function chartNodeId(node) {
          if (node.type === SINGLE) {
            return String(node.id);
          }
          if (node.type === OVERLAY_ENTITY) {
            return overlayEntityId(node.id);
          }
          return comboId(node.id);
        }

        function chartLinkId(link) {
          var from_type = '';
          var to_type = '';
          if (link.from_type !== SINGLE) { from_type = link.from_type; }
          if (link.to_type !== SINGLE) { to_type = link.to_type; }
          return from_type + String(link.from_id) + 'to' + to_type + String(link.to_id);
        }

        function chartItemId(item) {
          if (item.hasOwnProperty('from_id') && item.hasOwnProperty('to_id')) {
            return chartLinkId(item);
          }
          if (item.hasOwnProperty('type')) {
            return chartNodeId(item);
          }
        }

        function nodeAttributes(node) {
          var size, icon, label, halo;
          var data = {};
          if (node.type === SINGLE) {
            icon = 'assets/analyze_color/' + (node.gender || 'male') + '_employee.svg';
            label = utilService.employeeDisplayName(node.first_name, node.email, node.id);
            data = {
              type: SINGLE,
              id: node.id
            };
          } else if (node.type === OVERLAY_ENTITY) {
            icon = node.image_url || 'assets/analyze_color/empty.png';
            label = node.name;
            // shape = 'box';
            data = {
              type: OVERLAY_ENTITY,
              id: node.id
            };
          } else {
            icon = node.image_url || 'assets/analyze_color/group.svg';
            label = node.sons_count ? node.name + ' (' + node.sons_count + ')' : node.name;
            data = {
              type: COMBO,
              id: node.id
            };
          }
          size = _.find(NODE_INTERVAL, function (interval) {
            if (node.combo_type === 'overlay_entity') { return { size: 1 }; }
            return node.rate >= interval.min && node.rate <= interval.max;
          }).size;
          if (node.highlighted) { halo = { c: node.highlighted, w: 10, r: 50}; }
          var result = {
            type: 'node',
            id: chartNodeId(node),
            e: size,
            c: node.color || '#b3b3b3',
            bg: node.hide,
            t: label,
            u: icon,
            d: data,
            ha0: halo //,            sh: shape || 'circle'
          };
          if (node.x && node.y) {
            result.x = node.x;
            result.y = node.y;
          }
          return result;
        }

        function linkAttributes(link) {
          var origin_id, destination_id;
          origin_id = link.from_type === SINGLE ? link.from_id : (link.from_type === COMBO ? comboId(link.from_id) : overlayEntityId(link.from_id));
          destination_id = link.to_type === SINGLE ? link.to_id : (link.to_type === COMBO ? comboId(link.to_id) : overlayEntityId(link.to_id));
          var a1 = !!link.way_arr;
          var size = _.find(EDGE_INTERVAL, function (interval) {
            return link.weight >= interval.min && link.weight <= interval.max;
          }).size;
          return {
            type: 'link',
            id: origin_id + 'to' + destination_id,
            id1: origin_id,
            id2: destination_id,
            w: size,
            c: link.color || LINK_COLOR,
            bg: link.hide,
            a1: a1,
            a2: true
          };
        }

        function itemAttributes(item) {
          if (item.hasOwnProperty('from_id') && item.hasOwnProperty('to_id')) {
            return linkAttributes(item);
          }
          if (item.hasOwnProperty('type')) {
            return nodeAttributes(item);
          }
        }

        // helpers
        function bindEvent(chart, event, item_handler) {
          chart.bind(event, function (id, x, y) {
            var item = chart.getItem(id);
            if (item && item.type === 'node') {
              item_handler(item.d.id, item.d.type, x, y);
            } else {
              item_handler();
            }
            scope.$apply();
            return true;
          });
        }

        function ping(chart, node, color) {
          if (!node || !node.id || !node.type) { return; }
          chart.ping(chartNodeId(node), { c: color, repeat: 3 });
        }

        function setLayout(chart) {
          if (graphService.getLayout().layout === 'advanced') { return; }
          chart.layout('standard', { tightness: 1 }, function () {
            ping(chart, graphService.getSearch(), 'green');
            ping(chart, graphService.getIsolated());
          });
        }

        // init keylines graph
        function initGraph(loadChart) {
          $log.debug("In initGraph()");
          KeyLines.create([{ id: 'chart-element', type: 'chart' }], loadChart);
        }

        function initItems() {
          $log.debug("In initItems()");
          var nodes = graphService.getNodes();
          var links = graphService.getLinks();
          var items = [];
          _.each(nodes, function (node) {
            items.push(nodeAttributes(node));
          });
          _.each(links, function (link) {
            items.push(linkAttributes(link));
          });
          return items;
        }

        // UI -> Model =====================================================================================
        function initBindKeylinesEvents(chart) {
          $log.debug("In initBIndKeylinesEvents()");
          bindEvent(chart, 'click', graphService.getEventHandlerOnClick);
          bindEvent(chart, 'dblclick', graphService.getEventHandlerOnDblClick);
          bindEvent(chart, 'contextmenu', graphService.getEventHandlerOnRightClick);
        }

        function loadChart(err, new_chart) {
          $log.debug("In loadChart()");
          if (err) { $log.error('Error itilializing the chart', err); }

          var callbackAfterKeylinesLoad = function(scopeChartRef) {
            return function() {
              if (graphService.getLayout().layout === 'advanced') {
                graphService.setLayout('advanced', false, function () {
                  ping(scopeChartRef, graphService.getSearch(), 'green');
                  ping(scopeChartRef, graphService.getIsolated());
                });
              }
              $log.debug("NGD - setChartState");
              analyzeMediator.setChartState(scopeChartRef);
              analyzeMediator.setChart(scopeChartRef);
              setLayout(scopeChartRef);
              initBindKeylinesEvents(scopeChartRef);

              $log.debug("NGD - loadChart() - checking update_graph");
              if (graphService.update_graph === true) {
                window.addEventListener('resize', setChartSize);
                $log.debug("NGD - loadChart() - set to false");
                graphService.update_graph = false;
              }
            };
          };

          var chartState = analyzeMediator.getChartState();
          scope.chart = new_chart;
          var keylines_items = initItems();
          if (chartState === null) {
            if (scope.chart) {
              $log.debug("NGD - loadChart() - create chart using new chart state");
              scope.chart.load({ type: 'LinkChart', items: keylines_items }, callbackAfterKeylinesLoad(scope.chart) );
            }
          } else {
            $log.debug("NGD - loadChart() - create chart from chartState");
            scope.chart.load(chartState, callbackAfterKeylinesLoad(scope.chart) );
            $log.debug("NGD - loadChart() - set to true");
            graphService.update_graph = true;
          }
          init = false;
          setChartSize();
        }

        function filterRegularNodes(nodes) {
          return _.filter(nodes, function (n) { return n.type === SINGLE || (n.type === COMBO && n.combo_type !== OVERLAY_ENTITY); });
        }

        function filterRegularLinks(links) {
          return _.filter(links, function (l) {
            return l.from_type !== OVERLAY_ENTITY
                   && l.to_type !==OVERLAY_ENTITY
                   && (_.isEmpty(l.inner_links) || !_.some(l.inner_links, function (il) {
                    return il.from_type === OVERLAY_ENTITY || il.to_type === OVERLAY_ENTITY;
                   }));
          });
        }

        scope.$watch('graphService.network_id', function () {
          $log.debug("In watch for network_id");
          if (graphService.network_id === undefined) { return; }
          if (graphService.update_graph === true) {
            init = true;
            analyzeMediator.resetChartState();
            initGraph(loadChart);
          }
        }, true);

        scope.$on('resize', setChartSize);

        function idsAndTypes(nodes) {
          return _.map(nodes, function (n) { return {id: n.id, type: n.type}; });
        }

        scope.$watch('[graphService.getNodes(), graphService.getLinks()]', function (items, old_items) {
          $log.debug("In watch getNodes or getLings");
          if (init) { return; }
          var nodes = items[0];
          var links = items[1];
          var old_nodes = old_items[0];
          var old_links = old_items[1];
          var erased_nodes, erased_links;
          if (!old_nodes) { old_nodes = []; }
          if (!old_links) { old_links = []; }
          if (!nodes) { nodes = []; }
          if (!links) { links = []; }
          if (nodes === old_nodes  ||  scope.chart === undefined) {
            return;
          }
          //remove absent items
          erased_nodes = _.filter(old_nodes, function (node) {
            return !_.some(nodes, { id: node.id, type: node.type });
          });
          erased_links = _.filter(old_links, function (l) {
            return !_.some(links, { from_id: l.from_id, from_type: l.from_type, to_id: l.to_id, to_type: l.to_type });
          });
          scope.chart.removeItem(_.map(_.union(erased_nodes, erased_links), function (item) {
            return chartItemId(item);
          }));
          //update and add new items
            scope.chart.merge(_.map(_.union(nodes, links), function (item) {
              return itemAttributes(item);
            }), function () {

              var regular_nodes = filterRegularNodes(nodes),
                  regular_old_nodes = filterRegularNodes(old_nodes),
                  regular_links = filterRegularLinks(links),
                  regular_old_links = filterRegularLinks(old_links),
                  same_nodes = old_nodes.length === nodes.length && angular.equals(idsAndTypes(old_nodes), idsAndTypes(nodes)),
                  overlay_turned_off = old_nodes.length > nodes.length && regular_old_nodes.length === regular_nodes.length && nodes.length === regular_nodes.length,
                  same_links = regular_old_links.length === regular_links.length;
              if ((same_nodes || overlay_turned_off) && same_links) {
                return;
              }
              if (graphService.getLayout().layout === 'advanced') {
                graphService.setLayout('advanced', false, function () {
                  ping(scope.chart, graphService.getSearch(), 'green');
                  ping(scope.chart, graphService.getIsolated());
                });
              }
              setLayout(scope.chart);
            });
          // zoomChart(scope.chart);


        }, true);

        scope.$watch('graphService.getLayout()', function (value) {
          if (!value) { return; }
          if (value.layout !== 'advanced' && scope.chart) {
            setLayout(scope.chart);
          }
        }, true);

        scope.$watch('graphService.getSearch()', function (value) {
          if (!value || !value.id || !value.type) { return; }
          var toHide = [], backup = [];
          scope.chart.each({}, function (it) {
            if (!it.bg) { backup.push({id: it.id, bg: false}); }
            if (it.id === chartNodeId(value) && it.bg) { backup.push({id: it.id, bg: true}); }
            toHide.push({id: it.id, bg: true});
          });
          scope.chart.setProperties(toHide);
          // scope.chart.selection([chartNodeId(value)]);
          // scope.chart.zoom('selection', {animate: true, time: 1200});
          scope.chart.setProperties({id: chartNodeId(value), bg: false});
          scope.chart.ping(chartNodeId(value), { c: 'green', repeat: 3 });
          $timeout(function () {
            scope.chart.setProperties(backup);
          }, 1000);
        }, true);

        scope.$watch('graphService.getIsolated()', function (value) {
          ping(scope.chart, value);
        });

        scope.$watch('showMenu', setChartSize);

        // Cleanup =========================================================================================
        // Here we unregister from global events on scope destroy
        scope.$on('$destroy', function (scope) {
          var keylinesChart = analyzeMediator.getChart();
          keylinesChart.unbind('click');
          keylinesChart.unbind('dblclick');
          keylinesChart.unbind('contextmenu');
          window.removeEventListener('resize', setChartSize);
          scope.chart = null;
          init = false;
        });
      }
    };
  });
