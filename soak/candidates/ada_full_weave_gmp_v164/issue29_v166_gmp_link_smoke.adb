with Ada.Text_IO;
with Normative_Oracle;
with System;

--  Full Ada package BODY is resolved by taking the subprogram's address,
--  but no source calendar method, including F(c,t), is EVER called.
procedure Issue29_V166_Gmp_Link_Smoke is
   use type System.Address;

   Calendar_Symbol : constant System.Address :=
     Normative_Oracle.Calendar_Date'Address;
   Rank_Symbol : constant System.Address :=
     Normative_Oracle.Choose_Rank'Address;
   Sauce_Symbol : constant System.Address :=
     Normative_Oracle.Sauce'Address;
begin
   if Calendar_Symbol = System.Null_Address
     or else Rank_Symbol = System.Null_Address
     or else Sauce_Symbol = System.Null_Address
   then
      raise Program_Error with "integrated original QA oracle symbols unresolved";
   end if;

   Ada.Text_IO.Put_Line ("V166_FULL_ORACLE_FUNCTION_ADDRESSES_RESOLVED");
   Ada.Text_IO.Put_Line ("V166_NO_FCT_CALLS_NO_ORIGINAL_SOURCE_CALENDAR_EXECUTION");
end Issue29_V166_Gmp_Link_Smoke;
