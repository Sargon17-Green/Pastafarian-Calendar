package body Issue29_V196_Hooks is
   Current_Point : Injection_Point := No_Injection;
   Allocated : Natural := 0;
   Freed : Natural := 0;

   procedure Reset is
   begin
      Current_Point := No_Injection;
      Allocated := 0;
      Freed := 0;
   end Reset;

   procedure Arm (Point : Injection_Point) is
   begin
      Current_Point := Point;
   end Arm;

   procedure Note_Allocation (Terminal : Boolean) is
   begin
      Allocated := Allocated + 1;
      if (Terminal and then Current_Point = After_Terminal_Row)
        or else (not Terminal and then Current_Point = After_First_Lower_Row)
      then
         Current_Point := No_Injection;
         raise Injected_Failure;
      end if;
   end Note_Allocation;

   procedure Note_Free is
   begin
      Freed := Freed + 1;
   end Note_Free;

   function Allocation_Count return Natural is (Allocated);
   function Free_Count return Natural is (Freed);
end Issue29_V196_Hooks;
