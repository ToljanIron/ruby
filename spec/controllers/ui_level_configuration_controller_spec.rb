require 'spec_helper'
require './spec/spec_factory'
include SessionsHelper

describe UiLevelConfigurationController, type: :controller do
  describe 'get_ui_levels' do
    before do
      Company.create(id: 2, name: 'Acme')
    end
    it 'should call build_ui_level_tree helper function' do
      log_in_with_dummy_user_with_role(0, 2)
      res = get :get_ui_levels, {"cid" => 2}
      res = JSON.parse(res.body)
      expect(res["children"].empty?).to be true
    end
  end
end
