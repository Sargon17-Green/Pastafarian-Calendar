with Ada.Numerics.Big_Numbers.Big_Integers;

package Monster_Bootstrap is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   type Monster_Phase is (Boot_Entry, Boot_Validate, Boot_Dispatch, Boot_Done, Boot_Failed);
   type Monster_Status is (New_State, Running, Validated, Completed, Failed);
   type Error_Code is (No_Error, Invalid_Input_State, Dispatcher_Invariant_Failed);

   type Metric_Shell is record
      Dispatch_Count   : Natural := 0;
      Validation_Count : Natural := 0;
      Error_Count      : Natural := 0;
   end record;

   type Monster_Context is record
      Calculation_Day : Big_Integer;
      Target_Day      : Big_Integer;
      Phase           : Monster_Phase := Boot_Entry;
      Sub_Phase       : Natural := 0;
      Status          : Monster_Status := New_State;
      Retry_Budget    : Natural := 0;
      Recovery_Depth  : Natural := 0;
      Current_Handler : Natural := 0;
      Previous_Handler : Natural := 0;
      Commit_Token    : Natural := 0;
      Metrics         : Metric_Shell;
      Last_Error      : Error_Code := No_Error;
   end record;

   function New_Context
     (Calculation_Day, Target_Day : Big_Integer) return Monster_Context;

   procedure Base_Validate (Context : in out Monster_Context);
   procedure Base_Dispatch (Context : in out Monster_Context);
   procedure Execute_Bootstrap (Context : in out Monster_Context);
end Monster_Bootstrap;
