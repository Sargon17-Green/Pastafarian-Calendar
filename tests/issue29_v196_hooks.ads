package Issue29_V196_Hooks is
   type Injection_Point is
     (No_Injection, After_Terminal_Row, After_First_Lower_Row);

   Injected_Failure : exception;

   procedure Reset;
   procedure Arm (Point : Injection_Point);
   procedure Note_Allocation (Terminal : Boolean);
   procedure Note_Free;
   function Allocation_Count return Natural;
   function Free_Count return Natural;
end Issue29_V196_Hooks;
