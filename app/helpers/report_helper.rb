module ReportHelper
  include UtilHelper

  def self.create_gauge_regression_report(cid)
    report = prepare_regression_report(cid)
    puts "Group Name, Algorithm Name, Slope, Initial z-score"
    report.each do |e|
      puts "#{e[:gname]},#{e[:aname]},#{e[:slope]},#{e[:orig_score]}"
    end
  end

  def self.prepare_regression_report(cid)
    report = []
    res = query_gauge_data(cid)
    return [] if res.empty?

    prev = res[0]
    y = []
    res.each do |e|
      if is_same_data_series?(prev,e)
        y << e['z_score'].to_f if (e['z_score'] != nil)
      else
        report << create_report_entry(y, prev)
        y = e['z_score'] == nil ? [] : [e['z_score'].to_f]
      end
      prev = e
    end
    report << create_report_entry(y, prev)
    return report
  end

  ############################################################
  ## Notation here is:
  ##  sxy - Sigma on x times y
  ##  sy  - Sigma on y
  ##  sy2 - Sigma on y squared
  ## Also, x is actually just an array like: [1,2,3,4, .. ]
  ############################################################
  def self.calculate_regression_slope(y)
    return nil if (y == nil || y.empty?)
    return nil if (y.length < 3)
    return 0   if (y.max == y.min)
    n = y.length
    x = Array(1..n)
    sy = y.reduce(:+)
    sx = x.reduce(:+)
    x2 = x.map {|i| i**2}
    sx2 = x2.reduce(:+)
    sxy = 0
    x.each {|i| sxy += (i * y[i-1])}
    numerator = ((n * sxy) - (sx * sy)).to_f
    nominator = (n * sx2 - sx**2)
    return (numerator / nominator).round(3)
  end

  def self.query_gauge_data(cid)
    sqlstr =
      "select c.group_id as gid, g.name as gname, c.algorithm_id as aid, a.name as aname, c.snapshot_id as sid, c.z_score as z_score
      from cds_metric_scores as c
      join algorithms as a on a.id = c.algorithm_id
      join snapshots as s on s.id = c.snapshot_id
      join groups as g on g.id = c.group_id
      where a.algorithm_type_id = 5 and s.company_id = #{cid}
      UNION
      select c.group_id as gid, g.name as gname, c.algorithm_id as aid, a.name as aname, c.snapshot_id as sid, c.score as z_score
      from cds_metric_scores as c
      join algorithms as a on a.id = c.algorithm_id
      join snapshots as s on s.id = c.snapshot_id
      join groups as g on g.id = c.group_id
      where a.algorithm_type_id = 6 and s.company_id = #{cid} and a.id < 500
      order by gid, aid, sid"

      return ActiveRecord::Base.connection.select_all(sqlstr).to_hash
  end

  ######################## Employees Report #################################
  def self.create_employees_report(cid)
    report = query_employee_data(cid)
    heading = ''
    report.first.each do |k,v|
      heading += ",#{k}"
    end
    puts heading[1..-1]
    report.each do |e|
      row = ''
      e.each do |k,v|
        row += ",#{v}"
      end
      puts row[1..-1]
    end
  end

  #################################################################################################
  ##
  ## A couple of important things:
  ##
  ##  - The reason "crosstab" is used is because cds_metric_scores has all the
  ##      scores in seperate rows, but we want to show report where every combination
  ##      of snapshot, group employee has all the scores in one row.
  ##  - The first SQL command is needed because the postgres function: crosstab
  ##      is part of the tablefunc package
  ##  - Every time we want a new employee measure (socre) included we need
  ##      apply 3 changes:
  ##      - The algorithm number should be added in both places (where the long list of numbers are)
  ##      - The name of the algorithm should be added in the list below
  ##  - VERY IMPORTANT - The algorithm number should appear in the same order in the list as the
  ##    algorithm's name
  ##
  ##  Another thing, there is no test for this query because the test will have to
  ##   be changed with every new algorithm, so it's just not worth it. If you want
  ##   to test it just run the rake task, it's just as quick and no maintanence is needed.
  ##
  #################################################################################################
  def self.query_employee_data(cid)
    sqlstr = "create extension if not exists \"tablefunc\""
    ActiveRecord::Base.connection.select_all(sqlstr)

    sqlstr =
      "select * from crosstab(
         'select snapshot_id, g.name,   e.first_name || '' '' || e.last_name, algorithm_id, score
          from cds_metric_scores as c
          join employees as e on e.id = c.employee_id
          join groups as g on g.id = c.group_id
          where employee_id <> 0 and algorithm_id in(16, 27, 61, 63, 64, 66, 67, 70, 71, 100, 101, 102, 129, 130, 135, 141) and c.group_id is not null
          order by employee_id, c.group_id, snapshot_id' ,
         'select id from algorithms where id in(16, 27, 61, 63, 64, 66, 67, 70, 71, 100, 101, 102, 129, 130, 135, 141)')
       as emloyees_report(
         snapshot_id           integer,
         group_name            varchar,
         employee_id           varchar,
         in_the_loop           numeric,
         most_isolated_to_args numeric,
         social_power          numeric,
         expert                numeric,
         collaboration         numeric,
         team_glue             numeric,
         trusting              numeric,
         social_activity       numeric,
         advice_seeker         numeric,
         information_isolate   numeric,
         powerful_non_managers numeric,
         non_reciprocity       numeric,
         representatives       numeric,
         bottlenecks           numeric,
         gatekeepers           numeric,
         sinks                 numeric)"

      return ActiveRecord::Base.connection.select_all(sqlstr).to_hash
  end

  ######################## Interact Report #################################
  def self.create_interact_report(cid)
    sid = Snapshot.last_snapshot_of_company(cid)
    report = self.query_interact_data(cid, sid)
    puts report.length
    return report
  end

  def self.query_interact_data(cid, sid)
    sqlstr = "create extension if not exists \"tablefunc\""
    ActiveRecord::Base.connection.select_all(sqlstr)

    sqlstr =
      "select emp.first_name || ' ' || emp.last_name as name, g.name as group_name, nn.name || '-' || als.name as metric_name, cms.score
       from cds_metric_scores as cms
       join employees as emp      on emp.id = cms.employee_id
       join groups as g           on g.id   = cms.group_id
       join company_metrics as cm on cm.id  = cms.company_metric_id
       join network_names as nn   on nn.id  = cm.network_id
       join (VALUES (601, 'In'), (602, 'Out')) as als (id, name) on als.id = cm.algorithm_id
       where
       cms.company_id  = #{cid} and
       cms.snapshot_id = #{sid}"

      return ActiveRecord::Base.connection.select_all(sqlstr).to_hash
  end

  ######################### Matrix Report #################################
  def self.prepare_regression_report_in_matrix_format(cid)
    rep = prepare_regression_report(cid)
    ogid = rep.first[:gid]
    heading_printed = false
    rec = nil
    report = ''
    rep.each do |e|
      if e[:gid] != ogid
        report = "#{print_flat_report_heading(rec)}" if !heading_printed
        heading_printed = true
        report = "#{report}\n#{print_flat_report_entry(rec)}"
        rec = nil
      end

      rec = create_new_record_accumulator(e, cid)        if rec.nil?
      rec = add_entry_to_record_accumulator(e, rec) if e[:gid] == ogid
      ogid = e[:gid]
    end
    report = "#{report}\n#{print_flat_report_entry(rec)}"
    return report
  end

  ########################################################################
  # A report record looks like this:
  #   {
  #     gname: <group name>,
  #     gid: <group id>,
  #     size:  <number of emps under group>,
  #     communication_dynamics: {
  #       internal: <int>
  #       external: <int>
  #     },
  #     group_scores: [
  #       { aname: <algorithm name>,
  #         last_score: <float>,
  #         slope: <float>
  #       },
  #       ...
  #     ]
  #   }
  ########################################################################
  def self.add_entry_to_record_accumulator(e, rec)
    entry = {
      aname: e[:aname],
      last_score: e[:orig_score],
      slope: e[:slope]
    }
    rec[:group_scores].push(entry) unless rec[:group_scores].include?(entry)
    return rec
  end

  def self.create_new_record_accumulator(e, cid)
    sid = Company.find(cid).last_snapshot.id
    internal = CdsMetricScore.where(
      algorithm_id: 505,
      snapshot_id: sid,
      group_id: e[:gid]).where("employee_id <> 0").pluck(:score).sum
    internal = (internal.to_f / 100).round(1)

    external = CdsMetricScore.where(
      algorithm_id: 505,
      snapshot_id: sid,
      group_id: e[:gid]).where("employee_id = 0").pluck(:score).sum
    external = (external.to_f / 100).round(1)


    rec = {
      gname: e[:gname],
      gid: e[:gid],
      size: Group.find(e[:gid]).extract_employees.size,
      communication_dynamics: {
        internal: internal,
        external: external
      },
      group_scores: []
    }
    return add_entry_to_record_accumulator(e, rec)
  end

  def self.print_flat_report_entry(rec)
    comm = rec[:communication_dynamics]
    scores = rec[:group_scores]
    line = "#{rec[:gname]},#{rec[:gid]},#{rec[:size]},#{comm[:internal]},#{comm[:external]}"
    scores.each do |s|
      line = "#{line},#{s[:last_score]}"
    end
    return line[0..-1]
  end

  def self.print_flat_report_heading(rec)
    heading = 'group name,group ID,group size,internal emails,external emails'
    rec[:group_scores].each do |e|
      heading = "#{heading},#{e[:aname]}"
    end
    return heading
  end

  ######################## Simple Employee Scores Report ##########################3
  def self.simple_employee_scores_report(cid)

    emp_name_str = "concat(emp.first_name, ' ', emp.last_name)" if is_sql_server_connection?
    emp_name_str = "emp.first_name || ' ' || emp.last_name"     if !is_sql_server_connection?

    sqlstr = 'create table id_to_name (id int, name varchar(254));'
    ActiveRecord::Base.connection.select_all(sqlstr)

    sqlstr = "INSERT INTO id_to_name values
                (74, 'Bypassed managers'),
                (100, 'Information isolates'),
                (101, 'Powerfull nonmanagers'),
                (154, 'Political power'),
                (63, 'Information power centers'),
                (65, 'Decision makers'),
                (62, 'Social power'),
                (71, 'Advice seekers'),
                (130, 'Bottlenecks'),
                (141, 'Sinks'),
                (63, 'Experts'),
                (64, 'Collaboration'),
                (66, 'Team glue'),
                (67, 'Trusting'),
                (70, 'Socially active'),
                (102, 'Non-reciprocity'),
                (135, 'Gatekeepers'),
                (129, 'Representatives');"
    ActiveRecord::Base.connection.select_all(sqlstr)

    sqlstr =
      "SELECT
        emp.email AS emp_name,
        g.name AS group_name,
        itn.name AS algorithm_name,
        al.id AS algorithm_id,
        s.id AS snapshot_id,
        s.timestamp AS snapshot_date,
        cds.score AS score
      FROM cds_metric_scores AS cds
      JOIN employees AS emp ON emp.id = cds.employee_id
      JOIN groups AS g ON g.id = cds.group_id
      JOIN algorithms AS al ON al.id = cds.algorithm_id
      JOIN snapshots AS s ON s.id = cds.snapshot_id
      JOIN id_to_name as itn ON itn.id = al.id
      WHERE
      cds.company_id = #{cid} and
      al.id IN (74,100,101,154,63,65,62,71,130,141,63,64,66,67,70,102,135,129)
      ORDER BY snapshot_id, group_name, algorithm_name, score"

    ret = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    puts "Found #{ret.count} records"
    file = File.open('employee_scores_report.csv', 'w')
    file.write("emp_name,group_name,algorithm_name,snapshot_id,snapshot_date,score\n")
    ii = 0
    ret.each do |e|
      ii +=1
      puts "wrote #{ii} lines" if ((ii % 2000) == 0)
      date = e['snapshot_date'].split(' ')[0]
      file.write("#{e['emp_name']},#{e['group_name']},#{e['algorithm_name']},#{e['snapshot_id']},#{date},#{e['score']}\n")
    end
    file.close

    sqlstr = "DROP TABLE id_to_name;"
    ActiveRecord::Base.connection.select_all(sqlstr)

    return 'OK'
  end

  def self.emails_dump(cid)
    snapshots = Snapshot.where(company_id: cid)
    network = NetworkSnapshotData.emails(cid)
    file = File.open("emails_from_network_snapshot_data_dump.csv", "w")
    file.write("from_id, to_id, snapshot_id, message_id, multiplicity, from_type, to_type, email_date\n")

    snapshots.each do |s|
      sid = s.id
      puts "Working on snapshot: #{sid}"

      res = NetworkSnapshotData.where(snapshot_id: sid, network_id: network)
      res.each do |r|
        str = "#{r.from_employee_id},#{r.to_employee_id},#{sid},#{r.message_id},#{r.multiplicity},#{r.from_type},#{r.to_type},#{r.email_date}\n"
        file.write(str)
      end

    end

    file.close
    puts "Done"
  end

  ################## questionnaire_completion_status ##################################
  def self.questionnaire_completion_status(cid)
    ret = QuestionnaireParticipant.joins("JOIN employees AS emp ON emp.id = questionnaire_participants.employee_id")
            .joins("JOIN groups AS g ON g.id = emp.group_id")
            .select("emp.email as email, emp.group_id, emp.external_id")
            .where("emp.company_id = #{cid}")
            .order('g.name')
            .pluck(:email, :group_id, :name, :status, :external_id)
    res = ''
    ret.each do |e|
      res += "#{e[4]},#{e[0]},#{e[1]},#{e[2]},#{e[3]}\n"
    end
    return res
  end

  private

  def self.create_report_entry(x, prev)
    slope = calculate_regression_slope(x)
    return {
      gid:   prev['gid'],
      gname: prev['gname'],
      aid:   prev['aid'],
      aname: prev['aname'],
      slope: slope,
      orig_score: prev['z_score']}
  end

  def self.is_same_data_series?(prev, curr)
    return false if (prev.nil? || curr.nil?)
    return (prev['gid'] == curr['gid'] && prev['aid'] == curr['aid'])
  end
end
