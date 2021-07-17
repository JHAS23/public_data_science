whenever sqlerror exit sql.sqlcode;
variable return number;
begin
  HM_DM_OWNER.ETL_BATCH_RUN_CTRL_API.START_JOB('&1');
  :return := 0;
exception when program_error then
  :return := 1;
end;
/
exit :return;
