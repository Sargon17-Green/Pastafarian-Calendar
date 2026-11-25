package Issue29_Lifecycle_Probe is
   type Injection_Mode is
     (No_Injection,
      Raise_Before_Terminal,
      Raise_After_Terminal,
      Raise_After_First_Lower_Row);

   Injected_Failure : exception;

   procedure Reset (Mode : Injection_Mode);
   procedure Set_Mode (Mode : Injection_Mode);

   procedure Record_Allocation;
   procedure Record_Free;

   procedure Before_Terminal_Allocation;
   procedure After_Terminal_Allocation;
   procedure After_Lower_Row_Allocation;

   function Allocation_Count return Natural;
   function Free_Count return Natural;
end Issue29_Lifecycle_Probe;
