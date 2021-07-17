whenever sqlerror exit sql.sqlcode;
variable return number;
set verify off;
begin
  HM_DM_OWNER.ETL_BATCH_RUN_CTRL_API.CHECK_NOT_RUNNING('&1');
  :return := 0;
exception when program_error then
  :return := 1;
end;
/
exit :return;
