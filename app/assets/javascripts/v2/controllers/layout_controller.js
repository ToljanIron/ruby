/*globals angular, console, setTimeout, window, unused, _   */
angular.module('workships').controller('layoutController', function ($scope, $timeout, $location, StateService, sidebarMediator, dashboradMediator, overlayBlockerService, tabService, dataModelService, graphService, analyzeMediator, pleaseWaitService) {
  'use strict';

  var self = this;
  var ADMIN =  'admin';
  var FLAG = 2;
  $scope.RESEND_EMP = 0;
  $scope.RESEND_ALL = 1;
  $scope.SUBMIT_RESULT = 2;

  var isAdmin = function () {
    $scope.admin_show = $scope.data.currentUser.role === ADMIN;
  };
  $scope.linkToAdminPage = function () {
    window.location.href = '/admin_page';
  };
  $scope.employee_init = function () {
    $scope.admin_show = false;

    var employeesSuccess = function (employees_list) {
      var current_employee = _.find(employees_list, function (employee) {
        return employee.email === $scope.data.currentUser.email;
      });
      unused(current_employee);
      $scope.img_url = 'assets/user.jpg'; //current_employee.img_url;
    };
    $scope.companies = [];
    _.each($scope.data.companies, function (company) {
      if (!company) { return; }
      var temp = {};
      temp.id = company.id;
      temp.name = company.name;
      if ($scope.data.currentUser.company_id === company.id) {
        $scope.current_company = temp;
      }
      $scope.companies.push(temp);
    });
    isAdmin();
    dataModelService.getEmployees().then(employeesSuccess);
  };


  $scope.open_left_panel = function () {
    $scope.showMenu = !$scope.showMenu;
    if (tabService.current_tab === 'Explore') {
      $scope.initial_strip_pos = false;
      $scope.show_left_on_explore = !$scope.show_left_on_explore;
    }
    if (tabService.current_tab !== undefined && tabService.current_tab !== null && tabService.current_tab !== 'Dashboard' && tabService.current_tab !== 'Explore' && (tabService.current_tab !== 'Settings' || StateService.get('settings_tab') === 2)) {
      $scope.tempShowMenu = !$scope.tempShowMenu;
    }
  };

  $scope.setHeightForLeftPnl = function () {
    var height = window.innerHeight - 112;
    var newHeight = height + 'px';
    if (tabService.showMiniHeader === true || tabService.showMiniHeader === 'true') {
      return {  'top': '85px', 'height': newHeight };
    }
    height -= 55;
    newHeight = height + 'px';
    return { 'height': newHeight };
  };

  $scope.hide_or_show_panel = function () {
    if ($scope.showMenu === false) {
      return { 'min-width': '0px',
        'width': '0px',
        'height': '1000px',
        'float': 'left',
        'top': '167px',
        'position': 'fixed',
        'transition': 'transform 0.4s',
        'transform': 'translateX(-246px)'
      };
    }
    return {'':''};
  };


  $scope.$on('$locationChangeStart', function () {
    if (!$scope.sidebar.change_to_employee_page) {
      $timeout(function () {
        $scope.$broadcast('resize');
      }, 0);
      $scope.sidebar.show_personal_card = false;
      $scope.sidebar.should_show_sidebar = $scope.sidebar.state_before_employee_card;
    }
    var path = $location.path();
    if (path === '/dashboard') {
      $scope.viewName = "dashboard";
      if (tabService.current_tab === 'Dashboard' || (tabService.current_tab === 'Settings' && StateService.get('settings_tab') === 1)) {
        if ($scope.showMenu === true) {
          $scope.tempShowMenu = true;
          $scope.tempExplore = true;
        }
        $scope.showMenu = false;
      }
      if (tabService.current_tab === 'Explore') {
        if ($scope.show_left_on_explore === false) {
          $scope.showMenu = false;
        }
        if ($scope.show_left_on_explore === true) {
          $scope.showMenu = true;
        }
      }
      if (tabService.current_tab !== undefined && tabService.current_tab !== null && tabService.current_tab !== 'Dashboard' && tabService.current_tab !== 'Explore' && (tabService.current_tab !== 'Settings' || StateService.get('settings_tab') === 2)) {
        if ($scope.tempShowMenu === true) { //$scope.showMenu === false && 
          $scope.showMenu = true;
        }
        if ($scope.tempShowMenu === false) { //$scope.showMenu === true && 
          $scope.showMenu = false;
        }
      }
    } else if (path === '/analyze') {
      $scope.viewName = "new_graph";
    } else if (path === '/directory') {
      $scope.viewName = "directory";
    } else if (path === '/setting') {
      $scope.showMenu = false;
      $scope.sidebar.should_show_sidebar = false;
      $scope.show_setting_page = false;
      $scope.sidebar.show_personal_card = true;
      $scope.viewName = 'setting';
    } else {
      $timeout(function () {
        $location.path("/dashboard");
      }, 0);
    }
  });

  $scope.viewNameIsntAnalyzeOrDirectory = function () {
    return (($scope.viewName !== 'directory') && ($scope.viewName !== 'new_graph'));
  };

  $scope.reportModalIsDisplayed = function () {
    return overlayBlockerService.isElemDisplayed("report-modal-window-directory");
  };

  $scope.presetModalIsDisplayed = function () {
    return overlayBlockerService.isElemDisplayed("preset-menu");
  };

  $scope.onClickCollapseSidebarBtn = function () {
    $scope.sidebar.should_show_sidebar = !$scope.sidebar.should_show_sidebar;
    $scope.sidebar.state_before_employee_card = $scope.sidebar.should_show_sidebar;
    $timeout(function () {
      $scope.$broadcast('resize');
    }, 0);
  };

  $scope.isCurrentView = function (view_name) {
    if ($scope.StateService.get('selected_tab') === view_name) {
      return true;
    }
    return false;
  };

  $scope.getSidebarCollapseBtnStyle = function () {
    if ($scope.sidebar.should_show_sidebar) {
      return {
        left: '229px'
      };
    }
    return {
      left: '0px'
    };
  };

  $scope.isBlocked = function () {
    return overlayBlockerService.isBlocked();
  };

  $scope.unblock = function () {
    overlayBlockerService.unblock();
  };

  $scope.showLogoutMenu = function () {
    if ($scope.data.currentUser.role === 'admin') {
      $scope.obs.block('logout-menu-admin');
      // $scope.show_logout_menu_admin = !$scope.show_logout_menu_admin;
    } else {
      $scope.obs.block('logout-menu-hr');
    }
  };

  $scope.contactContainerStyle = function (tab_name) {
    if (tab_name === 'Explore' || tab_name === 'Directory') {
      return {'right': '99px'};
    }
  };

  $scope.update_me = function () {
    $scope.network = graphService.network_name;
    $scope.color_by = graphService.group_by_name;
    $scope.metric = graphService.measure_name;
    $scope.snapshot_time = graphService.snapshot_id;
    if (analyzeMediator.flag_data) {
      // if (analyzeMediator.flag_data.algorithm_type !== FLAG) { return; }
      $scope.show_higligthed = true;
      $scope.flag_name = analyzeMediator.flag_data.flag_name;
    }
    return true;
  };

  $scope.inTabsWithFalgs = function () {
    return (tabService.current_tab !== 'Explore' && tabService.current_tab !== 'Dashboard' && tabService.current_tab !== 'Settings');
  };

  $scope.removehighLighted = function () {
    $scope.show_higligthed = false;
    graphService.clearHighligthed();
    analyzeMediator.flag_data = null;
  };

  $scope.gethighLigthedColor = function () {
    if (!analyzeMediator.flag_data) { return; }
    var style = {};
    style['background-color'] = tabService.getTabColor(analyzeMediator.flag_data.flag_tab);
    return style;
  };
  $scope.changeGroupView = function () {
    dataModelService.setGroupOrIndividualView(!$scope.bottom_up_view).then(function (bottom_up_view) {
      dashboradMediator.group_overoll_state = bottom_up_view;
      $scope.bottom_up_view = bottom_up_view;
    });
  };

  $scope.downloadInteractReport = function() {
    window.location = 'API/download_interact';
  };

  $scope.init = function () {
    $scope.graphService = graphService;
    // pleaseWaitService.on();
    $scope.initial_strip_pos = false;
    tabService.showExploreSettings = !tabService.showExploreSettings;
    $scope.obs = overlayBlockerService;
    $scope.StateService = StateService;
    $scope.tabService = tabService;
    switch(window.__workships_bootstrap__.companies.product_type) {
      case 'questionnaire_only':
        $scope.tabService.selectTab('Collaboration');
        $scope.viewName = "Collaboration";
        break
      default:
        $scope.tabService.selectTab('Dashboard');
        $scope.viewName = "Dashboard";
    }
    $scope.tabService.init();
    $scope.sidebar = sidebarMediator;
    $scope.sidebar.init(true);
    $scope.data_model = dataModelService;
    dataModelService.getGroupOrIndividualView().then(function (bottom_up_view) {
      $scope.bottom_up_view = bottom_up_view;
    });
    $scope.employee_init();
    $scope.show_higligthed = false;
    $scope.show_left_on_explore = true;
  };

});
