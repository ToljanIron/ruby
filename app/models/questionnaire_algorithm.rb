class QuestionnaireAlgorithm < ApplicationRecord
	belongs_to :user
	belongs_to :questionnaire_question
	belongs_to :algorithm_type

	def self.get_question_score(sid,gids, nid, cid,k_factor)
		gids_str = gids.join(',')
		# sqlstr = "select e.first_name ||' '|| e.last_name as name,
		#           at.name as algorithm_name, 
		#           general_score as general, 
		#           office_score as office, 
		#           rank_score as rank, 
		#           gender_score as gender, 
		#           group_score as group,
		#           param_a_score as param_a,
		#           param_b_score as param_b,
		#           param_c_score as param_c,
		#           param_d_score as param_d,
		#           param_e_score as param_e,
		#           param_f_score as param_f,
		#           param_g_score as param_g,
		#           param_h_score as param_h,
		#           param_i_score as param_i,
		#           param_j_score as param_j
		# FROM questionnaire_algorithms qa
		# left join employees e on e.id= qa.employee_id 
		# JOIN groups g ON g.id=e.group_id
		# left join algorithm_types at on qa.algorithm_type_id = at.id 
		# where 
		# qa.snapshot_id=#{sid} AND 
		# qa.network_id = #{nid} AND 
		# g.id in (#{gids_str})
		# order by last_name"
	
		k = k_factor
		affected_measures = ['new_connectors','new_internal_champion']
		a_m = affected_measures.join("','")
		root_group_id = Group.where(snapshot_id: sid, parent_group_id: nil).first.id
		sqlstr = "select e.first_name ||' '|| e.last_name as name, 
				  g.name AS group_name,
				  at.name as algorithm_name,
				  c.rgb as color,
				  g2.name as parent_group_name,
				  CASE WHEN at.name in('#{a_m}') THEN general_score * #{k} ELSE  general_score END AS general, 
				  CASE WHEN at.name in('#{a_m}') THEN office_score * #{k} ELSE  office_score END AS office, 
				  CASE WHEN at.name in('#{a_m}') THEN rank_score * #{k} ELSE  rank_score END AS rank, 
				  CASE WHEN at.name in('#{a_m}') THEN gender_score * #{k} ELSE  gender_score END AS gender, 
				  CASE WHEN at.name in('#{a_m}') THEN group_score * #{k} ELSE  group_score END AS group, 
				  CASE WHEN at.name in('#{a_m}') THEN param_a_score * #{k} ELSE  param_a_score END AS param_a, 
				  CASE WHEN at.name in('#{a_m}') THEN param_b_score * #{k} ELSE  param_b_score END AS param_b, 
				  CASE WHEN at.name in('#{a_m}') THEN param_c_score * #{k} ELSE  param_c_score END AS param_c, 
				  CASE WHEN at.name in('#{a_m}') THEN param_d_score * #{k} ELSE  param_d_score END AS param_d, 
				  CASE WHEN at.name in('#{a_m}') THEN param_e_score * #{k} ELSE  param_e_score END AS param_e, 
				  CASE WHEN at.name in('#{a_m}') THEN param_f_score * #{k} ELSE  param_f_score END AS param_f, 
				  CASE WHEN at.name in('#{a_m}') THEN param_g_score * #{k} ELSE  param_g_score END AS param_g, 
				  CASE WHEN at.name in('#{a_m}') THEN param_h_score * #{k} ELSE  param_h_score END AS param_h, 
				  CASE WHEN at.name in('#{a_m}') THEN param_i_score * #{k} ELSE  param_i_score END AS param_i, 
				  CASE WHEN at.name in('#{a_m}') THEN param_j_score * #{k} ELSE  param_j_score END AS param_j
		FROM questionnaire_algorithms qa
		left join employees e on e.id= qa.employee_id 
		JOIN groups g ON g.id=e.group_id
		left join groups g2 on g.parent_group_id = g2.id and g.parent_group_id != #{root_group_id}
		left join algorithm_types at on qa.algorithm_type_id = at.id
		left join colors c on c.id=g.color_id
		where 
		qa.snapshot_id=#{sid} AND 
		qa.network_id = #{nid} AND 
		g.id in (#{gids_str})
		order by last_name"
		res = ActiveRecord::Base.connection.select_all(sqlstr)
		return res
	end
end
