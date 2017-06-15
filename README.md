DB Flow (SA_db.graphml)
=======================
The DB flow will be changed at version X.X.X.
at this doc, we'll cover the current, and the new DB flows.

There are 2 data sources that can act as input to the system:

 - Email collectors
 - Questionnaire

Emails collector Flow
----------------------------------

<ol type="A">
  <li>import_emails API action is triggered by the collector, creating RawDataEntries</li>
  <li>when the create_snapshot / create_snapshot_for_e2e rake tasks are triggered, it calls the CreateSnapshotHelper.create_company_snapshot
    <ol type="1">
      <li>Snapshot find or create by date</li>
      <li>Emails Snapshot Data (at old version was name NetworkSnapshotsNodes) are created</li>
      <li>Snapshot Data is generated for 'communication flow' network</li>
    </ol>
  </li>
  <li>run precalculate_pins task to update EmployeePin table</li>
  <li>run precalculate_metric_scores to generate MetricScores</li>
</ol>


Questionnaire Data Flow (deprecated)
-----------------------------------

<ol type="1">
  <li>when csv is loaded into the system from the back-end</li>
    <ol type="1">
      <li>Snapshot find or create</li>
      <li>find or create FriendshipsSnapshot for each pair of employees</li>
      <li>find or create AdvicesSnapshot for each pair of employees</li>
      <li>find or create TrustsSnapshot for each pair of employees</li>
    </ol>
  <li>run precalculate_pins task to update EmployeePin table</li>
  <li>run precalculate_metric_scores to generate MetricScores</li>
</ol>

The New Questionnaire Data Flow -merge the Email & Questionnaire flows
------------------------------

<ol type="1">
  <li>when csv is loaded into the system from the back-end, or data is loaded by an API action - QuestionnireRawDataEntry are created</li>
  <li>when the create_snapshot/create_snapshot_for_e2e rake tasks are trigged, it calls the CreateSnapshotHelper.create_company_snapshot, which triggers
    <ol type="1">
      <li>Snapshot find or create by date</li>
      <li>NestworkSnapshotsNodes are created</li>
      <li>SnapshotData are created according to network type</li>
    </ol>
  <li>run precalculate_pins task to update EmployeePin table</li>
  <li>run precalculate_metric_scores to generate MetricScores</li>
</ol>