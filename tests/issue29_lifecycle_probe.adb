package body Issue29_Lifecycle_Probe is
   Current_Mode : Injection_Mode := No_Injection;
   Allocations  : Natural := 0;
   Frees        : Natural := 0;

   procedure Maybe_Raise
     (Expected_Mode : Injection_Mode; Site : String) is
   begin
      if Current_Mode = Expected_Mode then
         Current_Mode := No_Injection;
         raise Injected_Failure with Site;
      end if;
   end Maybe_Raise;

   procedure Reset (Mode : Injection_Mode) is
   begin
      Current_Mode := Mode;
      Allocations := 0;
      Frees := 0;
   end Reset;

   procedure Set_Mode (Mode : Injection_Mode) is
   begin
      Current_Mode := Mode;
   end Set_Mode;

   procedure Record_Allocation is
   begin
      Allocations := Allocations + 1;
   end Record_Allocation;

   procedure Record_Free is
   begin
      Frees := Frees + 1;
   end Record_Free;

   procedure Before_Terminal_Allocation is
   begin
      Maybe_Raise (Raise_Before_Terminal, "before terminal H allocation");
   end Before_Terminal_Allocation;

   procedure After_Terminal_Allocation is
   begin
      Maybe_Raise (Raise_After_Terminal, "after terminal H allocation");
   end After_Terminal_Allocation;

   procedure After_Lower_Row_Allocation is
   begin
      Maybe_Raise
        (Raise_After_First_Lower_Row,
         "after first lower H row allocation");
   end After_Lower_Row_Allocation;

   function Allocation_Count return Natural is
   begin
      return Allocations;
   end Allocation_Count;

   function Free_Count return Natural is
   begin
      return Frees;
   end Free_Count;
end Issue29_Lifecycle_Probe;
