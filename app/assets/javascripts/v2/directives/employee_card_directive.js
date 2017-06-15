/*globals angular, KeyLines, $, window, document, alert,  _ */
angular.module('workships.directives').directive('employeeCard', function (graphService, $timeout, directoryMediator, dataModelService, currentUserService) {
  'use strict';
  return {
    restrict: 'E',
    scope: true,
    template: '<div id="menu" class="context-menu">' +
                '<div class="arrow-box"></div>' +
                '<div class="menu-headline">' +
                  '<div class="name" id="employee-name"></div>' +
                  '<div class="group-scores">' +
                    '<div class="group-rate">' +
                      '<div class="rate"></div>' +
                      '<div class="group-rate-label"></div>' +
                    '</div>' +
                    '<div class="group-std">' +
                      '<div class="standard-deviation"></div>' +
                      '<div class="group-std-label"></div>' +
                    '</div>' +
                  '</div>' +
                '</div>' +
                '<div class="menu-center">' +
                  '<div class="employee-picture">' +
                    '<div class="outer-border">' +
                      '<img class="employee-pic" src="/assets/missing_user.jpg"/>' +
                      //'<div class="employee-pic"></div>' +
                      '<div class="emp-rate"></div>' +
                    '</div>' +
                  '</div>' +
                  '<div class="left-menu-center employee">' +
                    '<div class="label">Office:</div>' +
                    '<div class="office"></div>' +
                    '<div class="label">Job Title:</div>' +
                    '<div class="job_title"></div>' +
                    '<div class="label">Group:</div>' +
                    '<div class="employee_group_name"></div>' +
                  '</div>' +
                  '<div class="left-menu-center domain">' +
                    '<div class="label">Domain:</div>' +
                    '<div class="entity-domain"></div>' +
                    '<div class="label">Name:</div>' +
                    '<div class="entity-name"></div>' +
                  '</div>' +
                '</div>' +
                '<div class="measures"></div>' +
                //'<div class="groups-details"></div>' +
                '<div ng-click="group()" class="group-cls clickable">' +
                  '<div class="icon-btn bar-element group-img">' +
                    '<div class="menu-text" style="bottom: -3px ;left: 34px;">Group</div>' +
                  '</div>' +
                '</div>' +
                '<div ng-click="unGroup()" class="ungroup-cls clickable">' +
                  '<div class="icon-btn bar-element ungroup-img">' +
                    '<div class="menu-text">Ungroup</div>' +
                  '</div>' +
                '</div>' +
                '<div class="personal-card-cls clickable">' +
                  '<div class="icon-btn bar-element personal-card-img">' +
                    '<div class="menu-text">Employee Card</div>' +
                  '</div>' +
                '</div>' +
                '<div ng-click="isolate()" class="isolate-cls clickable">' +
                  '<div class="icon-btn bar-element isolate-img">' +
                    '<div class="menu-text isolate">Isolate</div>' +
                  '</div>' +
                '</div>' +
              '</div>',

    link: function postLink(scope) {
      scope.graphService = graphService;
      scope.data_model = dataModelService;

      var createJqueryObjectToContextMenu, new_params;

      function closeMenu() {
        var menu = $('#menu');
        $('.img').attr('src', '/assets/missing_user.jpg');
        if (menu.is(':visible')) {
          menu.fadeOut('fast');
        }
      }
      scope.group = function () {
        graphService.getEventHandlerOnDblClick(new_params.node_id, new_params.node_type);
        closeMenu();
      };

      scope.unGroup = function () {
        graphService.getEventHandlerOnDblClick(new_params.node_id, new_params.node_type);
        closeMenu();
      };

      scope.isolate = function () {
        var current_isolated = graphService.getIsolated();
        graphService.unIsolateNode();
        if (_.isEmpty(current_isolated) || current_isolated.id !== new_params.node_id || current_isolated.type !== new_params.node_type) {
          graphService.setIsolated(new_params.node_id, new_params.node_type);
        }
        closeMenu();
      };

      scope.goToPersonalCard = function () {
        directoryMediator.setEmplyeeId(new_params.node_id);
        closeMenu();
        window.location.href = '/#/directory';
      };

      createJqueryObjectToContextMenu = function (node_id, node_type, x, y) {
        var offset = $('#chart-element').offset();
        var menu = $('#menu');
        menu.contextmenu(function () {
          return false;
        });
        var menu_center = $('.menu-center');
        var left_menu_center_employee = $('.left-menu-center.employee');
        var left_menu_center_domain = $('.left-menu-center.domain');
        var menu_headline = $('.menu-headline').attr("style", '');
        var groups_details = $('.groups-details');
        var ungroup_buttom = $('.ungroup-cls');
        var personal_card_buttom = $('.personal-card-cls');
        var group_buttom = $('.group-cls');
        var employee_name = $('#employee-name').attr("style", '');
        var employee_rate = $('.emp-rate').attr("style", '');
        var rate = $('.rate').attr("style", '');
        var employee_group_name = $('.employee_group_name');
        var group_standard_deviation = $('.standard-deviation').empty();
        var employee_img = $('.employee-picture').attr("src", "/assets/missing_user.jpg");
        var employee_office = $('.office').empty().attr("style", '');
        var employee_job_title = $('.job_title').empty();
        var employee_role_type = $('.role-type');
        var measures = $('.measures').empty();
        var group_scores = $('.group-scores');
        var group_rate = $('.group-rate');
        var group_std = $('.group-std');
        var group_rate_label = $('.group-rate-label');
        var group_std_label = $('.group-std-label');
        var domain_div = $('.entity-domain');
        var entity_name = $('.entity-name').css('text-transform', 'capitalize');
        var isolate = $('.isolate');
        if (node_type === 'single') {
          var employee_view = graphService.getEmployeeDetails(node_id);
          menu_headline.css('padding-bottom', '5px');
          employee_img.show();
          employee_img.attr("src", employee_view.img_url);
          //employee_img.attr("rate", employee_view.rate);
          menu_center.css({ width: '200px', height: '115px' });

          employee_office.html(employee_view.office);
          employee_office.attr('title', employee_view.office);
          employee_job_title.html(employee_view.job_title);
          employee_job_title.attr('title', employee_view.job_title);
          employee_group_name.html(employee_view.g_name);
          employee_group_name.attr('title', employee_view.g_name);
          employee_role_type.text(employee_view.role_type);
          menu_center.show();

          groups_details.show();
          group_buttom.show();
          ungroup_buttom.hide();
          personal_card_buttom.show();
          if (currentUserService.isCurrentUserAdmin()) {
            employee_name.html(employee_view.name + '<br/>' + employee_view.email);
          } else {
            employee_name.text(employee_view.name);
          }
          employee_rate.text(employee_view.rate.toFixed(2).replace(/\.?0+$/, '')).css('float', 'right');
          employee_rate.show();
          measures.hide();
          group_scores.hide();
          left_menu_center_employee.show();
          left_menu_center_domain.hide();
          if (employee_view.isolated) {
            isolate.text('Cancel Isolate');
          } else {
            isolate.text('Isolate');
          }
        } else if (node_type === 'combo') {
          var group_view = graphService.getGroupDetails(node_id);
          groups_details.hide();
          group_buttom.hide();
          if (group_view.combo_type === 'overlay_entity') {
            group_scores.hide();
            menu_headline.css('padding-bottom', '15px');
            if (group_view.overlay_entity_type === 'keywords') {
              group_view.name = 'Keywords Group: ' + group_view.name;
            }
          } else {
            group_scores.show();
            menu_headline.css('padding-bottom', '5px');
          }
          employee_rate.hide();
          ungroup_buttom.show();
          personal_card_buttom.hide();
          measures.hide();
          menu_headline.css('height', 'auto');
          group_scores.css({height: '60px', 'font-size': '16px', 'padding': '10px 0 10px 0'});
          group_rate.css({'float': 'left', 'width': '49.5%', 'text-align': 'center', 'height': '50px', 'border-right': '1px solid #D3D2D2'});
          group_std.css({float: 'right', width: '49.5%', 'text-align': 'center', 'height': '50px'});
          group_rate_label.text('Average').css({'font-size': '12px', 'margin-top': '6px', 'font-weight': '100'});
          group_std_label.text('STD').css({'font-size': '12px', 'margin-top': '6px', 'font-weight': '100'});
          employee_name.html(group_view.name + '<br>').css('float', 'none');
          rate.text(group_view.rate).css({'color': '#EBC51C', 'font-size': '20px', 'font-weight': '700', 'text-align': 'center'});
          group_standard_deviation.text(group_view.standard_deviation).css({'color': '#EBC51C', 'font-size': '20px', 'font-weight': '700', 'text-align': 'center'});
          menu_center.hide();
          if (group_view.isolated) {
            isolate.text('Cancel Isolate');
          } else {
            isolate.text('Isolate');
          }
        } else if (node_type === 'overlay_entity') {
          var view = graphService.getOverlayEntityDetails(node_id);
          measures.hide();
          ungroup_buttom.hide();
          group_scores.hide();
          personal_card_buttom.hide();
          left_menu_center_employee.hide();
          group_buttom.show();
          employee_img.hide();
          left_menu_center_domain.show();
          left_menu_center_domain.css({ float: 'left' });
          if (view.overlay_entity_type_name === 'external_domains') {
            var domn = view.name.split('@')[1],
                name = view.name.split('@')[0];
            menu_headline.css('padding-bottom', '5px');
            employee_name.text(view.name);
            domain_div.show().text(domn);
            entity_name.show().text(name);
            menu_center.show().css({ height: '75px' });
          } else {
            employee_name.text('Keyword: ' + view.name);
            menu_headline.css('padding-bottom', '15px');
            domain_div.hide();
            entity_name.hide();
            menu_center.hide();
          }
          if (view.isolated) {
            isolate.text('Cancel Isolate');
          } else {
            isolate.text('Isolate');
          }
        }
        // $scope.group_id = node_id;
        offset.left = x + (scope.showMenu ? 265 : 25);
        offset.top = y;
        menu.css({left: offset.left, top: offset.top, background: '#EDECEC'});
        menu.css('border-radius', '3px').css('padding', '10px 15px 2px 15px');
        menu.css('box-shadow', '2px 4px 12px #D3D2D2');
        menu.css('display', 'block');
        menu.css('opacity', '0');
        //find distance from bottom
        if ($("#menu_bottom").length < 1) {
          $("#menu").append('<div id="menu_bottom"></div>');
        }
        if ($(".arrow_box_under").length < 1) {
          $("#menu").append('<div class="arrow_box_under"></div>');
        }

        var screen_height = window.innerHeight;
        $timeout(function () {
          var menu_item = $('#menu');
          var distance_from_bottom = screen_height - $('#menu_bottom').offset().top;
          var elem_height = menu_item.height();
          var top = parseInt(menu_item.css('top'), 10);
          var left = parseInt(menu_item.css('left'), 10);

          var distance_from_right = window.innerWidth - document.getElementById('menu').getBoundingClientRect().right;

          if (distance_from_right < 0) {
            menu_item.css("left", left + distance_from_right);
            //$("#menu .arrow_box_under").css("left", -distance_from_right);
            $("#menu .arrow-box").css({"left": -6, 'top': 18});
          } else {
            //$("#menu .arrow_box_under").css("left", 0);
            $("#menu .arrow-box").css({"left": -6, 'top': 18});
          }
          if (distance_from_bottom < 35) {
            menu_item.css("top", top - elem_height + 30);
            //$("#menu .arrow_box_under").show();
            $("#menu .arrow-box").css({'left': -6, "top": elem_height - 10});
            menu.fadeTo("fast", 1);
          } else {
            $("#menu .arrow-box").css({'left': -6, "top": 18});
            //$("#menu .arrow_box_under").hide();
            menu.fadeTo("fast", 1);
          }
        }, 0);
      };
      scope.$watch('graphService.getOpenCard()', function (params) {
        if (!params) { return; }
        if (params.open) {
          new_params = params;
          createJqueryObjectToContextMenu(params.node_id, params.node_type, params.position_x, params.position_y);
        } else {
          $timeout(closeMenu);
        }
      }, true);
      scope.$watch('showMenu', function () {
        $('#menu').css({display : 'none'});
        closeMenu();
      });
    }
  };
});