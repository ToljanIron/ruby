/*globals angular, _, document, window, unused, console*/

angular.module('workships.services').factory('tabService', function (StateService, dataModelService, $timeout) {
  'use strict';

  var tabService = {};
  var TAB_BLUE_BORDER = '#3599cc';
  var TAB_ORANGE_BORDER = '#f79739';
  var TAB_GREEN_BORDER = '#7dc247';
  var TAB_PINK_BORDER = '#ea1f7a';
  var TAB_PURPLE_BORDER = '#7c60a9';
  var TAB_YELLOW_BORDER = '#ebc51c';
  var TAB_TORQUOIZE_BORDER = '#00A99D';
  var TAB_DARKBLUE_BORDER = '#4A55E5';
  var TAB_BLUE_BACKGROUND = '#1F5D75';
  var TAB_ORANGE_BACKGROUND = '#9E5E25';
  var TAB_GREEN_BACKGROUND = '#4B7228';
  var TAB_PINK_BACKGROUND = '#751040';
  var TAB_PURPLE_BACKGROUND = '#341D56';
  var TAB_YELLOW_BACKGROUND = '#7F6805';
  var TAB_TORQUOIZE_BACKGROUND = '#005B52';
  var TAB_DARKBLUE_BACKGROUND  = '#242D6D';

  var TABSIZE = 85;
  var SPACEFORLOGO = 300;

  var DRILL_DOWN_ORIGIN_NONE    = -1;
  var DRILL_DOWN_ORIGIN_GROUP   = 1;
  var DRILL_DOWN_ORIGIN_OVERLAY = 2;

  var drillDownType = DRILL_DOWN_ORIGIN_NONE;

  tabService.subTabs = {};

  tabService.current_tab = null;
  tabService.current_tab_color = null;
  tabService.current_tab_background_color = null;
  tabService.tab_list = [
    {tab_class: 'Dashboard', name: 'Dashboard', img: 'Dashboard_idle.png', img_selected: 'Dashboard_selected.png', border_color: TAB_BLUE_BORDER, background_selected: TAB_BLUE_BACKGROUND},
    {tab_class: 'Workflow', name: 'Workflow', img: 'Workflow_idle.png', img_selected: 'Workflow_selected.png', border_color: TAB_ORANGE_BORDER, background_selected: TAB_ORANGE_BACKGROUND},
    {tab_class: 'Top Talent', name: 'Top Talent', img: 'TopTalent_idle.png', img_selected: 'TopTalent_selected.png', border_color: TAB_GREEN_BORDER, background_selected: TAB_GREEN_BACKGROUND},
    {tab_class: 'Productivity', name: 'Productivity', img: 'Productivity_idle.png', img_selected: 'Productivity_selected.png', border_color: TAB_PINK_BORDER, background_selected: TAB_PINK_BACKGROUND},
    {tab_class: 'Collaboration', name: 'Collaboration', img: 'Collaboration_idle.png', img_selected: 'Collaboration_selected.png', border_color: TAB_PURPLE_BORDER, background_selected: TAB_PURPLE_BACKGROUND},
    {tab_class: 'Explore', name: 'Explore', img: 'Explore_idle.png', img_selected: 'Explore_selected.png', border_color: TAB_YELLOW_BORDER, background_selected: TAB_YELLOW_BACKGROUND},
    // {tab_class: 'Directory', name: 'Directory', img: 'Directory_idle.png', img_selected: 'Directory_selected.png', border_color: TAB_TORQUOIZE_BORDER, background_selected: TAB_TORQUOIZE_BACKGROUND},
    {tab_class: 'Settings', name: 'Settings', img: 'Settings_idle.png', img_selected: 'Settings_selected.png', border_color: TAB_DARKBLUE_BORDER, background_selected: TAB_DARKBLUE_BACKGROUND}];

  tabService.saveTabState = function (tab_name) {
    if (!tab_name) { return; }
    if (tab_name !== 'Dashboard' && tab_name !== 'Explore') {
      StateService.set({name: tab_name + '_subTab', value: tabService.subTabs[tab_name]});
    }
    StateService.set({name: tab_name + '_scrollTop', value: document.body.scrollTop});
  };

  tabService.loadTabState = function (tab_name) {
    if (!tab_name) { return; }
    var scrollTop, subTab;
    if (tab_name !== 'Dashboard' && tab_name !== 'Explore') {
      subTab = StateService.get(tab_name + '_subTab');
      if (subTab === undefined) { return; }
      tabService.setSubTab(tab_name, subTab);
    }
    scrollTop = StateService.get(tab_name + '_scrollTop');
    $timeout(function () {
      document.body.scrollTop = scrollTop;
    });
  };

  tabService.setSubTab = function (tab_name, subTab) {
    tabService.subTabs[tab_name] = subTab;
    return subTab;
  };

  tabService.selectTab = function (new_selected_tab_name) {
    var selected_tab;
    var previous_tab_name = StateService.get('selected_tab');
    if (previous_tab_name === new_selected_tab_name) { return; }
    tabService.saveTabState(previous_tab_name);
    _.each(tabService.tab_list, function (tab) {
      tab.selected = (tab.name === new_selected_tab_name);
      if (tab.selected) { selected_tab = tab; }
    });

    StateService.set({name: 'selected_tab', value: selected_tab.tab_class});
    tabService.current_tab_color = selected_tab.border_color;
    tabService.current_tab_background_color = selected_tab.background_selected;
    tabService.current_tab = new_selected_tab_name;
    tabService.loadTabState(new_selected_tab_name);
  };
  tabService.activePanel = false;
  tabService.showMiniHeader = false;
  tabService.showExploreSettings = false;
  tabService.showNetworkPanel = true;
  tabService.showGroupByPanel = true;
  tabService.showFilterEdgesPanel = true;
  tabService.showLayoutPanel = true;
  tabService.showTimelinePanel = true;
  tabService.stopSpinning = false;
  tabService.getStopSpinning = function () {
    return tabService.stopSpinning;
  };
  tabService.showNotifications = false;

  tabService.closeExploreDropDown = function () {
    tabService.showNetworkPanel = true;
    tabService.showGroupByPanel = true;
    tabService.showFilterEdgesPanel = true;
  };

  tabService.getTabColor = function (tab_name) {
    return _.find(tabService.tab_list, {name: tab_name}).border_color;
  };

  tabService.changeTab = function (oldTabCount, screen_size_width, leftSeenTab) {
    var rightSeenTab;
    var newTabCount = Math.floor((screen_size_width - SPACEFORLOGO) / TABSIZE);
    if (newTabCount > oldTabCount && newTabCount >= tabService.tab_list.length) {
      leftSeenTab = 0;
      rightSeenTab = tabService.tab_list.length - 1;
    } else if (newTabCount > oldTabCount && newTabCount < tabService.tab_list.length) {
      if (leftSeenTab + newTabCount > tabService.tab_list.length - 1) {
        rightSeenTab = tabService.tab_list.length - 1;
        leftSeenTab  = rightSeenTab - newTabCount + 1;
      } else {
        rightSeenTab = leftSeenTab + newTabCount - 1;
      }
    } else if (newTabCount === oldTabCount) {
      rightSeenTab = leftSeenTab + newTabCount - 1;
    } else if (newTabCount < oldTabCount) {
      rightSeenTab = leftSeenTab + newTabCount - 1;
    } else {
      throw 'Unhandled case in changeTab. oldTabCount=' + oldTabCount + ', screen_size_width=' + screen_size_width + ', leftSeenTab=' + leftSeenTab + ', rightSeenTab=' + rightSeenTab;
    }

    return {
      leftSeenTab:  leftSeenTab,
      rightSeenTab: rightSeenTab,
      currTabCount: newTabCount
    };
  };
  /* istanbul ignore next */
  tabService.initDisplayForOrgStructure = function (groups, show) {
    _.each(groups, function (grp) {
      grp.selected = false;
      show[grp.id] = false;
    });
  };

  tabService.displayTheOrgStructre = function (groups) {
    var selected_group = _.find(groups, {id : StateService.get(tabService.current_tab + '_selected') });
    if (selected_group) {
      selected_group.selected = true;
      var chosen_group = selected_group;
      while (chosen_group.parent) {
        chosen_group = dataModelService.getGroupBy(chosen_group.parent);
        chosen_group.selected = true;
      }
    }
  };

  tabService.displayTheOrgStructreInExplore = function (groups, show) {
    var selected_group = _.find(groups, {id : StateService.get(tabService.current_tab + '_selected') });
    if (selected_group) {
      show[selected_group.id] = true;
      var chosen_group = selected_group;
      while (chosen_group.parent) {
        chosen_group = dataModelService.getGroupBy(chosen_group.parent);
        show[chosen_group.id] = true;
      }
    }
  };

  tabService.displayTheDeafultHierarchy = function (show, group_parent) {
    if (!group_parent.parent) {
      show[group_parent] = true;
      // var childs = dataModelService.getGroupDirectChilds(group_parent);
      // _.each(childs, function (child) {
      //   show[child.id] = true;
      // });
    }
  };

  tabService.initOnlySelect = function (groups) {
    _.each(groups, function (grp) {
      grp.selected = false;
    });
  };

  tabService.keepSelections = function (groups) {
    if (!groups) { return; }
    tabService.initOnlySelect(groups);
    tabService.displayTheOrgStructre(groups);
  };


  tabService.keepStates = function (dom_itm, varia) {
    StateService.set({name: tabService.current_tab + dom_itm, value:  varia });
    if (tabService.current_tab !== 'Explore') {
      StateService.set({name: 'Workflow' + dom_itm, value:  varia  });
      StateService.set({name: 'Top Talent' + dom_itm, value:  varia  });
      StateService.set({name: 'Collaboration' + dom_itm, value:  varia  });
      StateService.set({name: 'Productivity' + dom_itm, value:  varia  });
      // StateService.set({name: 'Directory' + dom_itm, value:  varia  });
      StateService.set({name: 'Settings' + dom_itm, value:  varia  });
    }
  };

  tabService.setDrillDownOriginOverlay = function() {
    drillDownType = DRILL_DOWN_ORIGIN_OVERLAY;
  };

  tabService.setDrillDownOriginGroup = function() {
    drillDownType = DRILL_DOWN_ORIGIN_GROUP;
  };

  tabService.setDrillDownOriginNone = function() {
    drillDownType = DRILL_DOWN_ORIGIN_GROUP;
  };

  tabService.drillDownOriginIsOverlay = function() {
    return drillDownType === DRILL_DOWN_ORIGIN_OVERLAY;
  };

  tabService.drillDownOriginIsGroup = function() {
    return drillDownType === DRILL_DOWN_ORIGIN_GROUP;
  };

  tabService.drillDownOriginIsNone = function() {
    return drillDownType === DRILL_DOWN_ORIGIN_NONE;
  };

  tabService.saveOpenGroups = function (groups, show) {
    if (!groups) { return; }
    var open_groups = [];
    _.each(groups, function (grp) {
      if (show[grp.id] === true) {
        open_groups.push(grp.id);
      }
    });
    tabService.keepStates('_open', open_groups);
  };

  tabService.fixHeightWhenHaveScroll = function (moveExpandToLeft) {
    var scroll_height = document.getElementById('scroller').scrollHeight;
    if (tabService.showMiniHeader === true) {
      if (scroll_height > window.innerHeight - 112) { moveExpandToLeft = true; }
      if (scroll_height > window.innerHeight - 167) { moveExpandToLeft = true; }
      if (scroll_height <= window.innerHeight - 112) { moveExpandToLeft = false; }
      if (scroll_height <= window.innerHeight - 167) { moveExpandToLeft = false; }
    }
    return moveExpandToLeft;
  };

  var tabValidation = function (x) {
    if (parseInt(x, 10) >= 0) {
      return true;
    }
  };

  var tabValidationbool = function (x) {
    if (x === true || x === 'true' || x === false || x === 'false') {
      return true;
    }
  };

  var scrollTopValidation = function (y) {
    return y <= document.body.scrollHeight;
  };

  tabService.init = function () {
    StateService.defineState({name: 'Dashboard_selected', validator: tabValidation});
    StateService.defineState({name: 'Workflow_selected', validator: tabValidation});
    StateService.defineState({name: 'Top Talent_selected', validator: tabValidation});
    StateService.defineState({name: 'Productivity_selected', validator: tabValidation});
    StateService.defineState({name: 'Collaboration_selected', validator: tabValidation});
    StateService.defineState({name: 'Explore_selected', validator: tabValidation});
    StateService.defineState({name: 'Settings_selected', validator: tabValidation});
    StateService.defineState({name: 'Dashboard_open', validator: tabValidation});
    StateService.defineState({name: 'Workflow_open', validator: tabValidation});
    StateService.defineState({name: 'Top Talent_open', validator: tabValidation});
    StateService.defineState({name: 'Productivity_open', validator: tabValidation});
    StateService.defineState({name: 'Collaboration_open', validator: tabValidation});
    StateService.defineState({name: 'Explore_open', validator: tabValidation});
    StateService.defineState({name: 'Settings_open', validator: tabValidation});
    StateService.defineState({name: 'Dashboard_structure_open', validator: tabValidationbool});
    StateService.defineState({name: 'Workflow_structure_open', validator: tabValidationbool});
    StateService.defineState({name: 'Top Talent_structure_open', validator: tabValidationbool});
    StateService.defineState({name: 'Productivity_structure_open', validator: tabValidationbool});
    StateService.defineState({name: 'Collaboration_structure_open', validator: tabValidationbool});
    StateService.defineState({name: 'Explore_structure_open', validator: tabValidationbool});
    StateService.defineState({name: 'Settings_structure_open', validator: tabValidationbool});
    StateService.defineState({name: 'Dashboard_scrollTop', validator: scrollTopValidation});
    StateService.defineState({name: 'Workflow_scrollTop', validator: scrollTopValidation});
    StateService.defineState({name: 'Top Talent_scrollTop', validator: scrollTopValidation});
    StateService.defineState({name: 'Productivity_scrollTop', validator: scrollTopValidation});
    StateService.defineState({name: 'Collaboration_scrollTop', validator: scrollTopValidation});
    StateService.defineState({name: 'Explore_scrollTop', validator: scrollTopValidation});
    StateService.defineState({name: 'Settings_scrollTop', validator: scrollTopValidation});

    StateService.defineState({name: 'Dashboard_subTab', validator: tabValidation});
    StateService.defineState({name: 'Workflow_subTab', validator: tabValidation});
    StateService.defineState({name: 'Top Talent_subTab', validator: tabValidation});
    StateService.defineState({name: 'Productivity_subTab', validator: tabValidation});
    StateService.defineState({name: 'Collaboration_subTab', validator: tabValidation});
    StateService.defineState({name: 'Explore_subTab', validator: tabValidation});
    StateService.defineState({name: 'Settings_subTab', validator: tabValidation});

    StateService.defineState({name: 'settings_tab', validator: function (x) { return parseInt(x, 10) === 1 || parseInt(x, 10) === 2; }});

    switch(window.__workships_bootstrap__.companies.product_type) {
      case 'questionnaire_only':
        tabService.current_tab = 'Collaboration';
        break
      default:
        tabService.current_tab = 'Dashboard';
    }

    StateService.set({name: 'settings_tab', value: 1});
  };
  return tabService;
});
