module PrecalculateNetworkMetricsHelper
require 'csv'

  def calculate_questionnaire_score(cid,sid)

    QuestionnaireAlgorithm.where(:snapshot_id => sid).delete_all
    qid = Questionnaire.where(:snapshot_id => sid).first.id
    base_mat = []
    participants = Employee
      .select("emps.id,emps.external_id,emps.first_name,emps.last_name,emps.office_id,emps.gender,emps.group_id,emps.rank_id,g.name as group_name,emps.rank_id")
      .from("employees emps")
      .joins("left join groups g on emps.group_id = g.id")
      .where("emps.company_id=#{cid} and  emps.snapshot_id= #{sid}")
      .order("emps.id")
    base_participants_score = {}
    n = participants.length
    base_mat[0] = Array.new(n+1,0)
    emps_hash = {}
    
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
        office: {name: val['office_id'], selections: 0, sum: 0, bidirectional: 0},
        gender:  {name: val['gender'], selections: 0, sum: 0, bidirectional: 0},
        group: {name: val['group_id'], selections: 0, sum: 0, bidirectional: 0},
        rank: {name: val['rank_id'], selections: 0, sum: 0, bidirectional: 0}, 
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


      for i in 1...base_mat.length
        emp1 = base_mat[i][0]
        for j in 1...base_mat.length
            emp2 = base_mat[0][j]
            matB[i][j] = 1 if participants_score[emp1][:office][:name] == participants_score[emp2][:office][:name]
            matC[i][j] = 1 if participants_score[emp1][:gender][:name] == participants_score[emp2][:gender][:name]
            matD[i][j] = 1 if participants_score[emp1][:group][:name] == participants_score[emp2][:group][:name]
            matE[i][j] = 1 if participants_score[emp1][:rank][:name] == participants_score[emp2][:rank][:name]
        end
      end

      # print_matrix(matA,"mat-selections-#{q.network_id}.csv")
      # print_matrix(matB,"mat-office-#{q.network_id}.csv")
      # print_matrix(matC,"mat-gender-#{q.network_id}.csv")
      # print_matrix(matD,"mat-group-#{q.network_id}.csv")
      # print_matrix(matE,"mat-rank-#{q.network_id}.csv")  

      for i in 1...base_mat.length
        emp = base_mat[i][0]
        for j in 1...base_mat[i].length
          participants_score[emp][:office][:selections] += matA[j][i] * matB[j][i]
          participants_score[emp][:office][:bidirectional] += matA[j][i] * matB[j][i] + matA[i][j] * matB[i][j]
          participants_score[emp][:office][:sum] += matB[j][i]

          participants_score[emp][:gender][:selections] += matA[j][i] * matC[j][i]
          participants_score[emp][:gender][:bidirectional] += matA[j][i] * matC[j][i] + matA[i][j] * matC[i][j]
          participants_score[emp][:gender][:sum] += matC[j][i]

          participants_score[emp][:group][:selections] += matA[j][i] * matD[j][i]
          participants_score[emp][:group][:bidirectional] += matA[j][i] * matD[j][i] + matA[i][j] * matD[i][j]
          participants_score[emp][:group][:sum] += matD[i][j]

          participants_score[emp][:rank][:selections] += matA[j][i] * matE[j][i]
          participants_score[emp][:rank][:bidirectional] += matA[j][i] * matE[j][i] + matA[i][j] * matE[i][j]
          participants_score[emp][:rank][:sum] += matE[j][i]

          participants_score[emp][:total_selections] += matA[j][i] # num of participants that choose him
          participants_score[emp][:bidirectional_total] += matA[i][j] # num of participants that choose him
        end
      end
      insert_internal_champions_values(participants_score,q.network_id,sid,n)
      insert_isolated_values(participants_score,q.network_id,sid,n)
      
      matZ = {}
      for i in 1...base_mat.length
        emp = base_mat[i][0]
        matZ[emp] = {office: {},gender: {},group: {},rank: {}}
        for j in 1...base_mat[i].length
          emp2 = participants_score[base_mat[0][j]]
          matZ[emp][:office][emp2[:office][:name]] ||= 0
          matZ[emp][:gender][emp2[:gender][:name]] ||= 0
          matZ[emp][:group][emp2[:group][:name]] ||= 0
          matZ[emp][:rank][emp2[:rank][:name]] ||= 0

          matZ[emp][:office][emp2[:office][:name]] += 1 if(matA[i][j].to_i == 1 || matA[j][i].to_i == 1)
          matZ[emp][:gender][emp2[:gender][:name]] += 1 if(matA[i][j].to_i ==1 || matA[j][i].to_i == 1)
          matZ[emp][:group][emp2[:group][:name]] += 1 if(matA[i][j] .to_i ==1|| matA[j][i].to_i == 1)
          matZ[emp][:rank][emp2[:rank][:name]] += 1 if(matA[i][j].to_i ==1 || matA[j][i].to_i == 1)
        end
        Rails.logger.info "-------------------------------------------------"
        Rails.logger.info("Employee: #{emp}, office: (#{matZ[emp][:office].values}), gender: (#{matZ[emp][:gender].values}), group: (#{matZ[emp][:group].values}), rank: (#{matZ[emp][:rank].values})")
        participants_score[emp][:office][:connectors] = calc_blau_index(matZ[emp][:office],n)
        participants_score[emp][:gender][:connectors] = calc_blau_index(matZ[emp][:gender],n)
        participants_score[emp][:group][:connectors] = calc_blau_index(matZ[emp][:group],n)
        participants_score[emp][:rank][:connectors] = calc_blau_index(matZ[emp][:rank],n)
      end
      insert_connectors_values(participants_score,q.network_id,sid,n)

    end

  end

  def isolated_val(value)
    return (value == 0 ? 1 : 0)
  end


  def insert_internal_champions_values(participants_score,network_id,sid,n)
    algorithm_id = AlgorithmType.find_by_name("internal_champion").id
    participants_score.each do |emp_id,val|
      general_score = (val[:total_selections].to_f/(n-1).to_f).round(3)
      group_score = (val[:group][:sum]-1 > 0 ?  (val[:group][:selections].to_f/(val[:group][:sum]-1).to_f) : 0).round(3)
      office_score = (val[:office][:sum]-1 > 0 ?  (val[:office][:selections].to_f/(val[:office][:sum]-1).to_f) : 0).round(3)
      gender_score = (val[:gender][:sum]-1 > 0 ?  (val[:gender][:selections].to_f/(val[:gender][:sum]-1).to_f) : 0).round(3)
      rank_score = (val[:rank][:sum]-1 > 0 ?  (val[:rank][:selections].to_f/(val[:rank][:sum]-1).to_f) : 0).round(3)

      QuestionnaireAlgorithm.create!(:employee_id => emp_id,:algorithm_type_id => algorithm_id,:network_id => network_id, :snapshot_id => sid, :general_score => general_score, :group_score => group_score, :office_score => office_score, :gender_score => gender_score, :rank_score => rank_score)
    end
  end

  def insert_isolated_values(participants_score,network_id,sid,n)
    algorithm_id = AlgorithmType.find_by_name("isolated").id
    participants_score.each do |emp_id,val|
      general_score =  (val[:bidirectional_total].to_f/(n-1).to_f).round(3)
      group_score = isolated_val(val[:group][:bidirectional])
      office_score = isolated_val(val[:office][:bidirectional])
      gender_score = isolated_val(val[:gender][:bidirectional])
      rank_score = isolated_val(val[:rank][:bidirectional])
      QuestionnaireAlgorithm.create!(:employee_id => emp_id,:algorithm_type_id => algorithm_id,:network_id => network_id, :snapshot_id => sid, :general_score => general_score, :group_score => group_score, :office_score => office_score, :gender_score => gender_score, :rank_score => rank_score)

    end
  end

  def insert_connectors_values(participants_score,network_id,sid,n)
    algorithm_id = AlgorithmType.find_by_name("connectors").id
    participants_score.each do |emp_id,val|
      general_score = ''
      group_score = val[:group][:connectors].round(3)
      office_score = val[:office][:connectors].round(3)
      gender_score = val[:gender][:connectors].round(3)
      rank_score = val[:rank][:connectors].round(3)
      QuestionnaireAlgorithm.create!(:employee_id => emp_id,:algorithm_type_id => algorithm_id,:network_id => network_id, :snapshot_id => sid, :general_score => general_score, :group_score => group_score, :office_score => office_score, :gender_score => gender_score, :rank_score => rank_score)
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
