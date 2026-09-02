with Ada.Numerics.Big_Numbers.Big_Integers;

package body Monster_Bootstrap is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   function New_Context
     (Calculation_Day, Target_Day : Big_Integer) return Monster_Context
   is
   begin
      return
        (Calculation_Day => Calculation_Day,
         Target_Day => Target_Day,
         Phase => Boot_Entry,
         Sub_Phase => 0,
         Status => New_State,
         Retry_Budget => 0,
         Recovery_Depth => 0,
         Current_Handler => 0,
         Previous_Handler => 0,
         Commit_Token => 0,
         Metrics => (Dispatch_Count => 0, Validation_Count => 0, Error_Count => 0),
         Last_Error => No_Error);
   end New_Context;

   procedure Base_Validate (Context : in out Monster_Context) is
   begin
      Context.Metrics.Validation_Count := Context.Metrics.Validation_Count + 1;
      if Context.Status = Failed then
         Context.Last_Error := Invalid_Input_State;
         Context.Metrics.Error_Count := Context.Metrics.Error_Count + 1;
         raise Program_Error with "విఫలమైన సందర్భాన్ని మళ్లీ ధృవీకరించరాదు";
      end if;
      Context.Status := Validated;
   end Base_Validate;

   procedure Base_Dispatch (Context : in out Monster_Context) is
   begin
      Context.Metrics.Dispatch_Count := Context.Metrics.Dispatch_Count + 1;
      Context.Previous_Handler := Context.Current_Handler;
      Context.Current_Handler := Context.Current_Handler + 1;

      case Context.Phase is
         when Boot_Entry =>
            Context.Status := Running;
            Context.Phase := Boot_Validate;
         when Boot_Validate =>
            Base_Validate (Context);
            Context.Phase := Boot_Dispatch;
         when Boot_Dispatch =>
            Context.Commit_Token := Context.Commit_Token + 1;
            Context.Phase := Boot_Done;
         when Boot_Done =>
            Context.Status := Completed;
         when Boot_Failed =>
            Context.Last_Error := Dispatcher_Invariant_Failed;
            Context.Metrics.Error_Count := Context.Metrics.Error_Count + 1;
            raise Program_Error with "ప్రాథమిక పంపిణీ స్థితి విఫలమైంది";
      end case;
   end Base_Dispatch;

   procedure Execute_Bootstrap (Context : in out Monster_Context) is
   begin
      while Context.Phase /= Boot_Done loop
         Base_Dispatch (Context);
      end loop;
      Base_Dispatch (Context);
   exception
      when others =>
         Context.Phase := Boot_Failed;
         Context.Status := Failed;
         Context.Metrics.Error_Count := Context.Metrics.Error_Count + 1;
         raise;
   end Execute_Bootstrap;

end Monster_Bootstrap;
