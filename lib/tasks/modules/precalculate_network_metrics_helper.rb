module PrecalculateNetworkMetricsHelper
require 'csv'
K = 1

  def calculate_questionnaire_score(cid,sid)

    QuestionnaireAlgorithm.where(:snapshot_id => sid).delete_all
    qid = Questionnaire.where(:snapshot_id => sid).first.id
    base_mat = []
    participants = Employee
      .select("emps.id,emps.external_id,emps.first_name,emps.last_name,g.name as group_name,
      emps.office_id as office,
      emps.gender,
      emps.group_id as group,
      emps.rank_id as rank,
      emps.factor_a_id as param_a,
      emps.factor_b_id as param_b,
      emps.factor_c_id as param_c,
      emps.factor_d_id as param_d,
      emps.factor_e_id as param_e,
      emps.factor_f_id as param_f,
      emps.factor_g_id as param_g,
      emps.factor_h as param_h,
      emps.factor_i as param_i,
      emps.factor_j as param_j
      ")
      .from("employees emps")
      .joins("left join groups g on emps.group_id = g.id")
      .where("emps.company_id=#{cid} and  emps.snapshot_id= #{sid}")
      .order("emps.id")
    base_participants_score = {}
    n = participants.length
    base_mat[0] = Array.new(n+1,0)
    emps_hash = {}
    paramsScore = ['office','gender', 'group','rank','param_a','param_b','param_c','param_d','param_e','param_f','param_g','param_h','param_i','param_j']
    conn_hash = {}
    paramsScore.each{|p_s| conn_hash[p_s.to_sym] = {}}
  # paramsScore = ['office','gender', 'group','rank']    

    participants.each_with_index do |val,idx|
      unless base_mat[idx+1] 
        base_mat[idx+1] = Array.new(n+1,0)
      end
      base_mat[idx+1][0]= val['id']
      base_mat[0][idx+1]=val['id']

      base_participants_score[val['id']] = {
        idx: idx+1,
        total_selections:  0,
        bidirectional_total: 0,
        office: {name: val['office'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0},
        gender:  {name: val['gender'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0},
        group: {name: val['group'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0},
        rank: {name: val['rank'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_a: {name: val['param_a'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_b: {name: val['param_b'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_c: {name: val['param_c'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_d: {name: val['param_d'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_e: {name: val['param_e'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_f: {name: val['param_f'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_g: {name: val['param_g'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_h: {name: val['param_h'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_i: {name: val['param_i'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
        param_j: {name: val['param_j'], selections: 0, sum: 0, bidirectional: 0, other_selections: 0}, 
      }
    end
    qq=QuestionnaireQuestion.where(:questionnaire_id => qid,:active => true)
    qq.each do |q|
      matA = base_mat.clone.map(&:clone)  
      participants_score = base_participants_score.deep_dup
      nsd = NetworkSnapshotData.where(:network_id =>q.network_id)
      nsd.each do |res|
        if(res['value'] == 1 )
          matA[participants_score[res['from_employee_id']][:idx]][participants_score[res['to_employee_id']][:idx]] = 1
        end
      end
      matB = base_mat.clone.map(&:clone)
      matC = base_mat.clone.map(&:clone)
      matD = base_mat.clone.map(&:clone)
      matE = base_mat.clone.map(&:clone)

      matPA = base_mat.clone.map(&:clone)
      matPB = base_mat.clone.map(&:clone)
      matPC = base_mat.clone.map(&:clone)
      matPD = base_mat.clone.map(&:clone)
      matPE = base_mat.clone.map(&:clone)
      matPF = base_mat.clone.map(&:clone)
      matPG = base_mat.clone.map(&:clone)
      matPH = base_mat.clone.map(&:clone)
      matPI = base_mat.clone.map(&:clone)
      matPJ = base_mat.clone.map(&:clone)
      paramsArr = {office: matB, gender: matC, group: matD, rank: matE, param_a: matPA, param_b: matPB,param_c: matPC, param_d: matPD, param_e: matPE, param_f: matPF, param_g: matPG, param_h: matPH,  param_i: matPI, param_j: matPJ}

      for i in 1...base_mat.length
        emp1 = base_mat[i][0]
        for j in 1...base_mat.length
          emp2 = base_mat[0][j]
          paramsArr.each do |param,matrix|
            matrix[i][j] = 1 if participants_score[emp1][param][:name] == participants_score[emp2][param][:name]
          end
        end
      end

      # print_matrix(matA,"mat-selections-Q#{q.network_id}-#{Time.now.strftime('%Y-%m-%d %H:%M')}.csv")
      # print_matrix(matB,"mat-office-Q#{q.network_id}-#{Time.now.strftime('%Y-%m-%d %H:%M')}.csv")
      # print_matrix(matC,"mat-gender-#{q.network_id}.csv")
      # print_matrix(matD,"mat-group-#{q.network_id}.csv")
      # print_matrix(matE,"mat-rank-#{q.network_id}.csv")  
      print_matrix(matPA,"matPA-Q#{q.network_id}-#{Time.now.strftime('%Y-%m-%d %H:%M')}.csv")
      print_matrix(matPB,"matPB-Q#{q.network_id}-#{Time.now.strftime('%Y-%m-%d %H:%M')}.csv")
      
      for i in 1...base_mat.length
        emp = base_mat[i][0]
        for j in 1...base_mat[i].length
          paramsArr.each do |param,matrix|
            participants_score[emp][param][:selections] += matA[j][i] * matrix[j][i]
            participants_score[emp][param][:bidirectional] += matA[j][i] * matrix[j][i] + matA[i][j] * matrix[i][j]
            participants_score[emp][param][:sum] += matrix[j][i]
            if( matA[j][i] == 1 && matrix[j][i] == 0 )
              participants_score[emp][param][:other_selections] += 1
            end
          end         
          participants_score[emp][:total_selections] += matA[j][i] # num of participants that choose him
          participants_score[emp][:bidirectional_total] += matA[i][j] # num of participants that choose him
        end
      end
      insert_internal_champions_values(participants_score,q.network_id,sid,n,paramsScore)
      insert_isolated_values(participants_score,q.network_id,sid,n,paramsScore)
      insert_new_internal_champion(participants_score,q.network_id,sid,n,paramsScore)
      insert_new_connectors(participants_score,q.network_id,sid,n,paramsScore)
      
      matZ = {}
      for i in 1...base_mat.length
        emp = base_mat[i][0]
        matZ[emp] = conn_hash.deep_dup  
        for j in 1...base_mat[i].length
          emp2 = participants_score[base_mat[0][j]]
          paramsScore.each do |param|
            matZ[emp][param.to_sym][emp2[param.to_sym][:name]] ||= 0
            matZ[emp][param.to_sym][emp2[param.to_sym][:name]] += 1 if(matA[i][j].to_i == 1 || matA[j][i].to_i == 1)
          end
        end
        paramsScore.each do |p_s|
          participants_score[emp][p_s.to_sym][:connectors] = calc_blau_index(matZ[emp][p_s.to_sym],n)
        end
      #   Rails.logger.info "-------------------------------------------------"
      #   Rails.logger.info("Employee: #{emp}, office: (#{matZ[emp][:office].values}), gender: (#{matZ[emp][:gender].values}), group: (#{matZ[emp][:group].values}), rank: (#{matZ[emp][:rank].values})")
      end
      insert_connectors_values(participants_score,q.network_id,sid,n,paramsScore)

    end
  end

  def isolated_val(value)
    return (value == 0 ? 1 : 0)
  end

  def insert_new_internal_champion(participants_score,network_id,sid,n,paramsScore)
    algorithm_id = AlgorithmType.find_by_name('new_internal_champion').id
    participants_score.each do |emp_id,val|
      qa = QuestionnaireAlgorithm.new(employee_id: emp_id, algorithm_type_id: algorithm_id, network_id: network_id, snapshot_id: sid)
      qa.general_score = ''
      paramsScore.each do |p_score|
        score = (val[p_score.to_sym][:sum]-1 > 0 ?  ((val[p_score.to_sym][:selections].to_f/(val[p_score.to_sym][:sum]-1).to_f) * (n - val[p_score.to_sym][:sum]) * K ) : 0).round(3)
        qa["#{p_score}_score"] = score
      end
      Rails.logger.info "EMP: #{emp_id}, Q: #{network_id},  val[:param_a][:sum] = #{val[:param_a][:sum]}, val[:param_a][:selections] = #{val[:param_a][:selections]}, val[:param_a][:other_selections]= #{val[:param_a][:other_selections]}, GROUP_SCORE= #{qa.param_a_score}"
      qa.save!
    end
  end

  def insert_new_connectors(participants_score,network_id,sid,n,paramsScore)
    algorithm_id = AlgorithmType.find_by_name('new_connectors').id
    participants_score.each do |emp_id,val|
      qa = QuestionnaireAlgorithm.new(employee_id: emp_id, algorithm_type_id: algorithm_id, network_id: network_id, snapshot_id: sid)
      qa.general_score = ''
      paramsScore.each do |p_score|
        score = (val[p_score.to_sym][:sum]-1 > 0 && n != val[p_score.to_sym][:sum] ?  ((val[p_score.to_sym][:other_selections].to_f/(n - val[p_score.to_sym][:sum]).to_f) * ( val[p_score.to_sym][:sum] - 1) * K ) : 0).round(3)
        qa["#{p_score}_score"] = score
      end
      Rails.logger.info "EMP: #{emp_id}, Q: #{network_id},  val[:param_a][:sum] = #{val[:param_a][:sum]}, val[:param_a][:selections] = #{val[:param_a][:selections]}, val[:param_a][:other_selections]= #{val[:param_a][:other_selections]}, ---C_GROUP_SCORE= #{qa.param_a_score}"
      qa.save!
    end
  end

  def insert_internal_champions_values(participants_score,network_id,sid,n,paramsScore)
    algorithm_id = AlgorithmType.find_by_name("internal_champion").id
    participants_score.each do |emp_id,val|
      qa = QuestionnaireAlgorithm.new(employee_id: emp_id, algorithm_type_id: algorithm_id, network_id: network_id, snapshot_id: sid)
      qa.general_score = (val[:total_selections].to_f/(n-1).to_f).round(3)
      paramsScore.each do |p_score|
        score = (val[p_score.to_sym][:sum]-1 > 0 ?  (val[p_score.to_sym][:selections].to_f/(val[p_score.to_sym][:sum]-1).to_f) : 0).round(3)
        qa["#{p_score}_score"] = score
      end
      qa.save!
    end
  end

  def insert_isolated_values(participants_score,network_id,sid,n,paramsScore)
    algorithm_id = AlgorithmType.find_by_name("isolated").id
    participants_score.each do |emp_id,val|
      qa = QuestionnaireAlgorithm.new(employee_id: emp_id, algorithm_type_id: algorithm_id, network_id: network_id, snapshot_id: sid)
      qa.general_score =  (val[:bidirectional_total].to_f/(n-1).to_f).round(3)
      paramsScore.each do |p_score|
        score = isolated_val(val[p_score.to_sym][:bidirectional])
        qa["#{p_score}_score"] = score
      end
      qa.save!
    end
  end

  def insert_connectors_values(participants_score,network_id,sid,n,paramsScore)
    algorithm_id = AlgorithmType.find_by_name("connectors").id
    participants_score.each do |emp_id,val|
      qa = QuestionnaireAlgorithm.new(employee_id: emp_id, algorithm_type_id: algorithm_id, network_id: network_id, snapshot_id: sid)
      qa.general_score =  ''
      paramsScore.each do |p_score|
        score = val[p_score.to_sym][:connectors].round(3)
        qa["#{p_score}_score"] = score
      end
      qa.save!
    end
  end

  def calc_blau_index(vector,n)
    Rails.logger.info "vector: #{vector}, N: #{n}"
    calc = 0
    vector.each do |key,val|
      calc += ((val.to_f * (val.to_f-1)) / (n * (n -1))).to_f  if n >1
    end
    Rails.logger.info 1-calc
    return (1 - calc)
  end

  def print_matrix(matx,file_name)
    file_path = Rails.root.join('public', file_name)
    begin
      for i in 1...matx.length
        external_id =Employee.find(matx[0][i]).external_id
        matx[0][i] = external_id
        matx[i][0] = external_id
      end
      CSV.open(file_path, "wb") do |csv|
        csv.to_io.write "\uFEFF"
        for i in 0...matx.length
          csv << matx[i]
        end
      end
      return file_path
    rescue Exception => e
      Rails.logger.info "ERROR:::  #{e}"
      return false
    end
  end

end
