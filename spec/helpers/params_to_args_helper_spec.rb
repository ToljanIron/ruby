require 'spec_helper'

describe ParamsToArgsHelper, type: :helper do
  describe 'calling contertion function with args should call the Algorithm' do
    it 'should return the mock value' do
      allow(ParamsToArgsHelper).to receive(:calculate_pair_for_specific_relation_per_snapshot).and_return 2
      allow(ParamsToArgsHelper).to receive(:get_most_social_to_args).and_return 2
      allow(ParamsToArgsHelper).to receive(:get_friends_relation_in_network_to_args).and_return 2
      allow(ParamsToArgsHelper).to receive(:most_isolated_to_args).and_return 2
      allow(ParamsToArgsHelper).to receive(:calculate_pair_advice_per_snapshot).and_return 2
      allow(ParamsToArgsHelper).to receive(:get_advice_relation_in_network).and_return 2
      allow(ParamsToArgsHelper).to receive(:find_most_expert_to_args).and_return 2
      allow(ParamsToArgsHelper).to receive(:at_risk_of_leaving_to_args).and_return 2
      allow(ParamsToArgsHelper).to receive(:most_promising_to_args).and_return 2
      allow(ParamsToArgsHelper).to receive(:most_bypassed_manager_to_args).and_return 2
      allow(ParamsToArgsHelper).to receive(:team_glue_to_args).and_return 2
      allow(ParamsToArgsHelper).to receive(:get_trust_in_network_to_args).and_return 2
      allow(ParamsToArgsHelper).to receive(:get_trust_out_network_to_args).and_return 2

      args = { snapshot_id: 1, network_id: 1, pid: 1 }
      expect(ParamsToArgsHelper.get_most_social_to_args(args)).to eq 2
      expect(ParamsToArgsHelper.get_friends_relation_in_network_to_args(args)).to eq 2
      expect(ParamsToArgsHelper.most_isolated_to_args(args)).to eq 2
      expect(ParamsToArgsHelper.find_most_expert_to_args(args)).to eq 2
      expect(ParamsToArgsHelper.at_risk_of_leaving_to_args(args)).to eq 2
      expect(ParamsToArgsHelper.most_promising_to_args(args)).to eq 2
      expect(ParamsToArgsHelper.most_bypassed_manager_to_args(args)).to eq 2
      expect(ParamsToArgsHelper.team_glue_to_args(args)).to eq 2
      expect(ParamsToArgsHelper.get_trust_in_network_to_args(args)).to eq 2
      expect(ParamsToArgsHelper.get_trust_out_network_to_args(args)).to eq 2
    end
  end
end
